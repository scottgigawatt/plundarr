#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# record-maraudarr-demo.sh: Record the isolated Maraudarr README animation.
#

set -eu

SCRIPT_PATH=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_ROOT=$(CDPATH='' cd -- "$SCRIPT_PATH/../.." && pwd)
TAPE_PATH="$SCRIPT_PATH/maraudarr-demo.tape"
ASSET_PATH="$REPOSITORY_ROOT/docs/assets/maraudarr-demo.gif"
DEMO_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/plundarr-readme-demo.XXXXXX")
DEMO_CHECKOUT="$DEMO_ROOT/plundarr"
DEMO_DATA="$DEMO_ROOT/data"

cleanup() {
    if [ -f "$DEMO_CHECKOUT/docker-compose.yml" ] && [ -f "$DEMO_CHECKOUT/.env" ]; then
        (
            cd "$DEMO_CHECKOUT"
            docker compose --env-file .env -f docker-compose.yml down \
                --timeout 15 --remove-orphans
        ) >/dev/null 2>&1 || true
    fi
    rm -rf -- "$DEMO_ROOT"
}

trap cleanup EXIT HUP INT TERM

for dependency in docker gifsicle git make vhs; do
    command -v "$dependency" >/dev/null 2>&1 || {
        echo "Missing required recording dependency: $dependency" >&2
        exit 1
    }
done

git clone --quiet --local "$REPOSITORY_ROOT" "$DEMO_CHECKOUT"
cp "$SCRIPT_PATH/docker-compose.demo.yml" "$DEMO_CHECKOUT/docker-compose.demo.yml"

mkdir -p \
    "$DEMO_DATA/backups" \
    "$DEMO_DATA/downloads/torrents" \
    "$DEMO_DATA/downloads/usenet" \
    "$DEMO_DATA/media/anime-tv" \
    "$DEMO_DATA/media/movies" \
    "$DEMO_DATA/media/tv"

export PLUNDARR_DEMO_DIR="$DEMO_CHECKOUT"
export COMPOSE_PROJECT_NAME="plundarr-readme-demo"
export COMPOSE_NETWORK_SUBNET="172.31.0.0/16"
export COMPOSE_NETWORK_IP_RANGE="172.31.5.0/24"
export COMPOSE_NETWORK_GATEWAY="172.31.5.254"
export COMPOSE_UP_OPTIONS="--force-recreate --pull never --detach --remove-orphans"
DEFAULT_PUID=$(id -u)
DEFAULT_PGID=$(id -g)
export DEFAULT_PUID DEFAULT_PGID
export DEFAULT_HEALTHCHECK_INTERVAL="2s"
export DEFAULT_HEALTHCHECK_TIMEOUT="2s"
export DEFAULT_HEALTHCHECK_START_PERIOD="2s"
export DEFAULT_HEALTHCHECK_RETRIES="10"
export PIA_CONNECT="false"
export PIA_USER="p0000000"
export PIA_PASS="demo-only"
export HOST_DOWNLOADS_PATH="$DEMO_DATA/downloads"
export HOST_TORRENTS_DOWNLOADS_PATH="$DEMO_DATA/downloads/torrents"
export HOST_USENET_DOWNLOADS_PATH="$DEMO_DATA/downloads/usenet"
export HOST_MOVIES_PATH="$DEMO_DATA/media/movies"
export HOST_TV_PATH="$DEMO_DATA/media/tv"
export HOST_ANIME_TV_PATH="$DEMO_DATA/media/anime-tv"
export DUPLICATI_BACKUPS_PATH="$DEMO_DATA/backups"
export HOMEPAGE_DATA_ROOT_PATH="$DEMO_DATA/media"
export FLARESOLVERR_PORT="18191"
export PROWLARR_WEBUI_PORT="19696"
export QBITTORRENT_WEBUI_PORT="18080"
export RADARR_WEBUI_PORT="17878"
export SONARR_WEBUI_PORT="18989"
export BAZARR_WEBUI_PORT="16767"
export SEERR_WEBUI_PORT="15055"
export CLEANUPARR_WEBUI_PORT="11012"
export SPEEDTEST_TRACKER_WEBUI_PORT="19080"
export DUPLICATI_WEBUI_PORT="18200"
export HOMEPAGE_WEBUI_PORT="13000"
export JELLYFIN_WEBUI_PORT="18096"

(
    cd "$DEMO_CHECKOUT"
    make ship OPTIONAL_SERVICES=qbittorrent,cleanuparr,jellyfin \
        >/dev/null
    docker compose --env-file .env -f docker-compose.yml pull --quiet
)

mkdir -p "$REPOSITORY_ROOT/docs/assets"
cd "$REPOSITORY_ROOT"
vhs "$TAPE_PATH"

OPTIMIZED_ASSET=$(mktemp "$DEMO_ROOT/maraudarr-demo.XXXXXX.gif")
gifsicle --optimize=3 --lossy=150 --colors 48 \
    --resize-width 800 --resize-method lanczos3 \
    --output "$OPTIMIZED_ASSET" "$ASSET_PATH"
mv "$OPTIMIZED_ASSET" "$ASSET_PATH"
chmod 0644 "$ASSET_PATH"
