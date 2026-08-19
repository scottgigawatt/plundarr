#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# ps.sh: Display one Compose project's containers in a compact table.
#
# Usage: scripts/compose/ps.sh --env-file <path> --compose-file <path> [options]
#

#
# Variables for the Compose project and its environment.
#
compose_file=""
docker_bin="docker"
env_file=""

#
# Fail on errors and unset variables.
#
set -eu

#
# usage: Print the supported command-line options.
#
# Parameters: None.
#
# Returns: Prints usage text.
#
usage() {
    printf '%s\n' \
        "Usage: $0 --env-file <path> --compose-file <path> [options]" \
        "" \
        "Options:" \
        "  -e, --env-file <path>" \
        "  -f, --compose-file <path>" \
        "  -d, --docker-bin <command>" \
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
# Parse command-line flags and arguments.
#
while [ "$#" -gt 0 ]; do
    case "$1" in
        -e | --env-file)
            require_option_argument "$1" "$#"
            env_file=$2
            shift 2
            ;;
        -f | --compose-file)
            require_option_argument "$1" "$#"
            compose_file=$2
            shift 2
            ;;
        -d | --docker-bin)
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
# Validate that the required paths were provided.
#
if [ ! -f "${env_file}" ]; then
    printf 'Environment file not found: %s\n' "${env_file}" >&2
    exit 1
fi

#
# Validate required paths before asking Compose to inspect the project.
#
if [ ! -f "${compose_file}" ]; then
    printf 'Compose file not found: %s\n' "${compose_file}" >&2
    exit 1
fi

#
# Prefer Docker Compose v2 and retain support for a standalone v1 installation.
# Compose owns project-name resolution, so nested .env defaults remain correct.
#
if "${docker_bin}" compose version >/dev/null 2>&1; then
    "${docker_bin}" compose \
        --env-file "${env_file}" \
        -f "${compose_file}" \
        ps \
        --format 'table {{.Name}}\t{{.Service}}\t{{.Status}}\t{{.Ports}}'
elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose \
        --env-file "${env_file}" \
        -f "${compose_file}" \
        ps
else
    echo "Neither 'docker compose' nor 'docker-compose' is available." >&2
    exit 1
fi
