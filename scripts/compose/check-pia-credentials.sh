#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# check-pia-credentials.sh: Validate resolved PIA credentials without sourcing
#                           an environment file or printing secret values.
#
# Usage: docker compose config --environment | scripts/compose/check-pia-credentials.sh
#

#
# Fail on errors and unset variables.
#
set -eu

#
# Validate that the resolved PIA credentials are not empty or still use the
# documented example values.
#
pia_user=""
pia_pass=""

#
# credential_is_invalid: Identify an empty or generated example credential.
#
# Parameters: $1 - Resolved credential value.
#             $2 - Generated example value.
#
# Returns: 0 when invalid; otherwise returns 1.
#
credential_is_invalid() {
    [ -z "$1" ] || [ "$1" = "$2" ]
}

#
# Read only the two required values from Docker Compose's resolved environment.
# Values are retained in memory and never written to stdout or stderr.
#
while IFS= read -r environment_line; do
    case "${environment_line}" in
        PIA_USER=*)
            pia_user=${environment_line#PIA_USER=}
            ;;
        PIA_PASS=*)
            pia_pass=${environment_line#PIA_PASS=}
            ;;
    esac
done

#
# Reject missing values and the documented examples generated for new stacks.
#
if credential_is_invalid "${pia_user}" "p1234567"; then
    echo "PIA_USER is missing or still uses the generated example value." >&2
    echo "Set PIA_USER in the selected preset's .env file before starting Privateerr." >&2
    exit 1
fi

#
# Reject missing values and the documented examples generated for new stacks.
#
if credential_is_invalid "${pia_pass}" "abc123"; then
    echo "PIA_PASS is missing or still uses the generated example value." >&2
    echo "Set PIA_PASS in the selected preset's .env file before starting Privateerr." >&2
    exit 1
fi
