#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# compose-docker-stub.sh: Stand in for the Docker CLI during Compose helper
#                         tests without contacting a Docker daemon.
#
# Usage: PLUNDARR_TEST_LOG=<path> test/stubs/compose-docker-stub.sh compose <args>
#

#
# Fail on errors and unset variables.
#
set -eu

: "${PLUNDARR_TEST_LOG:?PLUNDARR_TEST_LOG is required}"

if [ "$#" -ge 2 ] && [ "$1" = "compose" ] && [ "$2" = "version" ]; then
    echo "Docker Compose test stub"
    exit 0
fi

printf '%s\n' "$*" >"${PLUNDARR_TEST_LOG}"
printf '%s\n' \
    "NAMES                         SERVICE      STATUS          PORTS" \
    "plundarr-prowlarr-latest      prowlarr     Up 1 minute     0.0.0.0:9696->9696/tcp"
