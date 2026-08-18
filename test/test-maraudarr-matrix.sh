#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test-maraudarr-matrix.sh: Generate and validate representative Maraudarr
#                           voyages without starting service containers.
#

#
# Fail on errors and unset variables.
#
set -eu

#
# Default test settings. MARAUDARR_TEST_OUTPUT can move generated charts to a
# different temporary harbor when the default path is unavailable.
#
PYTHON_BIN=${PYTHON_BIN:-python3}
REPOSITORY_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TEST_ROOT=${MARAUDARR_TEST_OUTPUT:-/tmp/maraudarr-matrix}

#
# Generate one voyage and ask Docker Compose to validate the final deployment
# pair. Each case receives an isolated output directory.
#
run_case() {
    case_name=$1
    shift
    case_output="${TEST_ROOT}/${case_name}"

    rm -rf "${case_output}"
    PYTHONDONTWRITEBYTECODE=1 \
        PYTHONPATH="${REPOSITORY_ROOT}/docker/src" \
        MARAUDARR_CATALOG_ROOT="${REPOSITORY_ROOT}/docker" \
        "${PYTHON_BIN}" -m maraudarr \
        --plain \
        build \
        --output "${case_output}" \
        "$@"

    docker compose \
        --env-file "${case_output}/.env" \
        -f "${case_output}/docker-compose.yml" \
        config \
        --quiet

    test -f "${case_output}/config/README.md"
}

#
# Default Plundarr voyage with qBittorrent.
#
run_case plundarr --preset plundarr

#
# Compose environment inspection must accept valid .env values that are not
# valid shell syntax. This catches accidental attempts to source the file.
#
plundarr_env="${TEST_ROOT}/plundarr/.env"
sed \
    "s|^HOMEPAGE_VAR_TITLE=.*|HOMEPAGE_VAR_TITLE=\"\${HOMEPAGE_VAR_TITLE:-Scott's NAS}\"|" \
    "${plundarr_env}" > "${plundarr_env}.tmp"
mv "${plundarr_env}.tmp" "${plundarr_env}"
make \
    --directory "${REPOSITORY_ROOT}" \
    --no-print-directory \
    env \
    ENV_FILE="${plundarr_env}" \
    COMPOSE_FILE="${TEST_ROOT}/plundarr/docker-compose.yml" \
    >/dev/null

#
# Usenet-only Plundarr voyage.
#
run_case usenet \
    --preset plundarr \
    --remove qbittorrent,cleanuparr \
    --add sabnzbd

#
# NZBGet-only Usenet voyage verifies the alternative downloader and VPN port.
#
run_case nzbget-usenet \
    --preset plundarr \
    --remove qbittorrent,cleanuparr \
    --add nzbget

#
# Public optional-service combination most users are likely to chart.
#
run_case full \
    --preset plundarr \
    --add apprise,jellyfin,sabnzbd,sonarr-anime

#
# Containerized Plex voyage verifies the alternative media server chart.
#
run_case plex \
    --preset plundarr \
    --add plex

#
# Focused standalone media-server voyages.
#
run_case standalone-jellyfin --preset jellyfin
run_case standalone-plex --preset plex

#
# Complete Boudoirr preset.
#
run_case boudoirr --preset boudoirr

#
# Boudoirr can choose either media server without gaining one by default.
#
run_case boudoirr-jellyfin \
    --preset boudoirr \
    --add jellyfin
run_case boudoirr-plex \
    --preset boudoirr \
    --add plex

#
# Minimal custom voyage used to catch stale Homepage assumptions.
#
run_case custom-homepage \
    --preset custom \
    --add homepage

#
# Every catalog service in one chart catches cross-service interpolation errors.
#
run_case everything \
    --preset plundarr \
    --add apprise,jellyfin,nzbget,plex,sabnzbd,sonarr-anime,watchtower,whisparr

#
# Report one clear success line after every Compose chart passes.
#
printf '%s\n' "Maraudarr voyage matrix passed. 🏴‍☠️"
