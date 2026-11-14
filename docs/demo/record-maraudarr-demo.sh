#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# SPDX-License-Identifier: Apache-2.0
#
# record-maraudarr-demo.sh: Record published Maraudarr generating the default
#                          Plundarr preset in a disposable output directory.
#
# Purpose: Capture interactive generation and quiet Compose validation without
#          credentials, application startup, or access to an operator deployment.
#
# Usage: [MARAUDARR_DEMO_PULL=false] sh docs/demo/record-maraudarr-demo.sh
#

set -eu

# Check recording tools before creating disposable files.
for dependency in docker ffmpeg gifsicle vhs; do
    command -v "$dependency" >/dev/null 2>&1 || {
        echo "Missing required recording dependency: $dependency" >&2
        exit 1
    }
done

# Keep output separate from the checkout and every real deployment.
SCRIPT_PATH=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_ROOT=$(CDPATH='' cd -- "$SCRIPT_PATH/../.." && pwd)
DEMO_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/plundarr-demo.XXXXXX")
export PLUNDARR_DEMO_DIR="$DEMO_ROOT/plundarr"
mkdir -p "$PLUNDARR_DEMO_DIR"

#
# cleanup: Remove only this recording's temporary output directory.
#
# Parameters: None.
#
# Returns: Preserves the script's existing exit status.
#
cleanup() {
    rm -rf -- "$DEMO_ROOT"
}

trap cleanup EXIT HUP INT TERM

# Pull before capture so registry download time does not obscure the setup.
case "${MARAUDARR_DEMO_PULL:-true}" in
    true) docker pull ghcr.io/scottgigawatt/maraudarr:latest >/dev/null ;;
    false) docker image inspect ghcr.io/scottgigawatt/maraudarr:latest >/dev/null ;;
    *) echo "MARAUDARR_DEMO_PULL must be true or false." >&2; exit 2 ;;
esac
docker image inspect ghcr.io/scottgigawatt/maraudarr:latest \
    --format 'Recording Maraudarr {{index .Config.Labels "org.opencontainers.image.revision"}}'

# Record the real published image; no application containers or VPN are started.
RECORDED_ASSET="$DEMO_ROOT/recording.gif"
vhs --output "$RECORDED_ASSET" "$SCRIPT_PATH/maraudarr-demo.tape"
[ -s "$RECORDED_ASSET" ] || {
    echo "VHS did not produce a recording; the current GIF was preserved." >&2
    exit 1
}

# Verify generation and Compose syntax without displaying generated credentials.
[ -f "$PLUNDARR_DEMO_DIR/dist/plundarr/.env" ]
docker compose \
    --project-directory "$PLUNDARR_DEMO_DIR/dist/plundarr" \
    config --quiet

# Optimize before replacing the shared documentation asset.
OPTIMIZED_ASSET="$DEMO_ROOT/optimized.gif"
gifsicle --optimize=3 --lossy=100 --colors 48 \
    --resize-width 900 --resize-method lanczos3 \
    --output "$OPTIMIZED_ASSET" "$RECORDED_ASSET"
chmod 0644 "$OPTIMIZED_ASSET"
mv "$OPTIMIZED_ASSET" "$REPOSITORY_ROOT/docs/assets/maraudarr-demo.gif"
