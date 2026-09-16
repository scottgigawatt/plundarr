#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test-compose-cleanup-live.sh: Verify down and nuke against isolated Docker
#                               resources while unrelated sentinels survive.
#
# Purpose: Exercise the cleanup contract on a real Docker daemon without using
#          a repository deployment, generated credentials, or persistent state.
#
# Usage: test/runtime/test-compose-cleanup-live.sh
#

#
# Fail on errors and unset variables.
#
set -eu

#
# Resolve repository and disposable fixture paths.
#
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_ROOT=$(CDPATH='' cd -- "${SCRIPT_DIR}/../.." && pwd)
NUKE_HELPER="${REPOSITORY_ROOT}/scripts/compose/nuke.sh"
TEMPORARY_DIRECTORY=$(mktemp -d "${TMPDIR:-/tmp}/compose-cleanup-live.XXXXXX")
FIXTURE_DIRECTORY="${TEMPORARY_DIRECTORY}/fixture"
PROTECTED_DIRECTORY="${TEMPORARY_DIRECTORY}/protected"
COMPOSE_FILE="${FIXTURE_DIRECTORY}/docker-compose.yml"
DOCKERFILE="${FIXTURE_DIRECTORY}/Dockerfile"
ENV_FILE="${FIXTURE_DIRECTORY}/fixture.env"
PROJECT_NAME="plundarr-test-$(od -An -N12 -tx1 /dev/urandom | tr -d ' \n')"
SENTINEL_PROJECT="${PROJECT_NAME}-sentinel"
VOLUME_CLEANUP="${REPOSITORY_ROOT}/test/runtime/remove-test-volume.sh"
VOLUME_LEDGER="${TEMPORARY_DIRECTORY}/created-volumes"
: >"${VOLUME_LEDGER}"
BUILDER_NAME="${PROJECT_NAME}-builder"
SENTINEL_BUILDER_NAME="${PROJECT_NAME}-sentinel-builder"
SERVICE_IMAGE="${PROJECT_NAME}-service:local"
SENTINEL_IMAGE="${PROJECT_NAME}-sentinel:local"
SENTINEL_CONTAINER="${PROJECT_NAME}-sentinel"
SENTINEL_NETWORK="${PROJECT_NAME}-sentinel"
SENTINEL_VOLUME="${SENTINEL_PROJECT}_data"
PROJECT_VOLUME="${PROJECT_NAME}_fixture-data"
SCRATCH_VOLUME="${PROJECT_NAME}_scratch-data"
SELECTED_BUILDER_BEFORE=""

#
# cleanup: Remove this run's resources and only its recorded, verified test volumes.
#
# Parameters: None.
#
# Returns: Preserves test failures and reports failed cleanup as an error.
#
cleanup() {
    cleanup_status=$?
    trap - 0
    docker compose \
        --project-name "${PROJECT_NAME}" \
        --env-file "${ENV_FILE}" \
        --file "${COMPOSE_FILE}" \
        down --timeout 5 --remove-orphans --rmi all \
        >/dev/null 2>&1 || cleanup_status=1
    docker container rm --force "${SENTINEL_CONTAINER}" >/dev/null 2>&1 || true
    docker network rm "${SENTINEL_NETWORK}" >/dev/null 2>&1 || true
    while read -r owner volume; do
        "${VOLUME_CLEANUP}" "${owner}" "${volume}" || cleanup_status=1
    done <"${VOLUME_LEDGER}"
    docker image rm "${SERVICE_IMAGE}" >/dev/null 2>&1 || true
    docker image rm "${SENTINEL_IMAGE}" >/dev/null 2>&1 || true
    docker buildx rm --force "${BUILDER_NAME}" >/dev/null 2>&1 || true
    docker buildx rm --force "${SENTINEL_BUILDER_NAME}" >/dev/null 2>&1 || true
    if [ "${cleanup_status}" -eq 0 ]; then
        rm -rf "${TEMPORARY_DIRECTORY}"
    else
        echo "Test failed or cleanup was incomplete; resource ledger retained at ${VOLUME_LEDGER}." >&2
    fi
    exit "${cleanup_status}"
}

#
# create_test_volume: Create and record a previously absent, labeled test volume.
#
# Parameters: $1 - Exact test project name.
#             $2 - Logical Compose volume key.
#
# Returns: Fails if the name already exists or Docker cannot create the volume.
#
create_test_volume() {
    owner=$1
    key=$2
    volume="${owner}_${key}"
    existing_volumes=$(docker volume ls --format '{{.Name}}')
    if printf '%s\n' "${existing_volumes}" | grep -F -x "${volume}" >/dev/null; then
        fail "Refusing to reuse an existing volume: ${volume}"
    fi
    docker volume create \
        --label "com.docker.compose.project=${owner}" \
        --label "com.docker.compose.volume=${key}" \
        --label "io.plundarr.test-run=${owner}" \
        "${volume}" >/dev/null
    printf '%s %s\n' "${owner}" "${volume}" >>"${VOLUME_LEDGER}"
}

#
# fail: Print a diagnostic and stop the live acceptance test.
#
# Parameters: $1 - Diagnostic message.
#
# Returns: Exits with a failure status.
#
fail() {
    echo "ERROR: $1" >&2
    exit 1
}

#
# assert_present: Require a resource inspection command to succeed.
#
# Parameters: $1 - Resource description.
#             $@ - Inspection command and arguments.
#
# Returns: Exits when the resource is absent.
#
assert_present() {
    description=$1
    shift
    "$@" >/dev/null 2>&1 || fail "Expected ${description} to remain."
}

#
# assert_absent: Require a resource inspection command to fail.
#
# Parameters: $1 - Resource description.
#             $@ - Inspection command and arguments.
#
# Returns: Exits when the resource is present.
#
assert_absent() {
    description=$1
    shift
    if "$@" >/dev/null 2>&1; then
        fail "Expected ${description} to be removed."
    fi
}

#
# selected_builder: Print the globally selected Buildx builder, if any.
#
# Parameters: None.
#
# Returns: Prints the selected builder name or an empty line.
#
selected_builder() {
    docker buildx ls | awk '
        $1 ~ /\*$/ {
            sub(/\*$/, "", $1)
            print $1
            exit
        }
    '
}

#
# builder_exists: Check whether one exact Buildx builder exists.
#
# Parameters: $1 - Builder name.
#
# Returns: Success when the builder exists, otherwise failure.
#
builder_exists() {
    docker buildx ls --format '{{.Name}}' | grep -F -x "$1" >/dev/null
}

#
# project_container: Print the fixture service container ID.
#
# Parameters: None.
#
# Returns: Prints the container ID or an empty line.
#
project_container() {
    docker compose \
        --project-name "${PROJECT_NAME}" \
        --env-file "${ENV_FILE}" \
        --file "${COMPOSE_FILE}" \
        ps --all --quiet fixture
}

#
# Create files that are isolated from both repositories and contain no secrets.
#
mkdir -p "${FIXTURE_DIRECTORY}" "${PROTECTED_DIRECTORY}"
cat >"${DOCKERFILE}" <<'EOF'
FROM busybox:1.37

CMD ["sh", "-c", "sleep 600"]
EOF
cat >"${COMPOSE_FILE}" <<'EOF'
services:
  fixture:
    build:
      context: .
    image: ${SERVICE_IMAGE}
    command: ["sh", "-c", "sleep 600"]
    volumes:
      - fixture-data:/data
      - scratch-data:/scratch
      - ${PROTECTED_DIRECTORY}:/protected:ro

volumes:
  fixture-data:
  scratch-data:
EOF
cat >"${ENV_FILE}" <<EOF
SERVICE_IMAGE=${SERVICE_IMAGE}
PROTECTED_DIRECTORY=${PROTECTED_DIRECTORY}
EOF
printf '%s\n' 'protected fixture state' >"${PROTECTED_DIRECTORY}/marker.txt"
PROTECTED_CHECKSUM=$(cksum "${PROTECTED_DIRECTORY}/marker.txt")
ENV_CHECKSUM=$(cksum "${ENV_FILE}")

trap cleanup 0
trap 'exit 130' 1 2 15

#
# Create unrelated resources and builders with exact disposable names.
#
SELECTED_BUILDER_BEFORE=$(selected_builder)
docker pull busybox:1.37 >/dev/null
docker image tag busybox:1.37 "${SENTINEL_IMAGE}"
docker network create "${SENTINEL_NETWORK}" >/dev/null
create_test_volume "${SENTINEL_PROJECT}" data
create_test_volume "${PROJECT_NAME}" fixture-data
create_test_volume "${PROJECT_NAME}" scratch-data
docker container run \
    --detach \
    --name "${SENTINEL_CONTAINER}" \
    --network "${SENTINEL_NETWORK}" \
    --mount "source=${SENTINEL_VOLUME},target=/sentinel" \
    "${SENTINEL_IMAGE}" sh -c 'sleep 600' >/dev/null
docker buildx create \
    --name "${BUILDER_NAME}" \
    --driver docker-container >/dev/null
docker buildx create \
    --name "${SENTINEL_BUILDER_NAME}" \
    --driver docker-container >/dev/null

#
# Ordinary down removes containers and networks but preserves both named
# volumes, the local image, protected files, and unrelated Docker resources.
#
BUILDX_BUILDER="${BUILDER_NAME}" docker compose \
    --project-name "${PROJECT_NAME}" \
    --env-file "${ENV_FILE}" \
    --file "${COMPOSE_FILE}" \
    up --detach --build
CONTAINER_ID=$(project_container)
[ -n "${CONTAINER_ID}" ] || fail "Compose did not create the fixture container."
docker exec "${CONTAINER_ID}" sh -c 'printf "%s\n" "database marker" > /data/marker; printf "%s\n" "scratch marker" > /scratch/marker'

docker compose \
    --project-name "${PROJECT_NAME}" \
    --env-file "${ENV_FILE}" \
    --file "${COMPOSE_FILE}" \
    down --timeout 5 --remove-orphans

[ -z "$(project_container)" ] || fail "Ordinary down retained the fixture container."
assert_absent "project network after down" docker network inspect "${PROJECT_NAME}_default"
assert_present "named volume after down" docker volume inspect "${PROJECT_VOLUME}"
assert_present "scratch volume after down" docker volume inspect "${SCRATCH_VOLUME}"
assert_present "service image after down" docker image inspect "${SERVICE_IMAGE}"
[ "$(cksum "${PROTECTED_DIRECTORY}/marker.txt")" = "${PROTECTED_CHECKSUM}" ] \
    || fail "Ordinary down changed protected bind-mounted state."

#
# Recreate the isolated project with the same volumes, then exercise nuke.
#
BUILDX_BUILDER="${BUILDER_NAME}" docker compose \
    --project-name "${PROJECT_NAME}" \
    --env-file "${ENV_FILE}" \
    --file "${COMPOSE_FILE}" \
    up --detach --build
CONTAINER_ID=$(project_container)
[ -n "${CONTAINER_ID}" ] || fail "Compose did not recreate the fixture container."
[ "$(docker exec "${CONTAINER_ID}" cat /data/marker)" = "database marker" ] \
    || fail "Ordinary down changed the stored data."

"${NUKE_HELPER}" \
    --docker-bin docker \
    --compose-file "${COMPOSE_FILE}" \
    --env-file "${ENV_FILE}" \
    --project-name "${PROJECT_NAME}" \
    --down-timeout 5 \
    --builder-name "${BUILDER_NAME}"

[ -z "$(project_container)" ] || fail "Nuke retained the fixture container."
assert_absent "project network after nuke" docker network inspect "${PROJECT_NAME}_default"
assert_present "named volume after nuke" docker volume inspect "${PROJECT_VOLUME}"
assert_present "scratch volume after nuke" docker volume inspect "${SCRATCH_VOLUME}"
assert_absent "service image after nuke" docker image inspect "${SERVICE_IMAGE}"
if builder_exists "${BUILDER_NAME}"; then
    fail "Nuke retained the configured project builder."
fi

assert_present "sentinel container" docker container inspect "${SENTINEL_CONTAINER}"
assert_present "sentinel network" docker network inspect "${SENTINEL_NETWORK}"
assert_present "sentinel volume" docker volume inspect "${SENTINEL_VOLUME}"
assert_present "sentinel image" docker image inspect "${SENTINEL_IMAGE}"
builder_exists "${SENTINEL_BUILDER_NAME}" \
    || fail "Nuke removed the unrelated sentinel builder."
[ "$(selected_builder)" = "${SELECTED_BUILDER_BEFORE}" ] \
    || fail "Nuke changed the globally selected Buildx builder."
[ "$(cksum "${PROTECTED_DIRECTORY}/marker.txt")" = "${PROTECTED_CHECKSUM}" ] \
    || fail "Nuke changed protected bind-mounted state."
[ "$(cksum "${ENV_FILE}")" = "${ENV_CHECKSUM}" ] \
    || fail "Nuke changed the environment file."

#
# A second run must treat already-absent project resources as success.
#
"${NUKE_HELPER}" \
    --docker-bin docker \
    --compose-file "${COMPOSE_FILE}" \
    --env-file "${ENV_FILE}" \
    --project-name "${PROJECT_NAME}" \
    --down-timeout 5 \
    --builder-name "${BUILDER_NAME}"

#
# Restart against the preserved volumes and verify their contents before test cleanup.
#
docker image tag busybox:1.37 "${SERVICE_IMAGE}"
docker compose \
    --project-name "${PROJECT_NAME}" \
    --env-file "${ENV_FILE}" \
    --file "${COMPOSE_FILE}" \
    up --detach --no-build
CONTAINER_ID=$(project_container)
[ "$(docker exec "${CONTAINER_ID}" cat /data/marker)" = "database marker" ] \
    || fail "Nuke changed the stored database marker."
[ "$(docker exec "${CONTAINER_ID}" cat /scratch/marker)" = "scratch marker" ] \
    || fail "Nuke changed the stored scratch marker."

echo "Live Compose cleanup acceptance passed; removing verified test-owned resources."
