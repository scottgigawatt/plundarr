#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# prepare-python.sh: Create the exact Python virtual environment used by the
#                    developer documentation toolchain.
#
# Usage: scripts/docs/prepare-python.sh --python-bin <command> \
#            --python-version <version> --venv-path <path> \
#            --python-target <path> --stamp-path <path>
#

#
# Command-line values describing the required interpreter and environment.
#
python_bin=""
python_version=""
venv_path=""
python_target=""
stamp_path=""

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
        "Usage: $0 --python-bin <command> --python-version <version> [options]" \
        "" \
        "Options:" \
        "  --python-bin <command>      Required Python interpreter." \
        "  --python-version <version>  Exact supported Python version." \
        "  --venv-path <path>          Documentation virtual environment." \
        "  --python-target <path>      Interpreter inside the environment." \
        "  --stamp-path <path>         Versioned completion stamp." \
        "  --help                      Show this help text."
}

#
# require_option_argument: Reject an option whose value is missing.
#
# Parameters: $1 - Option name.
#             $2 - Number of remaining command-line arguments.
#
# Returns: Returns 0 when a value follows; otherwise exits with status 2.
#
require_option_argument() {
    # Require another argument after the current option.
    if [ "$2" -lt 2 ]; then
        printf '%s requires a value.\n' "$1" >&2
        exit 2
    fi
}

#
# interpreter_version: Print one interpreter's semantic version string.
#
# Parameters: $1 - Python interpreter command or path.
#
# Returns: Prints the version without Python's leading label.
#
interpreter_version() {
    "$1" --version 2>&1 | sed 's/^Python[[:space:]]*//'
}

#
# Parse command-line options.
#
while [ "$#" -gt 0 ]; do
    case "$1" in
        --python-bin)
            require_option_argument "$1" "$#"
            python_bin=$2
            shift 2
            ;;
        --python-version)
            require_option_argument "$1" "$#"
            python_version=$2
            shift 2
            ;;
        --venv-path)
            require_option_argument "$1" "$#"
            venv_path=$2
            shift 2
            ;;
        --python-target)
            require_option_argument "$1" "$#"
            python_target=$2
            shift 2
            ;;
        --stamp-path)
            require_option_argument "$1" "$#"
            stamp_path=$2
            shift 2
            ;;
        --help)
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
# Require every path and version used by the environment setup.
#
if [ -z "${python_bin}" ] || [ -z "${python_version}" ] || \
    [ -z "${venv_path}" ] || [ -z "${python_target}" ] || \
    [ -z "${stamp_path}" ]; then
    echo "All Python environment options are required." >&2
    usage >&2
    exit 2
fi

#
# Reject broad paths before replacing an incompatible virtual environment.
#
case "${venv_path}" in
    / | . | .. | ./ | ../ | */./* | */../* | */. | */..)
        printf 'Refusing unsafe documentation environment path: %s\n' \
            "${venv_path}" >&2
        exit 2
        ;;
esac

#
# Keep the interpreter and stamp inside the environment that may be replaced.
#
case "${python_target}" in
    "${venv_path}"/*)
        ;;
    *)
        echo "The documentation Python target must be inside the virtual environment." >&2
        exit 2
        ;;
esac

case "${stamp_path}" in
    "${venv_path}"/*)
        ;;
    *)
        echo "The documentation stamp must be inside the virtual environment." >&2
        exit 2
        ;;
esac

#
# Require the configured host interpreter and its exact supported version.
#
if ! command -v "${python_bin}" >/dev/null 2>&1; then
    printf 'Python %s is required to build documentation.\n' \
        "${python_version}" >&2
    printf 'Install %s or override DOCS_PYTHON_BIN with the exact interpreter path.\n' \
        "${python_bin}" >&2
    exit 1
fi

host_version=$(interpreter_version "${python_bin}")

#
# Require the documented patch release so dependency hashes remain reproducible.
#
if [ "${host_version}" != "${python_version}" ]; then
    printf 'Python %s is required; %s reports %s.\n' \
        "${python_version}" "${python_bin}" "${host_version}" >&2
    printf 'Set DOCS_PYTHON_BIN to a Python %s executable.\n' \
        "${python_version}" >&2
    exit 1
fi

environment_version=""

#
# Read the existing environment version only when its interpreter is executable.
#
if [ -x "${python_target}" ]; then
    environment_version=$(interpreter_version "${python_target}")
fi

#
# Replace only an absent or version-mismatched documentation environment.
#
if [ "${environment_version}" != "${python_version}" ]; then
    rm -rf -- "${venv_path}"

    # Report missing venv support with the same corrective action used by Make.
    if ! "${python_bin}" -m venv "${venv_path}"; then
        echo "Python venv support is required to build documentation." >&2
        echo "Install Python with venv support, then run make docs." >&2
        exit 1
    fi
fi

#
# Record the validated interpreter version for Make's dependency graph.
#
touch "${stamp_path}"
