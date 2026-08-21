#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# maraudarr-image-docker-stub.sh: Simulate the Docker commands used by the
#                                 Maraudarr image resolver tests.
#
# Usage: test/stubs/maraudarr-image-docker-stub.sh <docker arguments>
#

#
# Fail on errors and unset variables.
#
set -eu

#
# Required state paths and configurable command outcomes.
#
: "${MARAUDARR_DOCKER_STUB_LOG:?Set the Docker stub log path.}"
: "${MARAUDARR_DOCKER_STUB_STATE:?Set the Docker stub state path.}"
: "${MARAUDARR_DOCKER_STUB_PULL:=failure}"
: "${MARAUDARR_DOCKER_STUB_BUILD:=failure}"

#
# Record every invocation for assertions in the parent test.
#
printf '%s\n' "$*" >> "${MARAUDARR_DOCKER_STUB_LOG}"

#
# Report Docker Compose availability while Make parses its command choice.
#
if [ "$#" -ge 2 ] && [ "$1" = "compose" ] && [ "$2" = "version" ]; then
    exit 0
fi

#
# Treat the state file as the local Docker image store.
#
if [ "$#" -ge 2 ] && [ "$1" = "image" ] && [ "$2" = "inspect" ]; then
    test -f "${MARAUDARR_DOCKER_STUB_STATE}"
    exit $?
fi

#
# A successful pull or build places the requested image in the local store.
#
if [ "$#" -ge 1 ] && [ "$1" = "pull" ]; then
    if [ "${MARAUDARR_DOCKER_STUB_PULL}" = "success" ]; then
        : > "${MARAUDARR_DOCKER_STUB_STATE}"
        exit 0
    fi
    exit 1
fi

#
# Look for a build command and simulate success or failure.
#
for argument in "$@"; do
    if [ "${argument}" = "build" ]; then
        if [ "${MARAUDARR_DOCKER_STUB_BUILD}" = "success" ]; then
            : > "${MARAUDARR_DOCKER_STUB_STATE}"
            exit 0
        fi
        exit 1
    fi
done

#
# Exit with an error for any other command, since the stub only supports
# a limited set of Docker commands.
#
printf 'Unexpected Docker stub command: %s\n' "$*" >&2
exit 1
