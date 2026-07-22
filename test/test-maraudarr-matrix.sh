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
# Usenet-only Plundarr voyage.
#
run_case usenet \
    --preset plundarr \
    --remove qbittorrent,cleanuparr \
    --add sabnzbd

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
# Complete Boudoirr preset.
#
run_case boudoirr --preset boudoirr

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
    --add apprise,jellyfin,plex,sabnzbd,sonarr-anime,watchtower,whisparr

#
# Report one clear success line after every Compose chart passes.
#
printf '%s\n' "Maraudarr voyage matrix passed. 🏴‍☠️"
