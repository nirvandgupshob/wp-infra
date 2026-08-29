#!/usr/bin/env bash

set -Eeuo pipefail

ENVIRONMENT="${1:?environment: staging or production}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_DIR="${ROOT}/envs/${ENVIRONMENT}"

passed=0
failed=0

ok()   { printf '  \033[32mok\033[0m    %s\n' "$*"; passed=$((passed + 1)); }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$*"; failed=$((failed + 1)); }
head_() { printf '\n\033[1m%s\033[0m\n' "$*"; }

check() {
    local label="$1" expected="$2" actual="$3"
    if [ "$actual" = "$expected" ]; then
        ok "${label}: ${actual}"
    else
        bad "${label}: ${actual} (expected ${expected})"
    fi
}

tf() { terraform -chdir="$ENV_DIR" "$@"; }

terraform -chdir="$ENV_DIR" init -input=false >/dev/null

SITE_URL="$(tf output -raw site_url)"
DOMAIN="${SITE_URL#https://}"
CLUSTER="$(tf output -raw ecs_cluster)"
SERVICE="$(tf output -raw ecs_service)"

printf '\033[1mEnvironment %s — %s\033[0m\n' "$ENVIRONMENT" "$SITE_URL"

head_ "Endpoint"

code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "http://${DOMAIN}/" || echo 000)"
check "http redirects" "301" "$code"

tls="$(curl -sS -o /dev/null -w '%{ssl_verify_result}' --max-time 15 "${SITE_URL}/" || echo 1)"
check "certificate valid" "0" "$tls"

for path in / /wp-login.php /healthz.php /readyz.php; do
    code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "${SITE_URL}${path}" || echo 000)"
    check "GET ${path}" "200" "$code"
done

code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "${SITE_URL}/no-such-page-12345/" || echo 000)"
check "GET missing page" "404" "$code"

if curl -sS --max-time 15 "${SITE_URL}/readyz.php" | grep -q '"status":"ok"'; then
    ok "database reachable from the application"
else
    bad "database not reachable from the application"
fi

head_ "Tasks"

TASKS="$(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" \
    --query 'taskArns[]' --output text | tr '\t' '\n')"

zones=""
for task in $TASKS; do
    [ -n "$task" ] || continue
    read -r az health < <(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$task" \
        --query 'tasks[0].[availabilityZone,healthStatus]' --output text)
    zones="${zones}${az}\n"
    check "task ${task##*/} health" "HEALTHY" "$health"
done

unique_zones="$(printf '%b' "$zones" | sort -u | grep -c .)"
if [ "$unique_zones" -ge 2 ]; then
    ok "tasks spread across ${unique_zones} availability zones"
else
    bad "all tasks in a single availability zone"
fi

read -r running desired state < <(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
    --query 'services[0].[runningCount,desiredCount,deployments[0].rolloutState]' --output text)
check "running tasks" "$desired" "$running"
check "deployment state" "COMPLETED" "$state"

head_ "Load balancer"

TG="$(aws elbv2 describe-target-groups --names "$CLUSTER" --query 'TargetGroups[0].TargetGroupArn' --output text)"
# shellcheck disable=SC2016
unhealthy="$(aws elbv2 describe-target-health --target-group-arn "$TG" \
    --query 'length(TargetHealthDescriptions[?TargetHealth.State!=`healthy`])' --output text)"
check "unhealthy targets" "0" "$unhealthy"

head_ "Database"

read -r db_status db_members < <(aws rds describe-db-clusters --db-cluster-identifier "$CLUSTER" \
    --query 'DBClusters[0].[Status,length(DBClusterMembers)]' --output text)
check "cluster status" "available" "$db_status"

# shellcheck disable=SC2016
public="$(aws rds describe-db-instances --filters "Name=db-cluster-id,Values=${CLUSTER}" \
    --query 'length(DBInstances[?PubliclyAccessible==`true`])' --output text)"
check "publicly accessible instances" "0" "$public"

db_zones="$(aws rds describe-db-instances --filters "Name=db-cluster-id,Values=${CLUSTER}" \
    --query 'DBInstances[].AvailabilityZone' --output text | tr '\t' '\n' | sort -u | wc -l | tr -d ' ')"
if [ "$db_members" -gt 1 ] && [ "$db_zones" -lt 2 ]; then
    bad "database instances share one availability zone"
else
    ok "database instances: ${db_members} in ${db_zones} zone(s)"
fi

head_ "Alarms"

# shellcheck disable=SC2016
alarming="$(aws cloudwatch describe-alarms --alarm-name-prefix "$CLUSTER" \
    --query 'length(MetricAlarms[?StateValue==`ALARM`])' --output text)"
check "metric alarms in ALARM" "0" "$alarming"

composite="$(aws cloudwatch describe-alarms --alarm-name-prefix "$CLUSTER" --alarm-types CompositeAlarm \
    --query 'CompositeAlarms[0].StateValue' --output text)"
check "composite alarm" "OK" "$composite"

external="$(aws cloudwatch describe-alarms --alarm-name-prefix "$CLUSTER" --region us-east-1 \
    --query 'MetricAlarms[0].StateValue' --output text)"
check "external health check alarm" "OK" "$external"

head_ "Infrastructure state"

if tf plan -detailed-exitcode -input=false -lock=false >/dev/null 2>&1; then
    ok "no drift between code and AWS"
else
    bad "terraform plan reports changes"
fi

printf '\n\033[1mPassed: %d, failed: %d\033[0m\n\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
