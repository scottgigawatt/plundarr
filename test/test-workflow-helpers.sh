#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test-workflow-helpers.sh: Validate Discord payload generation and registry
#                           mirroring without messages or registry writes.
#
# Usage: test/test-workflow-helpers.sh
#

#
# Fail on errors and unset variables.
#
set -eu

REPOSITORY_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TEST_ROOT=$(mktemp -d)
SKOPEO_LOG="${TEST_ROOT}/skopeo.log"

#
# cleanup: Remove all temporary helper-test state.
#
# Parameters: None.
#
# Returns:     Always returns 0 so cleanup cannot hide the original result.
#
cleanup() {
    rm -rf "${TEST_ROOT}"
}
trap cleanup EXIT HUP INT TERM

#
# assert_json_value: Require a JSON expression to evaluate successfully.
#
# Parameters: $1 - JSON document path.
#             $2 - jq assertion expression.
#
# Returns:     0 when the expression succeeds; otherwise returns nonzero.
#
assert_json_value() {
    jq -e "$2" "$1" >/dev/null
}

#
# Render deterministic start and verdict payloads through long and short flags.
#
sh "${REPOSITORY_ROOT}/.github/scripts/notify-discord.sh" \
    --event start \
    --template shipyard \
    --run-url https://example.invalid/run \
    --repository test/plundarr \
    --ref-name test-ref \
    --workflow-name test-build \
    --actor test-captain \
    --platforms linux/amd64 \
    --ghcr-image ghcr.io/test/maraudarr \
    --dockerhub-image docker.io/test/maraudarr \
    --random-value 2 \
    --dry-run \
    > "${TEST_ROOT}/build-start.json"

assert_json_value "${TEST_ROOT}/build-start.json" \
    '.username == "Maraudarr Deck Crew" and .embeds[0].color == 3447003'

sh "${REPOSITORY_ROOT}/.github/scripts/notify-discord.sh" \
    -e verdict \
    -t kraken \
    -u https://example.invalid/run \
    -r test/plundarr \
    -f test-ref \
    -s failure \
    -g ghcr.io/test/maraudarr \
    -c https://example.invalid/ghcr \
    -b https://example.invalid/dockerhub \
    -l ghcr.io/test/maraudarr:test \
    -i sha256:0123456789abcdef \
    -n 4 \
    -x \
    > "${TEST_ROOT}/build-verdict.json"

assert_json_value "${TEST_ROOT}/build-verdict.json" \
    '.username == "Kraken Build Bureau" and .embeds[0].color == 15158332'

#
# Render deterministic success and failure documentation verdicts.
#
sh "${REPOSITORY_ROOT}/.github/scripts/notify-docs-discord.sh" \
    --build-status success \
    --deploy-status success \
    --run-url https://example.invalid/run \
    --site-url https://example.invalid/docs \
    --repository test/plundarr \
    --ref-name test-ref \
    --random-value 1 \
    --dry-run \
    > "${TEST_ROOT}/docs-success.json"

assert_json_value "${TEST_ROOT}/docs-success.json" \
    '.username == "Plundarr Chart Room" and .embeds[0].color == 3066993'

sh "${REPOSITORY_ROOT}/.github/scripts/notify-docs-discord.sh" \
    -b failure \
    -d skipped \
    -u https://example.invalid/run \
    -r test/plundarr \
    -f test-ref \
    -n 3 \
    -x \
    > "${TEST_ROOT}/docs-failure.json"

assert_json_value "${TEST_ROOT}/docs-failure.json" \
    '.embeds[0].color == 15158332
        and .embeds[0].fields[3].value == "skipped"
        and .embeds[0].fields[4].value == "unavailable"'

#
# Replace Skopeo with a deterministic recorder for copy and digest operations.
#
mkdir -p "${TEST_ROOT}/bin"
sed "s|@SKOPEO_LOG@|${SKOPEO_LOG}|g" \
    "${REPOSITORY_ROOT}/test/workflow-skopeo-stub.sh" \
    > "${TEST_ROOT}/bin/skopeo"
chmod +x "${TEST_ROOT}/bin/skopeo"

#
# run_registry_helper: Invoke the registry helper with safe test credentials.
#
# Parameters: $@ - Registry-helper flags.
#
# Returns:     The registry helper's exit status.
#
run_registry_helper() {
    GHCR_TOKEN=test-token \
    DOCKERHUB_TOKEN=test-token \
        sh "${REPOSITORY_ROOT}/.github/scripts/registry-mirror.sh" \
        --ghcr-image ghcr.io/test/maraudarr \
        --dockerhub-image docker.io/test/maraudarr \
        --ghcr-username test-user \
        --dockerhub-username test-user \
        --published-tags "ghcr.io/test/maraudarr:edge
ghcr.io/test/maraudarr:sha-test" \
        --skopeo-bin "${TEST_ROOT}/bin/skopeo" \
        "$@"
}

run_registry_helper --mirror
run_registry_helper -v

grep -F -- 'copy --all --preserve-digests' "${SKOPEO_LOG}" >/dev/null
grep -F -- 'docker://docker.io/test/maraudarr:sha-test' "${SKOPEO_LOG}" >/dev/null
grep -F -- 'inspect --creds' "${SKOPEO_LOG}" >/dev/null

echo "Workflow helper tests passed."
