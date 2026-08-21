#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# maraudarr-image-smoke.sh: Test the Maraudarr terminal UI, then generate and
#                           validate one deployment with CI's runtime controls.
#
# Usage: test/generator/maraudarr-image-smoke.sh --image <image> --preset <preset> \
#           --required-file <path> [options]
#

#
# Runtime command, repository, selection, and disposable output settings.
#
add_services=""
deployment_root="dist"
docker_bin="docker"
image=""
output_mount="/output"
output_root="/output/dist"
preset=""
remove_services=""
repository_root=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
required_file=""
smoke_output=""

#
# Fail on errors and unset variables.
#
set -eu

#
# cleanup: Remove the isolated smoke-test output directory.
#
# Parameters: None.
#
# Returns: Nothing.
#
cleanup() {
    # Remove the isolated smoke-test output directory.
    if [ -n "${smoke_output}" ] && [ -d "${smoke_output}" ]; then
        rm -rf "${smoke_output}"
    fi
}

#
# usage: Print the supported command-line options.
#
# Parameters: None.
#
# Returns: Prints usage text.
#
usage() {
    # Print the supported command-line options.
    printf '%s\n' \
        "Usage: $0 --image <image> --preset <preset> --required-file <path> [options]" \
        "" \
        "Options:" \
        "  -i, --image <image>" \
        "  -p, --preset <preset>" \
        "  -a, --add-services <ids>" \
        "  -r, --remove-services <ids>" \
        "  -f, --required-file <path>" \
        "  -m, --output-mount <path>" \
        "  -o, --output-root <path>" \
        "  -d, --deployment-root <path>" \
        "  -b, --docker-bin <command>" \
        "  -h, --help"
}

#
# require_option_argument: Reject a flag whose value is missing.
#
# Parameters: $1 - Option name.
#             $2 - Number of remaining command-line arguments.
#
# Returns: 0 when a value follows; otherwise exits with status 2.
#
require_option_argument() {
    if [ "$2" -lt 2 ]; then
        printf '%s requires a value.\n' "$1" >&2
        exit 2
    fi
}

#
# run_hardened_image: Run the selected image with Maraudarr's runtime controls.
#
# Parameters: $@ - Docker options, image, and command arguments.
#
# Returns: The Docker command's exit status.
#
run_hardened_image() {
    "${docker_bin}" run \
        --rm \
        --read-only \
        --network none \
        --cap-drop ALL \
        --security-opt no-new-privileges:true \
        --tmpfs /tmp:rw,noexec,nosuid,size=64m \
        --user "$(id -u):$(id -g)" \
        "$@"
}

#
# Parse command-line flags and arguments.
#
while [ "$#" -gt 0 ]; do
    case "$1" in
        -i | --image)
            require_option_argument "$1" "$#"
            image=$2
            shift 2
            ;;
        -p | --preset)
            require_option_argument "$1" "$#"
            preset=$2
            shift 2
            ;;
        -a | --add-services)
            require_option_argument "$1" "$#"
            add_services=$2
            shift 2
            ;;
        -r | --remove-services)
            require_option_argument "$1" "$#"
            remove_services=$2
            shift 2
            ;;
        -f | --required-file)
            require_option_argument "$1" "$#"
            required_file=$2
            shift 2
            ;;
        -m | --output-mount)
            require_option_argument "$1" "$#"
            output_mount=$2
            shift 2
            ;;
        -o | --output-root)
            require_option_argument "$1" "$#"
            output_root=$2
            shift 2
            ;;
        -d | --deployment-root)
            require_option_argument "$1" "$#"
            deployment_root=$2
            shift 2
            ;;
        -b | --docker-bin)
            require_option_argument "$1" "$#"
            docker_bin=$2
            shift 2
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

#
# Validate that the required options are present.
#
if [ -z "${image}" ] || [ -z "${preset}" ] || [ -z "${required_file}" ]; then
    echo "--image, --preset, and --required-file are required." >&2
    exit 2
fi

#
# Validate that the output root is under the output mount.
#
expected_output_root="${output_mount}/${deployment_root}"
if [ "${output_root}" != "${expected_output_root}" ]; then
    echo "--output-root must equal --output-mount/--deployment-root." >&2
    exit 2
fi

#
# Generate into a disposable host directory and remove it on every exit path.
#
smoke_output=$(mktemp -d)
trap cleanup 0 1 2 15

#
# Run the terminal UI tests inside the exact image so optional runtime
# dependencies, including Rich, exercise their host-skipped presentation checks.
#
run_hardened_image \
    --volume "${repository_root}/docker:/source:ro" \
    --entrypoint python3 \
    "${image}" \
    -m unittest discover \
    --start-directory /source/tests \
    --pattern test_ui.py \
    --verbose

#
# Generate the requested deployment through the same hardened image contract.
#
run_hardened_image \
    --volume "${smoke_output}:${output_mount}:rw" \
    "${image}" \
    --plain build \
    --preset "${preset}" \
    --remove "${remove_services}" \
    --add "${add_services}" \
    --output-root "${output_root}"

#
# Validate that the expected files were generated.
#
smoke_deployment="${smoke_output}/${deployment_root}/${preset}"
test -s "${smoke_deployment}/docker-compose.yml"
test -s "${smoke_deployment}/.env"
test -s "${smoke_deployment}/${required_file}"

#
# Validate the generated chart with the locally available Compose interface.
#
if "${docker_bin}" compose version >/dev/null 2>&1; then
    "${docker_bin}" compose \
        --env-file "${smoke_deployment}/.env" \
        --file "${smoke_deployment}/docker-compose.yml" \
        config \
        --quiet
elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose \
        --env-file "${smoke_deployment}/.env" \
        --file "${smoke_deployment}/docker-compose.yml" \
        config \
        --quiet
else
    echo "Neither 'docker compose' nor 'docker-compose' is available." >&2
    exit 1
fi
