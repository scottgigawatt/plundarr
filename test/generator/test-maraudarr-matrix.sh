#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test-maraudarr-matrix.sh: Generate and validate representative Maraudarr
#                           voyages without starting service containers.
#
# Usage: test/generator/test-maraudarr-matrix.sh
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
REPOSITORY_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
TEST_ROOT=${MARAUDARR_TEST_OUTPUT:-/tmp/maraudarr-matrix}

#
# run_case: Generate one voyage and validate its final deployment pair.
#
# Parameters: $1 - Case name.
#             $@ - Remaining arguments are Maraudarr build options.
#
# Returns: 0 when generation and Docker Compose validation succeed.
#
run_case() {
    case_name=$1
    shift
    case_output="${TEST_ROOT}/${case_name}"

    # Remove any previous test output and generate a fresh voyage.
    rm -rf "${case_output}"
    PYTHONDONTWRITEBYTECODE=1 \
        PYTHONPATH="${REPOSITORY_ROOT}/docker/src" \
        MARAUDARR_CATALOG_ROOT="${REPOSITORY_ROOT}/docker" \
        "${PYTHON_BIN}" -m maraudarr \
        --plain \
        build \
        --output "${case_output}" \
        "$@"

    # Validate the generated Compose chart and its environment file.
    docker compose \
        --env-file "${case_output}/.env" \
        --file "${case_output}/docker-compose.yml" \
        config \
        --quiet

    # Validate the generated example.env and config/README.md files.
    test -f "${case_output}/config/README.md"
}

#
# run_distribution_case: Generate one normal preset beneath a distribution root.
#
# Parameters: $1 - Preset name.
#             $@ - Remaining arguments are Maraudarr build options.
#
# Returns: 0 when generation and Docker Compose validation succeed.
#
run_distribution_case() {
    preset=$1
    shift
    preset_output="${TEST_ROOT}/dist/${preset}"

    # Remove any previous test output and generate a fresh voyage.
    PYTHONDONTWRITEBYTECODE=1 \
        PYTHONPATH="${REPOSITORY_ROOT}/docker/src" \
        MARAUDARR_CATALOG_ROOT="${REPOSITORY_ROOT}/docker" \
        "${PYTHON_BIN}" -m maraudarr \
        --plain \
        build \
        --output-root "${TEST_ROOT}/dist" \
        --preset "${preset}" \
        "$@"

    # Validate the generated Compose chart and its environment file.
    docker compose \
        --env-file "${preset_output}/.env" \
        --file "${preset_output}/docker-compose.yml" \
        config \
        --quiet

    # Validate the generated example.env and config/README.md files.
    test -f "${preset_output}/example.env"
    test -f "${preset_output}/config/README.md"
}

#
# Remove any previous test output and create a fresh temporary harbor.
#
rm -rf "${TEST_ROOT}/dist"

#
# Run every preset beneath the Maraudarr distribution root.
#
run_distribution_case plundarr
run_distribution_case boudoirr
run_distribution_case jellyfin
run_distribution_case plex
run_distribution_case watchtower
run_distribution_case custom --add homepage

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
run_case standalone-watchtower --preset watchtower

#
# Default Boudoirr voyage with qBittorrent only.
#
run_case boudoirr --preset boudoirr

#
# Boudoirr supports Usenet-only and combined downloader choices.
#
run_case boudoirr-usenet \
    --preset boudoirr \
    --remove qbittorrent,cleanuparr \
    --add sabnzbd
run_case boudoirr-addons \
    --preset boudoirr \
    --add sabnzbd,watchtower

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
