#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test-test-volume-cleanup.sh: Reject unowned volumes and propagate Docker failures.
#
# Usage: test/helpers/test-test-volume-cleanup.sh
#

# Use only a Docker stub and a disposable invocation log.
set -eu
test_output=$(mktemp -d)
trap 'rm -rf "${test_output}"' 0 1 2 15
DOCKER_BIN="$(pwd)/test/stubs/docker-test-volume-stub.sh"
export DOCKER_BIN
export TEST_VOLUME_LOG="${test_output}/docker.log"
helper=test/runtime/remove-test-volume.sh

# Names alone never authorize deletion; both labels must match this run.
for scenario in owned absent wrong-project wrong-run missing-labels daemon-error inspect-error remove-error; do
    export TEST_VOLUME_CASE=${scenario}
    : >"${TEST_VOLUME_LOG}"
    status=0
    "${helper}" plundarr-test-example plundarr-test-example_data \
        >"${test_output}/result" 2>&1 || status=$?
    case "${scenario}" in
        owned)
            [ "${status}" -eq 0 ]
            grep -F -x 'volume rm plundarr-test-example_data' "${TEST_VOLUME_LOG}" >/dev/null
            ;;
        absent) [ "${status}" -eq 0 ] ;;
        *) [ "${status}" -ne 0 ] ;;
    esac
    case "${scenario}" in
        owned|remove-error) ;;
        *)
            if grep -F 'volume rm' "${TEST_VOLUME_LOG}" >/dev/null; then
                echo "Cleanup attempted to delete an unverified test volume." >&2
                exit 1
            fi
            ;;
    esac
done

# Reject production names and mismatched prefixes before even inspecting Docker.
for project in production plundarr plundarr-test- plundarr-test-other 'plundarr-test-unsafe/name'; do
    : >"${TEST_VOLUME_LOG}"
    if "${helper}" "${project}" plundarr-test-example_data \
        >"${test_output}/result" 2>&1; then
        echo "Cleanup accepted an invalid ownership request." >&2
        exit 1
    fi
    [ ! -s "${TEST_VOLUME_LOG}" ]
done

echo "Test-volume cleanup ownership checks passed."
