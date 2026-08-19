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
# log: Print a consistent status line.
#
# Parameters: $* - Message fragments to write as one status line.
#
# Returns: 0 after writing the line.
#
log() {
    printf '[%s] %s\n' "${script_name}" "$*"
}

#
# container_id_for_service: Resolve one Compose service to its container ID.
#
# Parameters: $1 - Compose service name.
#
# Returns: 0 and the newest container ID when found.
#
container_id_for_service() {
    service_name="$1"

    # Use the Compose command to find the newest container ID for the service.
    "${docker_compose[@]}" ps -q "${service_name}" \
        | tail -n 1
}

#
# all_services_are_healthy: Check every healthcheck-enabled service.
#
# Parameters: None.
#
# Returns: 0 when all applicable services are healthy; 1 otherwise.
#
all_services_are_healthy() {
    all_healthy=true

    # Check every service in the Compose project.
    while IFS= read -r service_name; do
        container_id="$(container_id_for_service "${service_name}")"

        # Log the health status of each service and update the overall result.
        if [[ -z "${container_id}" ]]; then
            log "${service_name} has no container yet."
            all_healthy=false
            continue
        fi

        # Check the running and health status of the container.
        running_status="$(docker inspect -f '{{.State.Running}}' "${container_id}")"
        health_status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "${container_id}")"

        # Log the health status of each service and update the overall result.
        if [[ "${running_status}" != "true" ]]; then
            log "${service_name} is not running."
            all_healthy=false
            continue
        fi

        # Log the health status of each service and update the overall result.
        if [[ "${health_status}" == "none" ]]; then
            log "${service_name} has no healthcheck."
            continue
        fi

        # Log the health status of each service and update the overall result.
        if [[ "${health_status}" != "healthy" ]]; then
            log "${service_name} health is ${health_status}."
            all_healthy=false
        fi
    done < <("${docker_compose[@]}" config --services)

    [[ "${all_healthy}" == "true" ]]
}

#
# Log the start of the wait operation.
#
elapsed_seconds=0

#
# Wait for the stack to settle.
#
while true; do
    # Check if all healthcheck-enabled services are healthy.
    if all_services_are_healthy; then
        log "All healthcheck-enabled services are healthy."
        exit 0
    fi

    # Log the elapsed time and check for timeout.
    if [[ "${elapsed_seconds}" -ge "${PLUNDARR_STACK_WAIT_SECONDS}" ]]; then
        log "Timed out waiting for stack health."
        exit 1
    fi

    # Sleep for a short interval before checking again.
    sleep 5
    elapsed_seconds=$((elapsed_seconds + 5))
done
