#!/usr/bin/env bash

set -Eeuo pipefail

SCENARIO="${1:-}"
ENVIRONMENT="${2:-}"

usage() {
    cat >&2 <<'TEXT'
Usage: ./scripts/drill.sh <scenario> <environment>

Scenarios:
  failover   stop a task and measure availability while ECS replaces it
  autoscale  generate load and watch the service scale out, then back in
  rollback   deploy a broken revision and watch the circuit breaker revert it
  restore    restore the database from a snapshot, verify the data, clean up
  all        failover, autoscale and rollback in sequence

Environments: staging, production
TEXT
    exit 2
}

case "$SCENARIO" in
    failover | autoscale | rollback | restore | all) ;;
    *) usage ;;
esac

case "$ENVIRONMENT" in
    staging | production) ;;
    *) usage ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_DIR="${ROOT}/envs/${ENVIRONMENT}"
WORK="$(mktemp -d)"

log()  { printf '\033[36m[drill]\033[0m %s\n' "$*"; }
ok()   { printf '  \033[32mok\033[0m    %s\n' "$*"; }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$*"; }
head_() { printf '\n\033[1m%s\033[0m\n' "$*"; }

FAILURES=0
fail() { bad "$*"; FAILURES=$((FAILURES + 1)); }

tf() { terraform -chdir="$ENV_DIR" "$@"; }

terraform -chdir="$ENV_DIR" init -input=false >/dev/null

SITE_URL="$(tf output -raw site_url)"
CLUSTER="$(tf output -raw ecs_cluster)"
SERVICE="$(tf output -raw ecs_service)"
TASK_ARGS="$(tf output -json maintenance_task_args)"
CONTAINER="$(jq -r '.container' <<<"$TASK_ARGS")"
SUBNETS="$(jq -r '.subnets' <<<"$TASK_ARGS")"
TASK_SG="$(jq -r '.security_group' <<<"$TASK_ARGS")"

POLLER=""

cleanup() {
    if [ -n "$POLLER" ]; then
        kill "$POLLER" 2>/dev/null || true
    fi
    rm -rf "$WORK"
}
trap cleanup EXIT

start_polling() {
    : >"${WORK}/codes"
    (
        while :; do
            curl -s -o /dev/null -w '%{http_code}\n' --max-time 10 "${SITE_URL}/" 2>/dev/null \
                >>"${WORK}/codes" || echo 000 >>"${WORK}/codes"
        done
    ) &
    POLLER=$!
    disown "$POLLER" 2>/dev/null || true
}

stop_polling() {
    if [ -n "$POLLER" ]; then
        kill "$POLLER" 2>/dev/null || true
    fi
    POLLER=""
    TOTAL="$(grep -c . "${WORK}/codes" || true)"
    GOOD="$(grep -c '^200$' "${WORK}/codes" || true)"
    BAD_CODES="$(grep -v '^200$' "${WORK}/codes" | sort | uniq -c | tr '\n' ' ' || true)"
}

desired_count() {
    aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
        --query 'services[0].desiredCount' --output text
}

running_count() {
    aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
        --query 'services[0].runningCount' --output text
}

task_arns() {
    aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" \
        --query 'taskArns[]' --output text | tr '\t' '\n'
}

wait_stable() {
    local limit="${1:-40}" i state running desired
    for i in $(seq 1 "$limit"); do
        read -r state running desired < <(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
            --query 'services[0].[deployments[0].rolloutState,runningCount,desiredCount]' --output text)
        if [ "$state" = "COMPLETED" ] && [ "$running" = "$desired" ]; then
            return 0
        fi
        sleep 15
    done
    return 1
}

drill_failover() {
    head_ "Failover — ${ENVIRONMENT}"

    local before victim replacement i started elapsed
    before="$(task_arns | grep -c . || true)"
    victim="$(task_arns | head -1)"
    log "running tasks: ${before}, stopping ${victim##*/}"

    start_polling
    started="$(date +%s)"

    aws ecs stop-task --cluster "$CLUSTER" --task "$victim" \
        --reason "availability drill" >/dev/null

    for i in $(seq 1 60); do
        if [ "$(running_count)" -ge "$before" ] && ! task_arns | grep -q "$victim"; then
            break
        fi
        sleep 10
    done

    elapsed=$(($(date +%s) - started))
    sleep 5
    stop_polling

    log "replacement took ${elapsed}s, ${TOTAL} requests sent while it happened"

    if [ "$TOTAL" = "$GOOD" ]; then
        ok "every request returned 200 (${GOOD}/${TOTAL})"
    else
        fail "not all requests succeeded: ${GOOD}/${TOTAL}, other codes: ${BAD_CODES}"
    fi

    if [ "$(running_count)" -ge "$before" ]; then
        ok "service is back to ${before} running tasks"
    else
        fail "service has $(running_count) tasks, expected ${before}"
    fi

    replacement="$(task_arns | grep -v "$victim" | grep -c . || true)"
    if [ "$replacement" -ge "$before" ]; then
        ok "stopped task was replaced"
    else
        fail "no replacement task"
    fi

    local zones
    zones="$(for t in $(task_arns); do
        aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$t" \
            --query 'tasks[0].availabilityZone' --output text
    done | sort -u | grep -c .)"

    if [ "$zones" -ge 2 ]; then
        ok "tasks spread across ${zones} availability zones"
    else
        fail "all tasks landed in one availability zone"
    fi
}

drill_autoscale() {
    head_ "Autoscaling — ${ENVIRONMENT}"

    local baseline peak load_seconds workers until_ts i current
    load_seconds="${DRILL_LOAD_SECONDS:-420}"
    workers="${DRILL_LOAD_WORKERS:-60}"

    baseline="$(desired_count)"
    peak="$baseline"
    log "baseline: ${baseline} tasks, load: ${workers} workers for ${load_seconds}s"

    until_ts=$(($(date +%s) + load_seconds))
    for i in $(seq 1 "$workers"); do
        (
            while [ "$(date +%s)" -lt "$until_ts" ]; do
                curl -s -o /dev/null --max-time 15 "${SITE_URL}/" >/dev/null 2>&1 || true
            done
        ) &
    done

    while [ "$(date +%s)" -lt "$until_ts" ]; do
        current="$(desired_count)"
        [ "$current" -gt "$peak" ] && peak="$current"
        log "desired ${current}, running $(running_count), cpu $(service_cpu)%"
        sleep 30
    done

    wait

    if [ "$peak" -gt "$baseline" ]; then
        ok "scaled out from ${baseline} to ${peak} tasks under load"
    else
        fail "service stayed at ${baseline} tasks, autoscaling did not trigger"
    fi

    log "load stopped, waiting for scale-in"
    log "target tracking removes one task at a time: 15 minutes below the threshold, then a 300s cooldown"

    local attempts
    attempts=$(( ${DRILL_SCALEIN_SECONDS:-3600} / 60 ))

    for i in $(seq 1 "$attempts"); do
        current="$(desired_count)"
        if [ "$current" -le "$baseline" ]; then
            ok "scaled back in to ${current} tasks"
            return 0
        fi
        log "desired ${current}, waiting ($((i)) of ${attempts} minutes)"
        sleep 60
    done

    fail "still at $(desired_count) tasks after $((attempts)) minutes"
}

service_cpu() {
    aws cloudwatch get-metric-statistics \
        --namespace AWS/ECS --metric-name CPUUtilization \
        --dimensions "Name=ClusterName,Value=${CLUSTER}" "Name=ServiceName,Value=${SERVICE}" \
        --start-time "$(date -u -v-5M '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '5 minutes ago' '+%Y-%m-%dT%H:%M:%SZ')" \
        --end-time "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        --period 60 --statistics Maximum \
        --query 'sort_by(Datapoints,&Timestamp)[-1].Maximum' --output text 2>/dev/null | cut -d. -f1
}

drill_rollback() {
    head_ "Automatic rollback — ${ENVIRONMENT}"

    local original broken i state current
    original="$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
        --query 'services[0].taskDefinition' --output text)"
    log "current task definition: ${original##*/}"

    aws ecs describe-task-definition --task-definition "$original" --query 'taskDefinition' \
        | jq --arg c "$CONTAINER" '
            del(.taskDefinitionArn, .revision, .status, .requiresAttributes,
                .compatibilities, .registeredAt, .registeredBy, .deregisteredAt)
            | (.containerDefinitions[] | select(.name == $c) | .command) = ["sh", "-c", "sleep 3600"]
          ' >"${WORK}/broken.json"

    broken="$(aws ecs register-task-definition --cli-input-json "file://${WORK}/broken.json" \
        --query 'taskDefinition.taskDefinitionArn' --output text)"
    log "registered a revision that never serves traffic: ${broken##*/}"

    start_polling

    aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" \
        --task-definition "$broken" >/dev/null

    for i in $(seq 1 80); do
        state="$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
            --query 'services[0].deployments[0].rolloutState' --output text)"
        current="$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
            --query 'services[0].taskDefinition' --output text)"

        if [ "$current" = "$original" ] && [ "$state" = "COMPLETED" ]; then
            break
        fi

        [ $((i % 4)) -eq 0 ] && log "deployment ${state}, service on ${current##*/}"
        sleep 15
    done

    sleep 5
    stop_polling

    if [ "$current" = "$original" ]; then
        ok "circuit breaker reverted the service to ${original##*/}"
    else
        fail "service is still on ${current##*/}, rollback did not happen"
    fi

    if [ "$TOTAL" = "$GOOD" ]; then
        ok "site stayed available throughout (${GOOD}/${TOTAL} requests returned 200)"
    else
        fail "site returned errors during the failed deployment: ${BAD_CODES}"
    fi

    aws ecs deregister-task-definition --task-definition "$broken" >/dev/null
    log "broken revision deregistered"

    aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" \
        --platform-version LATEST >/dev/null
    log "platform version reset to LATEST: the rollback deployment pins it to a concrete version"

    if wait_stable 20; then
        ok "deployment is stable again"
    else
        fail "service did not stabilise"
    fi
}

RESTORED=""
SNAPSHOT=""

restore_cleanup() {
    if [ -n "$RESTORED" ]; then
        log "removing the restored cluster"
        aws rds delete-db-instance --db-instance-identifier "${RESTORED}-0" \
            --skip-final-snapshot >/dev/null 2>&1 || true
        aws rds wait db-instance-deleted --db-instance-identifier "${RESTORED}-0" 2>/dev/null || true
        aws rds delete-db-cluster --db-cluster-identifier "$RESTORED" \
            --skip-final-snapshot >/dev/null 2>&1 || true
    fi
    if [ -n "$SNAPSHOT" ]; then
        log "removing the drill snapshot"
        aws rds delete-db-cluster-snapshot --db-cluster-snapshot-identifier "$SNAPSHOT" >/dev/null 2>&1 || true
    fi
}

drill_restore() {
    head_ "Database restore — ${ENVIRONMENT}"

    trap 'restore_cleanup; cleanup' EXIT

    local stamp subnet_group sg db_name secret_arn creds host endpoint expected actual
    stamp="$(date +%Y%m%d%H%M%S)"
    SNAPSHOT="${CLUSTER}-drill-${stamp}"
    RESTORED="${CLUSTER}-restore-${stamp}"

    read -r subnet_group db_name < <(aws rds describe-db-clusters --db-cluster-identifier "$CLUSTER" \
        --query 'DBClusters[0].[DBSubnetGroup,DatabaseName]' --output text)
    sg="$(aws rds describe-db-clusters --db-cluster-identifier "$CLUSTER" \
        --query 'DBClusters[0].VpcSecurityGroups[0].VpcSecurityGroupId' --output text)"

    expected="$(count_posts)"
    log "live database has ${expected} published posts"

    log "creating snapshot ${SNAPSHOT}"
    aws rds create-db-cluster-snapshot \
        --db-cluster-identifier "$CLUSTER" \
        --db-cluster-snapshot-identifier "$SNAPSHOT" >/dev/null
    aws rds wait db-cluster-snapshot-available --db-cluster-snapshot-identifier "$SNAPSHOT"
    ok "snapshot available"

    log "restoring into ${RESTORED}"
    aws rds restore-db-cluster-from-snapshot \
        --db-cluster-identifier "$RESTORED" \
        --snapshot-identifier "$SNAPSHOT" \
        --engine aurora-mysql \
        --db-subnet-group-name "$subnet_group" \
        --vpc-security-group-ids "$sg" \
        --serverless-v2-scaling-configuration MinCapacity=0.5,MaxCapacity=2 \
        --no-deletion-protection >/dev/null
    aws rds wait db-cluster-available --db-cluster-identifier "$RESTORED"
    ok "cluster restored"

    log "adding a writer instance"
    aws rds create-db-instance \
        --db-instance-identifier "${RESTORED}-0" \
        --db-cluster-identifier "$RESTORED" \
        --db-instance-class db.serverless \
        --engine aurora-mysql \
        --no-publicly-accessible >/dev/null
    aws rds wait db-instance-available --db-instance-identifier "${RESTORED}-0"
    ok "instance available"

    log "generating credentials for the restored cluster"
    aws rds modify-db-cluster \
        --db-cluster-identifier "$RESTORED" \
        --manage-master-user-password \
        --apply-immediately >/dev/null
    aws rds wait db-cluster-available --db-cluster-identifier "$RESTORED"

    secret_arn="$(aws rds describe-db-clusters --db-cluster-identifier "$RESTORED" \
        --query 'DBClusters[0].MasterUserSecret.SecretArn' --output text)"
    endpoint="$(aws rds describe-db-clusters --db-cluster-identifier "$RESTORED" \
        --query 'DBClusters[0].Endpoint' --output text)"

    for _ in $(seq 1 30); do
        creds="$(aws secretsmanager get-secret-value --secret-id "$secret_arn" \
            --query SecretString --output text 2>/dev/null || true)"
        [ -n "$creds" ] && break
        sleep 10
    done

    actual="$(count_posts "$endpoint" "$db_name" "$secret_arn")"
    log "restored database has ${actual} published posts"

    if [ -n "$actual" ] && [ "$actual" = "$expected" ]; then
        ok "restored data matches the live database (${actual} posts)"
    else
        fail "restored database has ${actual} posts, live has ${expected}"
    fi

    restore_cleanup
    RESTORED=""
    SNAPSHOT=""
    trap cleanup EXIT
    ok "drill resources removed"
}

# shellcheck disable=SC2016
count_posts() {
    local host="${1:-}" db="${2:-}" secret="${3:-}"
    local php overrides task_arn task_id status env_json group result

    php='$h=getenv("DB_HOST")?:getenv("WORDPRESS_DB_HOST");'
    php+='$d=getenv("DB_NAME")?:getenv("WORDPRESS_DB_NAME");'
    php+='if($s=getenv("DB_SECRET")){$j=json_decode($s,true);$u=$j["username"];$p=$j["password"];}'
    php+='else{$u=getenv("WORDPRESS_DB_USER");$p=getenv("WORDPRESS_DB_PASSWORD");}'
    php+='$m=mysqli_init();'
    php+='mysqli_real_connect($m,$h,$u,$p,$d,3306,null,'
    php+='MYSQLI_CLIENT_SSL|MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT) or exit(1);'
    php+='$r=mysqli_query($m,"SELECT COUNT(*) FROM wp_posts WHERE post_status=\"publish\"");'
    php+='echo "POSTS=".mysqli_fetch_row($r)[0]."\n";'

    if [ -n "$secret" ]; then
        env_json="$(jq -n --arg h "$host" --arg d "$db" --arg s "$(aws secretsmanager get-secret-value \
            --secret-id "$secret" --query SecretString --output text)" \
            '[{name:"DB_HOST",value:$h},{name:"DB_NAME",value:$d},{name:"DB_SECRET",value:$s}]')"
    else
        env_json='[]'
    fi

    overrides="$(jq -n --arg c "$CONTAINER" --arg p "$php" --argjson e "$env_json" \
        '{containerOverrides:[{name:$c,command:["php","-r",$p],environment:$e}]}')"

    task_arn="$(aws ecs run-task \
        --cluster "$CLUSTER" \
        --task-definition "$(jq -r '.task_definition' <<<"$TASK_ARGS")" \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[${SUBNETS}],securityGroups=[${TASK_SG}],assignPublicIp=DISABLED}" \
        --overrides "$overrides" \
        --query 'tasks[0].taskArn' --output text)"

    task_id="${task_arn##*/}"

    for _ in $(seq 1 60); do
        status="$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$task_arn" \
            --query 'tasks[0].lastStatus' --output text 2>/dev/null || echo UNKNOWN)"
        [ "$status" = "STOPPED" ] && break
        sleep 10
    done

    group="$(tf output -raw log_group)"

    for _ in $(seq 1 12); do
        result="$(aws logs get-log-events \
            --log-group-name "$group" \
            --log-stream-name "${CONTAINER}/${CONTAINER}/${task_id}" \
            --query 'events[].message' --output text 2>/dev/null \
            | tr '\t' '\n' | sed -n 's/^POSTS=//p' | head -1)"
        [ -n "$result" ] && break
        sleep 5
    done

    printf '%s' "$result"
}

case "$SCENARIO" in
    failover)  drill_failover ;;
    autoscale) drill_autoscale ;;
    rollback)  drill_rollback ;;
    restore)   drill_restore ;;
    all)       drill_failover; drill_autoscale; drill_rollback ;;
esac

printf '\n'
if [ "$FAILURES" -eq 0 ]; then
    printf '\033[1;32mDrill passed\033[0m\n\n'
else
    printf '\033[1;31mDrill failed: %d problem(s)\033[0m\n\n' "$FAILURES"
    exit 1
fi
