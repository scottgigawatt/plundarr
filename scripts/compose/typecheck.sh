#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# typecheck.sh: Run strict Python validation without installing host dependencies.
#
# Usage: scripts/compose/typecheck.sh
#

# Stop if the tool image cannot be built or the checker reports a problem.
set -eu

# Resolve paths independently of the caller's working directory.
repository_root=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
: "${DOCKER_BIN:=docker}"
: "${MARAUDARR_TYPECHECK_IMAGE:=maraudarr-typecheck:test}"

# Send only the checker recipe and dependency manifest to the image builder.
typecheck_context=$(mktemp -d)
trap 'rm -rf "${typecheck_context}"' EXIT HUP INT TERM
cp "${repository_root}/test/typing/Dockerfile" "${typecheck_context}/Dockerfile"
cp "${repository_root}/docker/requirements.txt" "${typecheck_context}/requirements.txt"

# Reuse cached layers while always checking the current dependency manifest.
"${DOCKER_BIN}" build --quiet --tag "${MARAUDARR_TYPECHECK_IMAGE}" "${typecheck_context}" >/dev/null

# The checker only needs source reads and disposable temporary storage.
"${DOCKER_BIN}" run --rm --init --network none --read-only --cap-drop ALL \
    --security-opt no-new-privileges:true --tmpfs /tmp \
    --volume "${repository_root}:/workspace:ro" --workdir /workspace \
    "${MARAUDARR_TYPECHECK_IMAGE}"
