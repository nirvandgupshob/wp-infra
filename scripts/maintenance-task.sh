#!/usr/bin/env bash

set -Eeuo pipefail

ENVIRONMENT="${1:?укажите окружение: staging или production}"
COMMAND="${2:?укажите команду, например 'wp core update-db'}"

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../envs/${ENVIRONMENT}" && pwd)"

log() { printf '\033[36m[maint]\033[0m %s\n' "$*"; }

ARGS="$(terraform -chdir="$ENV_DIR" output -json maintenance_task_args)"
CLUSTER="$(jq -r '.cluster' <<<"$ARGS")"
TASK_DEF="$(jq -r '.task_definition' <<<"$ARGS")"
CONTAINER="$(jq -r '.container' <<<"$ARGS")"
SUBNETS="$(jq -r '.subnets' <<<"$ARGS")"
SECURITY_GROUP="$(jq -r '.security_group' <<<"$ARGS")"

log "окружение: ${ENVIRONMENT}, кластер: ${CLUSTER}"
log "команда: ${COMMAND}"

WRAPPED="set -e; cd /var/www/html; ${COMMAND}"

OVERRIDES="$(jq -n \
    --arg container "$CONTAINER" \
    --arg cmd "$WRAPPED" \
    '{containerOverrides: [{name: $container, command: ["docker-ensure-installed.sh", "bash", "-c", $cmd]}]}')"

TASK_ARN="$(aws ecs run-task \
    --cluster "$CLUSTER" \
    --task-definition "$TASK_DEF" \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[${SUBNETS}],securityGroups=[${SECURITY_GROUP}],assignPublicIp=DISABLED}" \
    --overrides "$OVERRIDES" \
    --query 'tasks[0].taskArn' --output text)"

TASK_ID="${TASK_ARN##*/}"
log "задача запущена: ${TASK_ID}"

for attempt in $(seq 1 60); do
    STATUS="$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$TASK_ARN" \
        --query 'tasks[0].lastStatus' --output text 2>/dev/null || echo UNKNOWN)"

    [ "$STATUS" = "STOPPED" ] && break

    if [ "$attempt" -eq 60 ]; then
        echo "[maint] задача не завершилась за отведённое время" >&2
        exit 1
    fi

    sleep 10
done

EXIT_CODE="$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$TASK_ARN" \
    --query 'tasks[0].containers[0].exitCode' --output text)"

LOG_GROUP="$(terraform -chdir="$ENV_DIR" output -raw log_group)"

log 'вывод задачи:'
aws logs get-log-events \
    --log-group-name "$LOG_GROUP" \
    --log-stream-name "${CONTAINER}/${CONTAINER}/${TASK_ID}" \
    --query 'events[].message' --output text 2>/dev/null \
    | tr '\t' '\n' | sed 's/^/    /'

if [ "$EXIT_CODE" != "0" ]; then
    echo "[maint] задача завершилась с кодом ${EXIT_CODE}" >&2
    exit 1
fi

log 'готово'
