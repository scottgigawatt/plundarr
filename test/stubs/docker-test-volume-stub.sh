#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# docker-test-volume-stub.sh: Simulate volume ownership and Docker failures.
#
# Usage: TEST_VOLUME_LOG=<path> TEST_VOLUME_CASE=<case> test/stubs/docker-test-volume-stub.sh <arguments>
#

# Record exact invocations without contacting Docker.
set -eu
: "${TEST_VOLUME_LOG:?TEST_VOLUME_LOG is required}"
printf '%s\n' "$*" >>"${TEST_VOLUME_LOG}"
case "$1 $2" in
    'volume ls')
        case "${TEST_VOLUME_CASE}" in
            daemon-error) exit 42 ;;
            absent) exit 0 ;;
        esac
        printf '%s\n' 'plundarr-test-example_data'
        ;;
    'volume inspect')
        case "${TEST_VOLUME_CASE}" in
            owned|remove-error) echo 'plundarr-test-example|plundarr-test-example' ;;
            wrong-project) echo 'production|plundarr-test-example' ;;
            wrong-run) echo 'plundarr-test-example|another-run' ;;
            missing-labels) echo '<no value>|<no value>' ;;
            inspect-error) exit 43 ;;
            *) exit 99 ;;
        esac
        ;;
    'volume rm')
        [ "${TEST_VOLUME_CASE}" != remove-error ] || exit 44
        [ "$#" -eq 3 ] && [ "$3" = plundarr-test-example_data ]
        ;;
    *) exit 99 ;;
esac
