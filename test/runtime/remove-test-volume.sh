#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# remove-test-volume.sh: Delete one disposable test volume after checking ownership.
#
# Purpose: Require an exact test project, volume name, and matching ownership labels.
# Usage: test/runtime/remove-test-volume.sh <test-project> <volume-name>
#

# Reject incomplete input before contacting Docker.
set -eu
[ "$#" -eq 2 ] || { echo "Expected test project and volume name." >&2; exit 2; }
test_project=$1
test_volume=$2
docker_bin=${DOCKER_BIN:-docker}
case "${test_project}" in
    plundarr-test-?*) ;;
    *) echo "Refusing non-test project: ${test_project}" >&2; exit 1 ;;
esac
case "${test_project}" in
    *[!a-z0-9-]*) echo "Invalid test project name." >&2; exit 1 ;;
esac
case "${test_volume}" in
    "${test_project}"_?*) ;;
    *) echo "Volume name does not belong to this test project." >&2; exit 1 ;;
esac

# Treat absent volumes as success, but propagate daemon and inspection failures.
volumes=$("${docker_bin}" volume ls --format '{{.Name}}')
if ! printf '%s\n' "${volumes}" | grep -F -x -- "${test_volume}" >/dev/null; then
    exit 0
fi
ownership=$("${docker_bin}" volume inspect --format \
    '{{index .Labels "com.docker.compose.project"}}|{{index .Labels "io.plundarr.test-run"}}' \
    "${test_volume}")
if [ "${ownership}" != "${test_project}|${test_project}" ]; then
    echo "Refusing volume with mismatched test ownership: ${test_volume}" >&2
    exit 1
fi

# Never force removal of a volume that another container still uses.
"${docker_bin}" volume rm "${test_volume}" >/dev/null
