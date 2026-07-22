#!/usr/bin/env bash

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# plundarr-stack-wait.sh: This script waits for all Docker Compose services
#                         with healthchecks to report healthy.
#
# The script:
#   - Lists all services in the Docker Compose project.
#   - Resolves each service to its current container.
#   - Waits for healthcheck-enabled containers to report healthy.
#   - Fails when any container exits, reports unhealthy, or times out.
#

#
# Fail on any error, unset variable, or failed pipe command.
#
set -euo pipefail

#
# Default script settings.
#
: "${PLUNDARR_COMPOSE_FILE:=docker-compose.yml}"
if [[ -z "${PLUNDARR_ENV_FILE:-}" ]]; then
    PLUNDARR_ENV_FILE="$(dirname "${PLUNDARR_COMPOSE_FILE}")/.env"
fi
: "${PLUNDARR_STACK_WAIT_SECONDS:=600}"

#
# Script state used for consistent log output.
#
script_name="plundarr-stack-wait.sh"

#
# Docker Compose command compatible with v2 and v1.
#
if docker compose version >/dev/null 2>&1; then
    docker_compose=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    docker_compose=(docker-compose)
else
    printf '[%s] Docker Compose is missing.\n' "${script_name}" >&2
    exit 1
fi

#
# Bind every Compose command to the generated deployment pair.
#
docker_compose+=(--env-file "${PLUNDARR_ENV_FILE}" -f "${PLUNDARR_COMPOSE_FILE}")

#
# Print a consistent status line.
#
log() {
    printf '[%s] %s\n' "${script_name}" "$*"
}

#
# Resolve a Compose service to a container ID.
#
container_id_for_service() {
    service_name="$1"

    "${docker_compose[@]}" ps -q "${service_name}" \
        | tail -n 1
}

#
# Check whether every healthcheck-enabled service is healthy.
#
all_services_are_healthy() {
    all_healthy=true

    while IFS= read -r service_name; do
        container_id="$(container_id_for_service "${service_name}")"

        if [[ -z "${container_id}" ]]; then
            log "${service_name} has no container yet."
            all_healthy=false
            continue
        fi

        running_status="$(docker inspect -f '{{.State.Running}}' "${container_id}")"
        health_status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "${container_id}")"

        if [[ "${running_status}" != "true" ]]; then
            log "${service_name} is not running."
            all_healthy=false
            continue
        fi

        if [[ "${health_status}" == "none" ]]; then
            log "${service_name} has no healthcheck."
            continue
        fi

        if [[ "${health_status}" != "healthy" ]]; then
            log "${service_name} health is ${health_status}."
            all_healthy=false
        fi
    done < <("${docker_compose[@]}" config --services)

    [[ "${all_healthy}" == "true" ]]
}

#
# Wait for the stack to settle.
#
elapsed_seconds=0

while true; do
    if all_services_are_healthy; then
        log "All healthcheck-enabled services are healthy."
        exit 0
    fi

    if [[ "${elapsed_seconds}" -ge "${PLUNDARR_STACK_WAIT_SECONDS}" ]]; then
        log "Timed out waiting for stack health."
        exit 1
    fi

    sleep 5
    elapsed_seconds=$((elapsed_seconds + 5))
done
