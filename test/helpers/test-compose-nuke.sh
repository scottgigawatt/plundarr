#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# SPDX-License-Identifier: Apache-2.0
#
# test-compose-nuke.sh: Validate project-scoped destructive cleanup without
#                       contacting the developer's Docker daemon.
#
# Usage: test/helpers/test-compose-nuke.sh
#

#
# Directory for isolated nuke-helper fixtures.
#
test_output=""

#
# Fail on errors and unset variables.
#
set -eu

#
# cleanup: Remove the isolated nuke-helper test directory.
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
# Create isolated project fixtures and register cleanup on exit.
#
test_output=$(mktemp -d)
trap cleanup 0 1 2 15
stub_path="$(pwd)/test/stubs/docker-nuke-stub.sh"
: >"${test_output}/compose-file.yml"
: >"${test_output}/project.env"
printf '%s\n' 'FROM test/shared-base:1' >"${test_output}/Dockerfile.test"
mkdir -p "${test_output}/config" "${test_output}/backups"
printf '%s\n' 'preserve me' >"${test_output}/project.env.preserved"
printf '%s\n' 'preserve me' >"${test_output}/config/state.db"
printf '%s\n' 'preserve me' >"${test_output}/backups/config.tar.gz"

#
# Reject incomplete arguments before invoking Docker.
#
: >"${test_output}/missing.log"
if NUKE_STUB_LOG="${test_output}/missing.log" \
    sh scripts/compose/nuke.sh --docker-bin "${stub_path}" \
        >"${test_output}/missing.out" 2>&1; then
    echo "Compose nuke helper accepted incomplete arguments." >&2
    exit 1
fi
grep -F -- '--compose-file is required.' "${test_output}/missing.out" >/dev/null
test ! -s "${test_output}/missing.log"

#
# Remove one isolated project while retaining shared base images and host files.
#
: >"${test_output}/nuke.log"
NUKE_STUB_LOG="${test_output}/nuke.log" \
    sh scripts/compose/nuke.sh \
        --docker-bin "${stub_path}" \
        --compose-mode plugin \
        --compose-file "${test_output}/compose-file.yml" \
        --env-file "${test_output}/project.env" \
        --project-name test-project \
        --down-timeout 45 \
        --dockerfile "${test_output}/Dockerfile.test" \
        --base-image-awk scripts/awk/collect-dockerfile-base-images.awk \
        --builder-name test-builder \
        --additional-image test/additional:local \
        >"${test_output}/nuke.out" 2>&1

grep -F "compose --project-name test-project --env-file ${test_output}/project.env --file ${test_output}/compose-file.yml config --quiet" \
    "${test_output}/nuke.log" >/dev/null
grep -F "compose --project-name test-project --env-file ${test_output}/project.env --file ${test_output}/compose-file.yml config --images" \
    "${test_output}/nuke.log" >/dev/null
grep -F "compose --project-name test-project --env-file ${test_output}/project.env --file ${test_output}/compose-file.yml down --timeout 45 --remove-orphans --rmi all" \
    "${test_output}/nuke.log" >/dev/null
grep -F 'image rm test/service:local' "${test_output}/nuke.log" >/dev/null
grep -F 'image rm test/additional:local' "${test_output}/nuke.log" >/dev/null
grep -F 'image rm test/shared-base:1' "${test_output}/nuke.log" >/dev/null
grep -F "Retaining shared or in-use base image: test/shared-base:1" \
    "${test_output}/nuke.out" >/dev/null
grep -F 'buildx rm --force test-builder' "${test_output}/nuke.log" >/dev/null

test "$(grep -c 'image rm test/service:local' "${test_output}/nuke.log")" -eq 1
if grep -E -- '--volumes|(^| )-v( |$)|volume rm|system prune|image prune|volume prune|builder prune|--all-inactive|buildx rm --force unrelated-builder' \
    "${test_output}/nuke.log" >/dev/null; then
    echo "Compose nuke helper invoked a global or unrelated cleanup command." >&2
    exit 1
fi

test -f "${test_output}/project.env"
test -f "${test_output}/project.env.preserved"
test -f "${test_output}/config/state.db"
test -f "${test_output}/backups/config.tar.gz"

#
# Stop after an unexpected Compose failure without removing images or builders.
#
: >"${test_output}/failure.log"
if NUKE_STUB_LOG="${test_output}/failure.log" NUKE_STUB_FAIL_COMPOSE=down \
    sh scripts/compose/nuke.sh \
        --docker-bin "${stub_path}" \
        --compose-mode plugin \
        --compose-file "${test_output}/compose-file.yml" \
        --env-file "${test_output}/project.env" \
        --project-name test-project \
        --down-timeout 45 \
        --builder-name test-builder \
        >"${test_output}/failure.out" 2>&1; then
    echo "Compose nuke helper hid an unexpected teardown failure." >&2
    exit 1
fi
grep -F 'Docker Compose could not remove test-project.' \
    "${test_output}/failure.out" >/dev/null
if grep -E 'image rm|buildx rm' "${test_output}/failure.log" >/dev/null; then
    echo "Compose nuke helper continued after a teardown failure." >&2
    exit 1
fi

#
# Exercise the complete Make recipe so post-helper commands cannot reset real state.
#
repository_root=$(pwd)
fixture="${test_output}/make-fixture"
expected="${test_output}/expected"
mkdir -p "${fixture}/config/gluetun/wireguard" "${fixture}/config/privateerr/logs" \
    "${fixture}/config/application" "${fixture}/backups" "${expected}"
cp Makefile "${fixture}/Makefile"
cp "${test_output}/Dockerfile.test" "${fixture}/Dockerfile"
printf '%s\n' 'public fixture settings' >"${fixture}/.env"
printf '%s\n' 'services: {}' >"${fixture}/docker-compose.yml"
printf '%s\n' 'services: {}' >"${fixture}/maraudarr.yml"
printf '%s\n' 'public generator settings' >"${fixture}/maraudarr.env"

# Protect saved VPN files, connection state, logs, and application databases.
for state_file in gluetun/wireguard/wg0.conf gluetun/wireguard/privateerr.env \
    gluetun/forwarded_port gluetun/ip gluetun/piaportforward.json gluetun/servers \
    privateerr/logs/startup.log application/state.db; do
    printf '%s\n' "preserved fixture: ${state_file}" >"${fixture}/config/${state_file}"
done
printf '%s\n' 'preserved backup fixture' >"${fixture}/backups/config.tar.gz"
cp -R "${fixture}/config" "${expected}/config"
cp -R "${fixture}/backups" "${expected}/backups"
cp "${fixture}/.env" "${expected}/.env"
cp "${fixture}/docker-compose.yml" "${expected}/docker-compose.yml"

# Keep every command and cleanup path inside the disposable fixture.
NUKE_STUB_LOG="${test_output}/make-nuke.log" NO_COLOR=1 \
    make --no-print-directory --directory "${fixture}" nuke \
        DOCKER_BIN="${stub_path}" \
        DOCKER_COMPOSE="${stub_path} compose" \
        DEPENDENCIES=true \
        COMPOSE_NUKE_CMD="${repository_root}/scripts/compose/nuke.sh" \
        COMPOSE_FILE="${fixture}/docker-compose.yml" \
        ENV_FILE="${fixture}/.env" \
        COMPOSE_ENV_FILE="${fixture}/.env" \
        CONFIG_PATH="${fixture}/config" \
        MARAUDARR_COMPOSE_FILE="${fixture}/maraudarr.yml" \
        MARAUDARR_ENV_FILE="${fixture}/maraudarr.env" \
        DOCKERFILES="${fixture}/Dockerfile" \
        DOCKERFILE_BASE_IMAGES_AWK="${repository_root}/scripts/awk/collect-dockerfile-base-images.awk" \
        BUILDX_BUILDER_NAME=test-builder \
        MARAUDARR_IMAGE=test/additional:local \
        MARAUDARR_MULTIARCH_IMAGE=test/absent:latest \
        >"${test_output}/make-nuke.out" 2>&1

diff -r "${expected}/config" "${fixture}/config"
diff -r "${expected}/backups" "${fixture}/backups"
cmp "${expected}/.env" "${fixture}/.env"
cmp "${expected}/docker-compose.yml" "${fixture}/docker-compose.yml"
test "$(grep -c ' down --timeout ' "${test_output}/make-nuke.log")" -eq 2
if grep -E -- '--volumes|volume rm|system prune|image prune|volume prune|builder prune' \
    "${test_output}/make-nuke.log" >/dev/null; then
    echo "The Make nuke recipe crossed a protected Docker cleanup boundary." >&2
    exit 1
fi

echo "Compose nuke helper tests passed."
