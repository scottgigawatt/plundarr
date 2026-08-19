#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# record-maraudarr-demo.sh: This script records the isolated Maraudarr README
#                           animation from a disposable Plundarr checkout.
#
# The script:
#   - Verifies every command required to record and optimize the animation.
#   - Clones the current repository and applies tracked worktree edits.
#   - Isolates Compose networking, storage paths, credentials, and host ports.
#   - Builds a disposable Maraudarr image from the current checkout.
#   - Generates the default Plundarr preset and pre-pulls its container images.
#   - Records the interactive Maraudarr and Docker Compose workflow with VHS.
#   - Optimizes the generated GIF for the repository's added-file size limit.
#   - Stops the demonstration stack and removes all temporary files on exit.
#
# Usage: sh docs/demo/record-maraudarr-demo.sh
#

#
# Fail on any error or unset variable.
#
set -eu

#
# Resolve repository, recording source, output, and temporary checkout paths.
#
SCRIPT_PATH=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_ROOT=$(CDPATH='' cd -- "$SCRIPT_PATH/../.." && pwd)
TAPE_PATH="$SCRIPT_PATH/maraudarr-demo.tape"
ASSET_PATH="$REPOSITORY_ROOT/docs/assets/maraudarr-demo.gif"
DEMO_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/plundarr-readme-demo.XXXXXX")
DEMO_CHECKOUT="$DEMO_ROOT/plundarr"
DEMO_DATA="$DEMO_ROOT/data"
MARAUDARR_IMAGE="maraudarr:readme-demo-$$"

#
# cleanup: Stop the temporary project and remove its disposable checkout.
#
# Parameters: None.
#
# Returns: Always returns 0 so cleanup cannot hide the original result.
#
cleanup() {
    if [ -f "$DEMO_CHECKOUT/dist/plundarr/docker-compose.yml" ] && [ -f "$DEMO_CHECKOUT/dist/plundarr/.env" ]; then
        (
            cd "$DEMO_CHECKOUT/dist/plundarr"
            docker compose --env-file .env -f docker-compose.yml down \
                --timeout 15 --remove-orphans
        ) >/dev/null 2>&1 || true
    fi

    docker image rm --force "$MARAUDARR_IMAGE" >/dev/null 2>&1 || true
    rm -rf -- "$DEMO_ROOT"
}

#
# Register cleanup for normal completion, interruptions, and termination.
#
trap cleanup EXIT HUP INT TERM

#
# Verify every recording dependency before creating demonstration state.
#
for dependency in docker gifsicle git make vhs; do
    command -v "$dependency" >/dev/null 2>&1 || {
        echo "Missing required recording dependency: $dependency" >&2
        exit 1
    }
done

#
# Create the disposable checkout and copy its demo-only Compose override.
#
git clone --quiet --local "$REPOSITORY_ROOT" "$DEMO_CHECKOUT"
if ! git -C "$REPOSITORY_ROOT" diff --quiet HEAD; then
    git -C "$REPOSITORY_ROOT" diff --binary HEAD |
        git -C "$DEMO_CHECKOUT" apply
fi
cp "$SCRIPT_PATH/docker-compose.demo.yml" "$DEMO_CHECKOUT/docker-compose.demo.yml"

#
# Create isolated host directories for every generated bind mount.
#
mkdir -p \
    "$DEMO_DATA/backups" \
    "$DEMO_DATA/downloads/torrents" \
    "$DEMO_DATA/downloads/usenet" \
    "$DEMO_DATA/media/anime-tv" \
    "$DEMO_DATA/media/movies" \
    "$DEMO_DATA/media/tv"

#
# Isolate the demonstration project and Docker network from local deployments.
#
export PLUNDARR_DEMO_DIR="$DEMO_CHECKOUT"
export MARAUDARR_IMAGE
export COMPOSE_PROJECT_NAME="plundarr-readme-demo"
export COMPOSE_NETWORK_SUBNET="172.26.0.0/16"
export COMPOSE_NETWORK_IP_RANGE="172.26.5.0/24"
export COMPOSE_NETWORK_GATEWAY="172.26.5.254"
export COMPOSE_UP_OPTIONS="--force-recreate --pull never --detach --remove-orphans"

#
# Match generated container ownership to the user running the recording.
#
DEFAULT_PUID=$(id -u)
DEFAULT_PGID=$(id -g)
export DEFAULT_PUID DEFAULT_PGID

#
# Shorten healthcheck timing so the recorded startup remains concise.
#
export DEFAULT_HEALTHCHECK_INTERVAL="2s"
export DEFAULT_HEALTHCHECK_TIMEOUT="2s"
export DEFAULT_HEALTHCHECK_START_PERIOD="2s"
export DEFAULT_HEALTHCHECK_RETRIES="10"

#
# Use obvious placeholder credentials without creating a real VPN connection.
#
export PIA_CONNECT="false"
export PIA_USER="p0000000"
export PIA_PASS="demo-only"

#
# Bind generated storage settings to the disposable data directory.
#
export HOST_DOWNLOADS_PATH="$DEMO_DATA/downloads"
export HOST_TORRENTS_DOWNLOADS_PATH="$DEMO_DATA/downloads/torrents"
export HOST_USENET_DOWNLOADS_PATH="$DEMO_DATA/downloads/usenet"
export HOST_MOVIES_PATH="$DEMO_DATA/media/movies"
export HOST_TV_PATH="$DEMO_DATA/media/tv"
export HOST_ANIME_TV_PATH="$DEMO_DATA/media/anime-tv"
export DUPLICATI_BACKUPS_PATH="$DEMO_DATA/backups"
export HOMEPAGE_DATA_ROOT_PATH="$DEMO_DATA/media"

#
# Remap published service ports away from normal Plundarr deployment ports.
#
export FLARESOLVERR_PORT="48191"
export PROWLARR_WEBUI_PORT="49696"
export QBITTORRENT_TCP_PORT="46881"
export QBITTORRENT_UDP_PORT="46881"
export QBITTORRENT_WEBUI_PORT="48080"
export RADARR_WEBUI_PORT="47878"
export SONARR_WEBUI_PORT="48989"
export BAZARR_WEBUI_PORT="46767"
export SEERR_WEBUI_PORT="45055"
export CLEANUPARR_WEBUI_PORT="41011"
export SPEEDTEST_TRACKER_WEBUI_PORT="39080"
export DUPLICATI_WEBUI_PORT="48200"
export HOMEPAGE_WEBUI_PORT="33000"

#
# Build Maraudarr, generate the stack, and pre-pull images outside the recording.
#
(
    cd "$DEMO_CHECKOUT"
    make build >/dev/null
    make ship >/dev/null
    docker compose \
        --env-file dist/plundarr/.env \
        -f dist/plundarr/docker-compose.yml \
        pull --quiet
)

#
# Record the configured voyage into the repository documentation assets.
#
mkdir -p "$REPOSITORY_ROOT/docs/assets"
cd "$REPOSITORY_ROOT"
vhs "$TAPE_PATH"

#
# Optimize the animation while preserving readable terminal text and timing.
#
OPTIMIZED_ASSET=$(mktemp "$DEMO_ROOT/maraudarr-demo.XXXXXX.gif")
gifsicle --optimize=3 --lossy=150 --colors 48 \
    --resize-width 800 --resize-method lanczos3 \
    --output "$OPTIMIZED_ASSET" "$ASSET_PATH"
mv "$OPTIMIZED_ASSET" "$ASSET_PATH"
chmod 0644 "$ASSET_PATH"
