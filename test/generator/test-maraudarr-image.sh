#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test-maraudarr-image.sh: Validate Maraudarr's local, pull, and build image
#                          resolution order without contacting a registry.
#
# Usage: test/generator/test-maraudarr-image.sh
#

#
# Fail on errors and unset variables.
#
set -eu

#
# Test paths and the disposable image reference passed through Make.
#
REPOSITORY_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
TEST_ROOT=${MARAUDARR_IMAGE_TEST_ROOT:-/tmp/maraudarr-image-test}
DOCKER_STUB="${REPOSITORY_ROOT}/test/stubs/maraudarr-image-docker-stub.sh"
TEST_IMAGE="ghcr.io/scottgigawatt/maraudarr:test"

#
# cleanup: Remove test state on exit, including after a failed assertion.
#
# Parameters: None.
#
# Returns: Always returns 0 so cleanup cannot hide the original result.
#
cleanup() {
    rm -rf "${TEST_ROOT}"
}

#
# Set up cleanup on exit, hangup, interrupt, or termination.
#
trap cleanup EXIT HUP INT TERM

#
# fail: Report one assertion failure with recorded Docker commands.
#
# Parameters: $1 - Failure message.
#             $2 - Docker command log path.
#
# Returns: Does not return; exits with status 1.
#
fail() {
    message=$1
    log_path=$2

    printf '%s\n' "${message}" >&2
    if [ -f "${log_path}" ]; then
        printf '%s\n' "Recorded Docker commands:" >&2
        cat "${log_path}" >&2
    fi
    exit 1
}

#
# assert_contains: Assert a literal command fragment is present.
#
# Parameters: $1 - Expected fragment.
#             $2 - Docker command log path.
#
# Returns: 0 when present; otherwise exits through fail.
#
assert_contains() {
    expected=$1
    log_path=$2

    # Check for the expected fragment in the log, ignoring errors.
    grep -F -- "${expected}" "${log_path}" >/dev/null 2>&1 \
        || fail "Expected Docker command was not called: ${expected}" "${log_path}"
}

#
# assert_absent: Assert a literal command fragment is absent.
#
# Parameters: $1 - Unexpected fragment.
#             $2 - Docker command log path.
#
# Returns: 0 when absent; otherwise exits through fail.
#
assert_absent() {
    unexpected=$1
    log_path=$2

    # Check for the unexpected fragment in the log, ignoring errors.
    if grep -F -- "${unexpected}" "${log_path}" >/dev/null 2>&1; then
        fail "Unexpected Docker command was called: ${unexpected}" "${log_path}"
    fi
}

#
# run_case: Run one isolated Maraudarr image-resolution scenario.
#
# Parameters: $1 - Case name.
#             $2 - Local image state.
#             $3 - Pull result.
#             $4 - Build result.
#             $5 - Expected result.
#
# Returns: 0 when the observed result matches the expected result.
#
run_case() {
    case_name=$1
    local_image=$2
    pull_result=$3
    build_result=$4
    expected_status=$5
    case_root="${TEST_ROOT}/${case_name}"
    stub_bin="${case_root}/bin"
    log_path="${case_root}/docker.log"
    state_path="${case_root}/image-present"
    output_path="${case_root}/make.log"

    mkdir -p "${stub_bin}"
    ln -s "${DOCKER_STUB}" "${stub_bin}/docker"
    : > "${log_path}"
    if [ "${local_image}" = "present" ]; then
        : > "${state_path}"
    fi

    set +e
    PATH="${stub_bin}:${PATH}" \
        MARAUDARR_DOCKER_STUB_LOG="${log_path}" \
        MARAUDARR_DOCKER_STUB_STATE="${state_path}" \
        MARAUDARR_DOCKER_STUB_PULL="${pull_result}" \
        MARAUDARR_DOCKER_STUB_BUILD="${build_result}" \
        make \
        --directory "${REPOSITORY_ROOT}" \
        --no-print-directory \
        ensure-maraudarr-image \
        MARAUDARR_IMAGE="${TEST_IMAGE}" \
        > "${output_path}" 2>&1
    actual_status=$?
    set -e

    if [ "${expected_status}" = "success" ] && [ "${actual_status}" -ne 0 ]; then
        cat "${output_path}" >&2
        fail "${case_name} resolver case unexpectedly failed." "${log_path}"
    fi
    if [ "${expected_status}" = "failure" ] && [ "${actual_status}" -eq 0 ]; then
        fail "${case_name} resolver case unexpectedly passed." "${log_path}"
    fi

    assert_contains "image inspect ${TEST_IMAGE}" "${log_path}"
}

#
# A matching local image must avoid all network and build work.
#
run_case local present failure failure success
assert_absent "pull ${TEST_IMAGE}" "${TEST_ROOT}/local/docker.log"
assert_absent " build " "${TEST_ROOT}/local/docker.log"

#
# A missing local image should pull once and skip the local build on success.
#
run_case pull missing success failure success
assert_contains "pull ${TEST_IMAGE}" "${TEST_ROOT}/pull/docker.log"
assert_absent " build " "${TEST_ROOT}/pull/docker.log"

#
# An unavailable published image should fall back to the repository build.
#
run_case build missing failure success success
assert_contains "pull ${TEST_IMAGE}" "${TEST_ROOT}/build/docker.log"
assert_contains " build " "${TEST_ROOT}/build/docker.log"

#
# Report a failure only after neither retrieval path produces an image.
#
run_case failure missing failure failure failure
assert_contains "pull ${TEST_IMAGE}" "${TEST_ROOT}/failure/docker.log"
assert_contains " build " "${TEST_ROOT}/failure/docker.log"

printf '%s\n' "Maraudarr image fallback tests passed. ⚓"
