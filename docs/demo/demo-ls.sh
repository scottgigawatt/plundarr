#!/bin/sh

#
# Copyright 2026 Scott Gigawatt
#
# SPDX-License-Identifier: Apache-2.0
#
# demo-ls.sh: Show real generated-file metadata with public demo ownership.
#
# Purpose: Publish reviewed file metadata without recording workstation identities.
#
# Usage: PLUNDARR_DEMO_REAL_LS=<path> PLUNDARR_DEMO_LISTING_VERIFIED=<path> ls -lah
#

set -eu
: "${PLUNDARR_DEMO_REAL_LS:?The recording must provide the real ls executable}"
: "${PLUNDARR_DEMO_LISTING_VERIFIED:?The recording must provide a verification marker}"

# Restrict this recording-only wrapper to the reviewed listing command.
if [ "$#" -ne 1 ] || [ "$1" != "-lah" ]; then
    echo "The demo listing only supports ls -lah." >&2
    exit 2
fi

listing_directory=$(mktemp -d "${TMPDIR:-/tmp}/maraudarr-demo-ls.XXXXXX")

#
# cleanup: Remove only this listing's private temporary files.
#
# Parameters: None.
#
# Returns: Preserves the current exit status.
#
cleanup() {
    rm -rf -- "${listing_directory}"
}

trap cleanup 0 1 2 15

# Buffer raw metadata privately; publish nothing until every row is validated.
if LC_ALL=C "${PLUNDARR_DEMO_REAL_LS}" "$@" >"${listing_directory}/raw" 2>"${listing_directory}/error"; then
    :
else
    listing_status=$?
    echo "The demo listing command failed; raw metadata was not displayed." >&2
    exit "${listing_status}"
fi

if ! awk '
    /^total[[:space:]]+[0-9]+([.][0-9]+)?[BKMGTPE]?$/ {
        print
        next
    }
    NF == 9 && $1 ~ /^[-bcdlps][rwxStTs-]+[@+.]?$/ && length($1) >= 10 && $2 ~ /^[0-9]+$/ && $5 ~ /^[0-9]+([.][0-9]+)?[BKMGTPE]?$/ {
        if ($9 !~ /^(\.|\.\.|\.env|config|docker-compose\.yml|example\.env)$/) {
            failed = 1
            exit 1
        }

        # Preserve permissions, links, sizes, dates, and filenames byte for byte.
        match($0, /^[^[:space:]]+[[:space:]]+[0-9]+[[:space:]]+/)
        prefix = substr($0, 1, RLENGTH)
        remainder = substr($0, RLENGTH + 1)
        sub(/^[^[:space:]]+[[:space:]]+[^[:space:]]+/, "", remainder)
        printf "%s%-5s %-5s%s\n", prefix, "scott", "users", remainder
        rows++
        next
    }
    {
        failed = 1
        exit 1
    }
    END {
        if (failed || rows == 0) {
            exit 1
        }
    }
' "${listing_directory}/raw" >"${listing_directory}/safe"; then
    echo "Unexpected demo listing format; capture stopped before showing metadata." >&2
    exit 1
fi

cat "${listing_directory}/safe"
: >"${PLUNDARR_DEMO_LISTING_VERIFIED}"
