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
grep -F "This deployment cannot start without valid PIA credentials." \
    "${test_output}/missing.out" >/dev/null
grep -F "Credential  PIA_USER" \
    "${test_output}/missing.out" >/dev/null
grep -F "Problem     Missing or still using a known example value." \
    "${test_output}/missing.out" >/dev/null
grep -F "Fix         Set PIA_USER in the active deployment's .env file, then rerun the requested Make target." \
    "${test_output}/missing.out" >/dev/null

#
# Keep redirected diagnostic output free from terminal escape sequences.
#
if LC_ALL=C grep "$(printf '\033')" "${test_output}/missing.out" >/dev/null; then
    echo "Credential helper emitted terminal colors into redirected output." >&2
    exit 1
fi

#
# Reject both known example password values.
#
for example_password in abc123 shiverMeTimbers123; do
    if printf '%s\n' 'PIA_USER=p7654321' "PIA_PASS=${example_password}" \
        | scripts/compose/check-pia-credentials.sh \
            >"${test_output}/placeholder-${example_password}.out" 2>&1; then
        echo "Credential helper accepted a known example PIA password." >&2
        exit 1
    fi

    grep -F "Credential  PIA_PASS" \
        "${test_output}/placeholder-${example_password}.out" >/dev/null
done

#
# Confirm the status helper delegates project selection to Docker Compose.
#
: >"${test_output}/compose.yml"
: >"${test_output}/stack.env"
COMPOSE_TEST_LOG="${test_output}/docker.log" \
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
grep -F "test-idle-latest" "${test_output}/ps.out" >/dev/null
grep -F "test-gluetun-latest" "${test_output}/ps.out" >/dev/null
grep -F "test-service-latest" "${test_output}/ps.out" >/dev/null

#
# Collapse duplicate wildcard bindings and stack each distinct published port.
#
test "$(grep -c 'test-gluetun-latest' "${test_output}/ps.out")" -eq 1
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
# Keep clean repository-only and protect every generated deployment.
#
NO_COLOR=1 make --dry-run clean >"${test_output}/clean.out"
grep -F 'rm -rf .venv-docs site .ruff_cache .pytest_cache test/logs' \
    "${test_output}/clean.out" >/dev/null
grep -F -- "-path './dist'" "${test_output}/clean.out" >/dev/null
if grep -E '(^|[[:space:]])docker([[:space:]]|$)|rm -rf .*dist|rm -rf .*\.env|delete-config' \
    "${test_output}/clean.out" >/dev/null; then
    echo "The clean target includes deployment or Docker state." >&2
    exit 1
fi

#
# Keep ordinary down volume- and image-preserving.
#
NO_COLOR=1 make --dry-run down \
    DOCKER_COMPOSE=true \
    ENV_FILE="${test_output}/stack.env" \
    COMPOSE_ENV_FILE="${test_output}/stack.env" \
    COMPOSE_FILE="${test_output}/compose.yml" \
    >"${test_output}/down.out"
grep -F 'down --timeout 30 --remove-orphans' "${test_output}/down.out" >/dev/null
if grep -E 'down .*--volumes|down .*--rmi' "${test_output}/down.out" >/dev/null; then
    echo "The down target includes destructive volume or image options." >&2
    exit 1
fi

#
# Keep the standalone Watchtower pass one-shot and disposable.
#
NO_COLOR=1 make --dry-run watchtower-run-once \
    DOCKER_COMPOSE=true \
    DEPENDENCIES=true \
    ENV_FILE="${test_output}/stack.env" \
    COMPOSE_ENV_FILE="${test_output}/stack.env" \
    COMPOSE_FILE="${test_output}/compose.yml" \
    SELECTED_COMPOSE_SERVICES=watchtower \
    >"${test_output}/watchtower-run-once.out"
grep -F 'ps --quiet "watchtower"' \
    "${test_output}/watchtower-run-once.out" >/dev/null
grep -F 'pull "watchtower"' \
    "${test_output}/watchtower-run-once.out" >/dev/null
grep -F 'run --rm --no-deps "watchtower" --run-once' \
    "${test_output}/watchtower-run-once.out" >/dev/null

#
# Reject one-shot execution when the selected chart omits Watchtower.
#
if NO_COLOR=1 make --no-print-directory watchtower-run-once \
    DOCKER_COMPOSE=true \
    DEPENDENCIES=true \
    ENV_FILE="${test_output}/stack.env" \
    COMPOSE_ENV_FILE="${test_output}/stack.env" \
    COMPOSE_FILE="${test_output}/compose.yml" \
    SELECTED_COMPOSE_SERVICES=homepage \
    >"${test_output}/watchtower-missing.out" 2>&1; then
    echo "The one-shot target accepted a deployment without Watchtower." >&2
    exit 1
fi
grep -F 'The selected deployment does not include watchtower.' \
    "${test_output}/watchtower-missing.out" >/dev/null

#
# Keep Kometa Overlay Reset profile-gated, one-shot, and disposable.
#
NO_COLOR=1 make --dry-run overlay-reset-run-once \
    DOCKER_COMPOSE=true \
    DEPENDENCIES=true \
    ENV_FILE="${test_output}/stack.env" \
    COMPOSE_ENV_FILE="${test_output}/stack.env" \
    COMPOSE_FILE="${test_output}/compose.yml" \
    PROFILED_COMPOSE_SERVICES=overlay-reset \
    >"${test_output}/overlay-reset-run-once.out"
grep -F 'ps --quiet "overlay-reset"' \
    "${test_output}/overlay-reset-run-once.out" >/dev/null
grep -F 'pull "overlay-reset"' \
    "${test_output}/overlay-reset-run-once.out" >/dev/null
grep -F 'run --rm --no-deps "overlay-reset"' \
    "${test_output}/overlay-reset-run-once.out" >/dev/null

#
# Reject one-shot execution when the selected chart omits Overlay Reset.
#
if NO_COLOR=1 make --no-print-directory overlay-reset-run-once \
    DOCKER_COMPOSE=true \
    DEPENDENCIES=true \
    ENV_FILE="${test_output}/stack.env" \
    COMPOSE_ENV_FILE="${test_output}/stack.env" \
    COMPOSE_FILE="${test_output}/compose.yml" \
    PROFILED_COMPOSE_SERVICES=homepage \
    >"${test_output}/overlay-reset-missing.out" 2>&1; then
    echo "The one-shot target accepted a deployment without Overlay Reset." >&2
    exit 1
fi
grep -F 'The selected deployment does not include overlay-reset.' \
    "${test_output}/overlay-reset-missing.out" >/dev/null

#
# Keep Plundarr and Maraudarr cleanup separate without deleting application config.
#
NO_COLOR=1 make --dry-run nuke \
    DOCKER_COMPOSE=true \
    ENV_FILE="${test_output}/stack.env" \
    COMPOSE_ENV_FILE="${test_output}/stack.env" \
    COMPOSE_FILE="${test_output}/compose.yml" \
    >"${test_output}/nuke.out"
test "$(grep -c '^scripts/compose/nuke.sh' "${test_output}/nuke.out")" -eq 2
grep -F -- '--project-name "maraudarr"' "${test_output}/nuke.out" >/dev/null
grep -F -- '--builder-name "plundarr-local"' "${test_output}/nuke.out" >/dev/null
test "$(grep -c 'make --no-print-directory clean' "${test_output}/nuke.out")" -eq 1
test "$(grep -c 'make --no-print-directory restore-test-config' "${test_output}/nuke.out")" -eq 1
if grep -E 'delete-config|rm -rf .*\.env|rm -rf .*backups|docker (system|image|volume|builder) prune|--all-inactive' \
    "${test_output}/nuke.out" >/dev/null; then
    echo "The nuke target crossed a protected cleanup boundary." >&2
    exit 1
fi

#
# Give Maraudarr an explicit Compose identity and repository-owned builder.
#
NO_COLOR=1 make --dry-run build \
    DOCKER_COMPOSE=true \
    DOCKER_BUILDX=true \
    >"${test_output}/build.out"
grep -F 'BUILDX_BUILDER="plundarr-local" true --project-name "maraudarr"' \
    "${test_output}/build.out" >/dev/null

#
# Keep target groups and framed dependency comments reviewable.
#
common_targets=$(awk '
    /^COMMON_TARGETS=/ { active = 1 }
    active && match($0, /\$\([A-Z0-9_]+\)/) {
        if (targets != "") {
            targets = targets " "
        }
        targets = targets substr($0, RSTART + 2, RLENGTH - 3)
    }
    active && $0 !~ /\\$/ {
        print targets
        exit
    }
' Makefile)
test "${common_targets}" = "BUILD_DEPENDS CHECK_ENV CHECK_PIA ENSURE_BUILDX_BUILDER ALL UP WATCHTOWER_RUN_ONCE OVERLAY_RESET_RUN_ONCE DOWN PS LOGS CONFIG ENV PRINT_CONFIG PRINT_ENV BUILD BUILD_PLATFORMS TEST TEST_MAKE_HELPERS TEST_WORKFLOWS TEST_E2E BACKUP RESTORE_TEST_CONFIG CLEAN_TEST CLEAN NUKE HELP"
common_recipe_order=$(awk '
    /^\$\([A-Z0-9_]+\)(:| )/ {
        target = $0
        sub(/^\$\(/, "", target)
        sub(/\).*/, "", target)
        if (targets != "") {
            targets = targets " "
        }
        targets = targets target
        if (++count == 27) {
            print targets
            exit
        }
    }
' Makefile)
test "${common_recipe_order}" = "${common_targets}"
project_targets=$(awk '
    /^PROJECT_TARGETS=/ { active = 1 }
    active && match($0, /\$\([A-Z0-9_]+\)/) {
        if (targets != "") {
            targets = targets " "
        }
        targets = targets substr($0, RSTART + 2, RLENGTH - 3)
    }
    active && $0 !~ /\\$/ {
        print targets
        exit
    }
' Makefile)
project_recipe_order=$(awk -v project_targets=" ${project_targets} " '
    /^\$\([A-Z0-9_]+\)(:| )/ {
        target = $0
        sub(/^\$\(/, "", target)
        sub(/\).*/, "", target)
        if (index(project_targets, " " target " ") == 0) {
            next
        }
        if (targets != "") {
            targets = targets " "
        }
        targets = targets target
    }
    END { print targets }
' Makefile)
test "${project_recipe_order}" = "${project_targets}"
grep -F ".DEFAULT_GOAL := \$(ALL)" Makefile >/dev/null
for target_group in COMMON_TARGETS PROJECT_TARGETS INTERNAL_TARGETS; do
    grep -F "${target_group}=" Makefile >/dev/null
done

missing_dependency_comments=$(awk '
    /^# \$\(/ { target = $0; dependencies = 0; active = 1; next }
    active && /^# Dependencies/ { dependencies = 1 }
    active && /^\$\(/ {
        if (!dependencies) {
            print target
        }
        active = 0
    }
' Makefile)
test -z "${missing_dependency_comments}"

#
# Report success.
#
echo "Make helper tests passed."
