#!/usr/bin/env bash

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# plundarr-vpn-test.sh: This script validates Plundarr's PIA WireGuard and
#                       port-forwarding support through the actual Privateerr
#                       and Gluetun Docker Compose containers.
#
# The script:
#   - Locates Privateerr and Gluetun containers from Docker Compose.
#   - Verifies both containers are running and healthy.
#   - Verifies Privateerr generated wg0.conf.
#   - Verifies Privateerr generated privateerr.env.
#   - Checks Gluetun's unauthenticated health endpoint inside Gluetun.
#   - Checks Gluetun's forwarded_port file when port forwarding is required.
#   - Checks selected download clients are running and healthy.
#   - Checks qBittorrent port-forwarding state when requested.
#   - Writes validation output to stdout and the Plundarr test log file.
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
: "${PLUNDARR_PRIVATEERR_SERVICE:=privateerr}"
: "${PLUNDARR_GLUETUN_SERVICE:=gluetun}"
: "${PLUNDARR_DOWNLOAD_SERVICES:=}"
: "${PLUNDARR_QBITTORRENT_SERVICE:=}"
: "${PLUNDARR_CONFIG_PATH:=config/gluetun/wireguard}"
: "${PLUNDARR_GLUETUN_PATH:=config/gluetun}"
: "${PLUNDARR_HEALTH_URL:=http://127.0.0.1:9999}"
: "${PLUNDARR_QBITTORRENT_URL:=http://127.0.0.1:8080}"
: "${PLUNDARR_REQUIRE_PORT_FORWARD:=true}"
: "${PLUNDARR_WAIT_SECONDS:=0}"
: "${PLUNDARR_LOG_PATH:=test/logs/plundarr-vpn-test.log}"

#
# Script state used for consistent log output.
#
plundarr_test_script_name="plundarr-vpn-test.sh"

#
# Docker Compose command compatible with v2 and v1.
#
if docker compose version >/dev/null 2>&1; then
    docker_compose=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    docker_compose=(docker-compose)
else
    printf '[%s] Docker Compose is missing.\n' "${plundarr_test_script_name}" >&2
    exit 1
fi

#
# Bind every Compose command to the generated deployment pair.
#
docker_compose+=(--env-file "${PLUNDARR_ENV_FILE}" -f "${PLUNDARR_COMPOSE_FILE}")

#
# Ensure the log directory exists before writing validation output.
#
mkdir -p "$(dirname "${PLUNDARR_LOG_PATH}")"
: > "${PLUNDARR_LOG_PATH}"

#
# log: Print one status line for CI logs and the persisted log file.
#
# Parameters: $* - Message fragments to write as one status line.
#
# Returns:     tee's exit status.
#
log() {
    printf '[%s] %s\n' "${plundarr_test_script_name}" "$*" \
        | tee -a "${PLUNDARR_LOG_PATH}"
}

#
# require_file: Ensure a file exists and is not empty.
#
# Parameters: $1 - File path.
#             $2 - Human-readable file label.
#
# Returns:     0 when the file exists; exits nonzero otherwise.
#
require_file() {
    file_path="$1"
    file_label="$2"

    if [[ ! -s "${file_path}" ]]; then
        log "Missing ${file_label}: ${file_path}"
        exit 1
    fi
}

#
# container_id_for_service: Resolve one Compose service to its container ID.
#
# Parameters: $1 - Compose service name.
#
# Returns:     0 and the newest container ID when found.
#
container_id_for_service() {
    service_name="$1"

    "${docker_compose[@]}" ps -q "${service_name}" \
        | tail -n 1
}

#
# require_running_container: Check that a resolved container is running.
#
# Parameters: $1 - Container ID.
#             $2 - Compose service name.
#
# Returns:     0 when running; exits nonzero otherwise.
#
require_running_container() {
    container_id="$1"
    service_name="$2"

    if [[ -z "${container_id}" ]]; then
        log "Missing container for ${service_name}."
        exit 1
    fi

    if [[ "$(docker inspect -f '{{.State.Running}}' "${container_id}")" != "true" ]]; then
        log "${service_name} container is not running."
        exit 1
    fi
}

#
# require_healthy_container: Check a container's Docker health status.
#
# Parameters: $1 - Container ID.
#             $2 - Compose service name.
#
# Returns:     0 when healthy; exits nonzero otherwise.
#
require_healthy_container() {
    container_id="$1"
    service_name="$2"

    health_status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "${container_id}")"

    if [[ "${health_status}" != "healthy" ]]; then
        log "${service_name} health is ${health_status}, expected healthy."
        exit 1
    fi
}

#
# wait_for_healthy_container: Wait for one container to become healthy.
#
# Parameters: $1 - Container ID.
#             $2 - Compose service name.
#
# Returns:     0 when healthy; exits nonzero after the configured timeout.
#
wait_for_healthy_container() {
    container_id="$1"
    service_name="$2"
    elapsed_seconds=0

    while true; do
        health_status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "${container_id}")"

        if [[ "${health_status}" == "healthy" ]]; then
            return 0
        fi

        if [[ "${elapsed_seconds}" -ge "${PLUNDARR_WAIT_SECONDS}" ]]; then
            log "${service_name} health is ${health_status}, expected healthy."
            exit 1
        fi

        log "Waiting for ${service_name} health: ${health_status}."
        sleep 2
        elapsed_seconds=$((elapsed_seconds + 2))
    done
}

#
# json_value: Extract a basic scalar value from qBittorrent preferences JSON.
#
# Parameters: $1 - JSON payload.
#             $2 - JSON key.
#
# Returns:     0 and the scalar value when found.
#
json_value() {
    json_payload="$1"
    json_key="$2"

    printf '%s\n' "${json_payload}" \
        | grep -o "\"${json_key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"\\|\"${json_key}\"[[:space:]]*:[[:space:]]*true\\|\"${json_key}\"[[:space:]]*:[[:space:]]*false\\|\"${json_key}\"[[:space:]]*:[[:space:]]*[0-9][0-9]*" \
        | head -n 1 \
        | cut -d ':' -f 2- \
        | tr -d '[:space:]' \
        | tr -d '"'
}

#
# Resolve and validate the target service containers.
#
privateerr_container_id="$(container_id_for_service "${PLUNDARR_PRIVATEERR_SERVICE}")"
gluetun_container_id="$(container_id_for_service "${PLUNDARR_GLUETUN_SERVICE}")"

log "Inspecting Privateerr container."
require_running_container "${privateerr_container_id}" "${PLUNDARR_PRIVATEERR_SERVICE}"
if [[ "${PLUNDARR_WAIT_SECONDS}" -gt 0 ]]; then
    wait_for_healthy_container "${privateerr_container_id}" "${PLUNDARR_PRIVATEERR_SERVICE}"
else
    require_healthy_container "${privateerr_container_id}" "${PLUNDARR_PRIVATEERR_SERVICE}"
fi

log "Inspecting Gluetun container."
require_running_container "${gluetun_container_id}" "${PLUNDARR_GLUETUN_SERVICE}"
if [[ "${PLUNDARR_WAIT_SECONDS}" -gt 0 ]]; then
    wait_for_healthy_container "${gluetun_container_id}" "${PLUNDARR_GLUETUN_SERVICE}"
else
    require_healthy_container "${gluetun_container_id}" "${PLUNDARR_GLUETUN_SERVICE}"
fi

#
# Confirm every selected download client is running and healthy.
#
read -r -a download_services <<< "${PLUNDARR_DOWNLOAD_SERVICES}"
for download_service in "${download_services[@]}"; do
    download_container_id="$(container_id_for_service "${download_service}")"

    log "Inspecting ${download_service} container."
    require_running_container "${download_container_id}" "${download_service}"
    if [[ "${PLUNDARR_WAIT_SECONDS}" -gt 0 ]]; then
        wait_for_healthy_container "${download_container_id}" "${download_service}"
    else
        require_healthy_container "${download_container_id}" "${download_service}"
    fi
done

#
# Confirm Privateerr produced the expected config and metadata files.
#
wg_config_path="${PLUNDARR_CONFIG_PATH}/wg0.conf"
metadata_path="${PLUNDARR_CONFIG_PATH}/privateerr.env"
forwarded_port_path="${PLUNDARR_GLUETUN_PATH}/forwarded_port"

log "Inspecting generated WireGuard config."
require_file "${wg_config_path}" "WireGuard config"
grep -q '^PrivateKey[[:space:]]*=' "${wg_config_path}"
grep -q '^PublicKey[[:space:]]*=' "${wg_config_path}"
grep -q '^Endpoint[[:space:]]*=' "${wg_config_path}"

log "Inspecting generated Gluetun metadata."
require_file "${metadata_path}" "Privateerr metadata"
grep -q '^PIA_WG_SERVER_NAME=' "${metadata_path}"
grep -q '^PIA_WG_ENDPOINT_IP=' "${metadata_path}"
grep -q '^PIA_PORT_FORWARDING_SUPPORTED=true' "${metadata_path}"

#
# Ask Gluetun's unauthenticated health server whether the VPN is alive.
#
log "Checking Gluetun VPN status inside Gluetun."
docker exec \
    -e PLUNDARR_HEALTH_URL="${PLUNDARR_HEALTH_URL}" \
    "${gluetun_container_id}" \
    sh -ec 'wget -qO- "${PLUNDARR_HEALTH_URL}" >/dev/null'

#
# Use Gluetun's forwarded_port file because the control API may require auth.
#
if [[ "${PLUNDARR_REQUIRE_PORT_FORWARD}" == "true" ]]; then
    log "Checking Gluetun forwarded port."
    forwarded_port=""

    # Wait up to 30 seconds for Gluetun to write the forwarded_port file.
    for _ in {1..30}; do
        # If the file exists and is not empty, read the port number and break the loop.
        if [[ -s "${forwarded_port_path}" ]]; then
            forwarded_port="$(tr -dc '0-9' < "${forwarded_port_path}")"
            break
        fi
        sleep 1
    done

    # If the file is still missing or empty, fail the validation.
    if ! [[ "${forwarded_port}" =~ ^[0-9]+$ ]] || [[ "${forwarded_port}" -lt 1 ]] || [[ "${forwarded_port}" -gt 65535 ]]; then
        log "No valid forwarded port came back from Gluetun."
        exit 1
    fi

    log "Forwarded port is ${forwarded_port}."
fi

#
# Confirm qBittorrent picked up Gluetun's forwarded port when requested.
#
if [[ -n "${PLUNDARR_QBITTORRENT_SERVICE}" ]]; then
    if [[ "${PLUNDARR_REQUIRE_PORT_FORWARD}" != "true" ]]; then
        log "qBittorrent validation requires port forwarding."
        exit 1
    fi

    log "Checking qBittorrent port-forwarding preferences."
    qbittorrent_preferences="$(
        docker exec \
            -e PLUNDARR_QBITTORRENT_URL="${PLUNDARR_QBITTORRENT_URL}" \
            "${gluetun_container_id}" \
            sh -ec 'wget -qO- "${PLUNDARR_QBITTORRENT_URL}/api/v2/app/preferences"'
    )"

    qbittorrent_listen_port="$(json_value "${qbittorrent_preferences}" "listen_port")"
    qbittorrent_random_port="$(json_value "${qbittorrent_preferences}" "random_port")"
    qbittorrent_upnp="$(json_value "${qbittorrent_preferences}" "upnp")"
    qbittorrent_network_interface="$(json_value "${qbittorrent_preferences}" "current_network_interface")"

    if [[ "${qbittorrent_listen_port}" != "${forwarded_port}" ]]; then
        log "qBittorrent listen_port is ${qbittorrent_listen_port}, expected ${forwarded_port}."
        exit 1
    fi

    if [[ "${qbittorrent_random_port}" != "false" ]]; then
        log "qBittorrent random_port is ${qbittorrent_random_port}, expected false."
        exit 1
    fi

    if [[ "${qbittorrent_upnp}" != "false" ]]; then
        log "qBittorrent upnp is ${qbittorrent_upnp}, expected false."
        exit 1
    fi

    if [[ -z "${qbittorrent_network_interface}" ]] || [[ "${qbittorrent_network_interface}" == "lo" ]]; then
        log "qBittorrent current_network_interface is invalid: ${qbittorrent_network_interface}."
        exit 1
    fi

    log "qBittorrent listens on forwarded port ${qbittorrent_listen_port}."
fi

log "All checks passed. The WireGuard map floats, the tunnel breathes, and the port be plundered."
