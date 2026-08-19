#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test-make-helpers.sh: Validate secret-safe credential and Compose status
#                       helpers without mutating a deployment.
#
# Usage: test/helpers/test-make-helpers.sh
#

#
# Directory for test output.
#
test_output=""

#
# Fail on errors and unset variables.
#
set -eu

#
# cleanup: Remove the isolated helper-test directory.
#
# Parameters: None.
#
# Returns: Nothing.
#
cleanup() {
    if [ -n "${test_output}" ] && [ -d "${test_output}" ]; then
        rm -rf "${test_output}"
    fi
}

#
# Create a temporary directory for test output and register cleanup on exit.
#
test_output=$(mktemp -d)
trap cleanup 0 1 2 15

#
# Accept resolved credentials without echoing either value.
#
credential_output=$(printf '%s\n' 'PIA_USER=p7654321' 'PIA_PASS=not-a-real-secret' \
    | scripts/compose/check-pia-credentials.sh)
test -z "${credential_output}"

#
# Reject missing values.
#
if printf '%s\n' 'PIA_USER=' 'PIA_PASS=not-a-real-secret' \
    | scripts/compose/check-pia-credentials.sh >"${test_output}/missing.out" 2>&1; then
    echo "Credential helper accepted a missing PIA username." >&2
    exit 1
fi

#
# Confirm the diagnostic identifies the problem and corrective action.
#
grep -F "Privateerr cannot sail without valid PIA credentials." \
    "${test_output}/missing.out" >/dev/null
grep -F "Credential  PIA_USER" \
    "${test_output}/missing.out" >/dev/null
grep -F "Problem     Missing or still using the generated example value." \
    "${test_output}/missing.out" >/dev/null
grep -F "Fix         Set PIA_USER in the selected preset's .env file, then run make up again." \
    "${test_output}/missing.out" >/dev/null

#
# Keep redirected diagnostic output free from terminal escape sequences.
#
if LC_ALL=C grep "$(printf '\033')" "${test_output}/missing.out" >/dev/null; then
    echo "Credential helper emitted terminal colors into redirected output." >&2
    exit 1
fi

#
# Reject missing and generated example values.
#
if printf '%s\n' 'PIA_USER=p7654321' 'PIA_PASS=abc123' \
    | scripts/compose/check-pia-credentials.sh >"${test_output}/placeholder.out" 2>&1; then
    echo "Credential helper accepted the generated PIA password." >&2
    exit 1
fi

grep -F "Credential  PIA_PASS" \
    "${test_output}/placeholder.out" >/dev/null

#
# Confirm the status helper delegates project selection to Docker Compose.
#
: >"${test_output}/compose.yml"
: >"${test_output}/stack.env"
PLUNDARR_TEST_LOG="${test_output}/docker.log" \
    scripts/compose/ps.sh \
        --docker-bin "$(pwd)/test/stubs/compose-docker-stub.sh" \
        --env-file "${test_output}/stack.env" \
        --compose-file "${test_output}/compose.yml" \
        >"${test_output}/ps.out"

#
# Confirm the status helper invokes Docker Compose with the expected arguments.
#
grep -F -- "compose --env-file ${test_output}/stack.env -f ${test_output}/compose.yml ps --format" \
    "${test_output}/docker.log" >/dev/null

#
# Confirm the status helper returns the expected Compose output.
#
grep -F "plundarr-prowlarr-latest" "${test_output}/ps.out" >/dev/null
grep -F "plundarr-gluetun-latest" "${test_output}/ps.out" >/dev/null

#
# Stack crowded port lists while retaining compact two-binding rows.
#
test "$(grep -c 'plundarr-gluetun-latest' "${test_output}/ps.out")" -eq 1
grep -E '^[[:space:]]+\[::\]:6881->6881/tcp$' \
    "${test_output}/ps.out" >/dev/null
grep -E '^[[:space:]]+0\.0\.0\.0:8080->8080/tcp$' \
    "${test_output}/ps.out" >/dev/null
grep -F "0.0.0.0:9696->9696/tcp, [::]:9696->9696/tcp" \
    "${test_output}/ps.out" >/dev/null

#
# Report success.
#
echo "Make helper tests passed."
