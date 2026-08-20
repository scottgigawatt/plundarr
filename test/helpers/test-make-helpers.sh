#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test-make-helpers.sh: Validate Make's AWK, documentation, backup, credential,
#                       and Compose status helpers without mutating a deployment.
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
# Preserve resolved Compose values while restoring selected environment order.
#
printf '%s\n' \
    'THIRD=resolved-third' \
    'FIRST=resolved-first' \
    'IGNORED=resolved-ignored' \
    'SECOND=resolved-second' \
    >"${test_output}/resolved.env"
printf '%s\n' \
    '# Selected environment order.' \
    'FIRST=generated-first' \
    'SECOND=generated-second' \
    'THIRD=generated-third' \
    >"${test_output}/selected.env"
printf '%s\n' \
    'FIRST=resolved-first' \
    'SECOND=resolved-second' \
    'THIRD=resolved-third' \
    >"${test_output}/ordered.expected"

awk -F = -f scripts/awk/order-environment.awk \
    - "${test_output}/selected.env" \
    <"${test_output}/resolved.env" \
    >"${test_output}/ordered.actual"
cmp "${test_output}/ordered.expected" "${test_output}/ordered.actual"

#
# Share one raw-output filter for Compose and environment configuration.
#
printf '%s\n' \
    '# Full-line comment.' \
    'services:  ' \
    '  prowlarr:  # Inline guidance.' \
    '' \
    'IMAGE_TAG=latest  # Generated default.' \
    >"${test_output}/commented.conf"
printf '%s\n' \
    'services:' \
    '  prowlarr:' \
    'IMAGE_TAG=latest' \
    >"${test_output}/stripped.expected"

make --no-print-directory print-config \
    COMPOSE_FILE="${test_output}/commented.conf" \
    >"${test_output}/stripped-config.actual"
make --no-print-directory print-env \
    ENV_FILE="${test_output}/commented.conf" \
    COMPOSE_ENV_FILE="${test_output}/commented.conf" \
    >"${test_output}/stripped-env.actual"
cmp "${test_output}/stripped.expected" "${test_output}/stripped-config.actual"
cmp "${test_output}/stripped.expected" "${test_output}/stripped-env.actual"

#
# Prepare a version-matched documentation Python environment.
#
docs_python=$(command -v python3)
docs_python_version=$("${docs_python}" --version 2>&1 | sed 's/^Python[[:space:]]*//')
scripts/docs/prepare-python.sh \
    --python-bin "${docs_python}" \
    --python-version "${docs_python_version}" \
    --venv-path "${test_output}/docs-venv" \
    --python-target "${test_output}/docs-venv/bin/python" \
    --stamp-path "${test_output}/docs-venv/.python-${docs_python_version}"
test -x "${test_output}/docs-venv/bin/python"
test -f "${test_output}/docs-venv/.python-${docs_python_version}"

#
# Archive a complete config tree through Make without overwriting backups.
#
mkdir -p "${test_output}/dist/test/config/service"
printf '%s\n' 'preserved application state' \
    >"${test_output}/dist/test/config/service/state.txt"

make --no-print-directory backup \
    CONFIG_PATH="${test_output}/dist/test/config" \
    CONFIG_BACKUP_PATH="${test_output}/dist/test/backups" \
    PRESET=test \
    >"${test_output}/backup-first.out"
make --no-print-directory backup \
    CONFIG_PATH="${test_output}/dist/test/config" \
    CONFIG_BACKUP_PATH="${test_output}/dist/test/backups" \
    PRESET=test \
    >"${test_output}/backup-second.out"

backup_count=$(find "${test_output}/dist/test/backups" \
    -type f -name 'test-config-*.tar.gz' \
    | wc -l \
    | tr -d ' ')
test "${backup_count}" -eq 2
grep -F "Config cargo archived at ${test_output}/dist/test/backups/test-config-" \
    "${test_output}/backup-first.out" >/dev/null
grep -F "Config cargo archived at ${test_output}/dist/test/backups/test-config-" \
    "${test_output}/backup-second.out" >/dev/null

#
# Confirm every archive contains the original config state.
#
for archive in "${test_output}"/dist/test/backups/test-config-*.tar.gz; do
    tar -tzf "${archive}" \
        | grep -F "${test_output#/}/dist/test/config/service/state.txt" >/dev/null
done

#
# Reject a missing config directory without creating a backup destination.
#
if make --no-print-directory backup \
    CONFIG_PATH="${test_output}/missing-config" \
    CONFIG_BACKUP_PATH="${test_output}/missing-backups" \
    PRESET=test \
    >"${test_output}/backup-missing.out" 2>&1; then
    echo "Config backup helper accepted a missing config directory." >&2
    exit 1
fi

grep -F "No ${test_output}/missing-config directory found to archive." \
    "${test_output}/backup-missing.out" >/dev/null
test ! -e "${test_output}/missing-backups"

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
grep -F -- "compose --env-file ${test_output}/stack.env --file ${test_output}/compose.yml ps --format" \
    "${test_output}/docker.log" >/dev/null

#
# Confirm the status helper returns the expected Compose output.
#
grep -F "plundarr-prowlarr-latest" "${test_output}/ps.out" >/dev/null
grep -F "plundarr-gluetun-latest" "${test_output}/ps.out" >/dev/null

#
# Collapse duplicate wildcard bindings and stack each distinct published port.
#
test "$(grep -c 'plundarr-gluetun-latest' "${test_output}/ps.out")" -eq 1
grep -E '^[[:space:]]+8080->8080/tcp$' \
    "${test_output}/ps.out" >/dev/null
grep -E '^[[:space:]]+6881->6881/udp$' \
    "${test_output}/ps.out" >/dev/null
grep -F "6881->6881/tcp" "${test_output}/ps.out" >/dev/null
grep -F "9696->9696/tcp" \
    "${test_output}/ps.out" >/dev/null
if grep -F '[::]' "${test_output}/ps.out" >/dev/null; then
    echo "Compose status helper retained a duplicate IPv6 wildcard binding." >&2
    exit 1
fi

#
# Report success.
#
echo "Make helper tests passed."
