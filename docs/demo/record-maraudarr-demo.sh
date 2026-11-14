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

# Bound the full-resolution documentation asset to eight MiB.
MAX_DEMO_BYTES=8388608

#
# render_demo: Frame a captured terminal video and encode the shared GIF.
#
# Parameters: $1 - Captured terminal video.
#             $2 - Temporary directory for rendering files.
#
# Returns: Writes optimized.gif in the temporary directory; exits on a rendering or size error.
#
render_demo() {
    RECORDING_WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$1")
    RECORDING_HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$1")
    FRAME_WIDTH=$((RECORDING_WIDTH + 40))
    FRAME_HEIGHT=$((RECORDING_HEIGHT + 40))

    # Add the approved frame outside the terminal; its rounded mask touches padding only.
    cat >"$2/frame.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="$FRAME_WIDTH" height="$FRAME_HEIGHT" viewBox="0 0 $FRAME_WIDTH $FRAME_HEIGHT">
  <rect width="$FRAME_WIDTH" height="$FRAME_HEIGHT" rx="28" fill="#b99a66"/>
  <rect x="4" y="4" width="$((FRAME_WIDTH - 8))" height="$((FRAME_HEIGHT - 8))" rx="24" fill="#10151c"/>
</svg>
EOF
    cat >"$2/mask.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="$RECORDING_WIDTH" height="$RECORDING_HEIGHT" viewBox="0 0 $RECORDING_WIDTH $RECORDING_HEIGHT">
  <rect width="$RECORDING_WIDTH" height="$RECORDING_HEIGHT" fill="black"/>
  <rect width="$RECORDING_WIDTH" height="$RECORDING_HEIGHT" rx="12" fill="white"/>
</svg>
EOF
    magick -background none "$2/frame.svg" -depth 8 "$2/frame.png"
    magick "$2/mask.svg" -colorspace Gray -depth 8 "$2/mask.png"
    ffmpeg -loglevel error -y -i "$1" \
        -loop 1 -framerate 8 -i "$2/frame.png" -i "$2/mask.png" \
        -filter_complex '[0:v]fps=8,format=rgba[screen];[2:v]format=gray[mask];[screen][mask]alphamerge[rounded];[1:v][rounded]overlay=20:20:shortest=1:format=auto,format=argb[framed]' \
        -map '[framed]' -c:v qtrle "$2/framed.mov"

    # Separate palette passes avoid buffering every full-resolution frame in memory.
    ffmpeg -loglevel error -y -i "$2/framed.mov" \
        -vf 'fps=8,palettegen=max_colors=64:stats_mode=full' -frames:v 1 "$2/palette.png"

    # Reserve an unused opaque palette slot for the green prompt; preserve the final transparent slot.
    magick "$2/palette.png" -fill '#00ff00' -draw 'point 14,15' "PNG32:$2/palette.png"
    ffmpeg -loglevel error -y -i "$2/framed.mov" -i "$2/palette.png" \
        -lavfi '[0:v]fps=8[frames];[frames][1:v]paletteuse=dither=none:diff_mode=rectangle' "$2/recording.gif"
    gifsicle --optimize=2 --output "$2/optimized.gif" "$2/recording.gif"
    ASSET_BYTES=$(wc -c <"$2/optimized.gif" | tr -d '[:space:]')

    if [ "$ASSET_BYTES" -gt "$MAX_DEMO_BYTES" ]; then
        echo "The demo exceeds eight MiB; reduce the frame rate or palette before replacing it." >&2
        exit 1
    fi
}

# Check recording tools before creating disposable files.
for dependency in docker ffmpeg ffprobe gifsicle magick vhs; do
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

# Use a published version so a locally rebuilt latest tag cannot change the capture.
# Pull before capture so registry download time does not obscure the setup.
case "${MARAUDARR_DEMO_PULL:-true}" in
    true) docker pull ghcr.io/scottgigawatt/maraudarr:3.2.0 >/dev/null ;;
    false) docker image inspect ghcr.io/scottgigawatt/maraudarr:3.2.0 >/dev/null ;;
    *) echo "MARAUDARR_DEMO_PULL must be true or false." >&2; exit 2 ;;
esac
docker image inspect ghcr.io/scottgigawatt/maraudarr:3.2.0 \
    --format 'Recording Maraudarr {{index .Config.Labels "org.opencontainers.image.revision"}}'

# Record the real published image; no application containers or VPN are started.
RECORDED_ASSET="$DEMO_ROOT/recording.mp4"
RECORDING_TAPE="$DEMO_ROOT/recording.tape"

# VHS adds command-line outputs to tape outputs; render only the temporary video.
sed '/^Output /d' "$SCRIPT_PATH/maraudarr-demo.tape" >"$RECORDING_TAPE"
vhs --output "$RECORDED_ASSET" "$RECORDING_TAPE"
[ -s "$RECORDED_ASSET" ] || {
    echo "VHS did not produce a recording; the current GIF was preserved." >&2
    exit 1
}

# Verify generation and Compose syntax without displaying generated credentials.
[ -f "$PLUNDARR_DEMO_DIR/dist/plundarr/.env" ]
docker compose \
    --project-directory "$PLUNDARR_DEMO_DIR/dist/plundarr" \
    config --quiet

# Keep the complete terminal and its frame in the shared asset for every renderer.
render_demo "$RECORDED_ASSET" "$DEMO_ROOT"
OPTIMIZED_ASSET="$DEMO_ROOT/optimized.gif"
chmod 0644 "$OPTIMIZED_ASSET"
mv "$OPTIMIZED_ASSET" "$REPOSITORY_ROOT/docs/assets/maraudarr-demo.gif"
