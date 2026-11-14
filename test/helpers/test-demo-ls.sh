#!/bin/sh

#
# Copyright 2026 Scott Gigawatt
#
# SPDX-License-Identifier: Apache-2.0
#
# test-demo-ls.sh: Verify demo ownership redaction and fail-closed output.
#
# Purpose: Check fixed ownership fields and ensure rejected output stays private.
#
# Usage: sh test/helpers/test-demo-ls.sh
#

set -eu
script_directory=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
test_directory=$(mktemp -d "${TMPDIR:-/tmp}/demo-ls-test.XXXXXX")

#
# cleanup: Remove this test's isolated fixtures.
#
# Parameters: None.
#
# Returns: Preserves the current exit status.
#
cleanup() {
    rm -rf -- "${test_directory}"
}

trap cleanup 0 1 2 15
cat >"${test_directory}/ls-stub" <<'STUB'
#!/bin/sh
set -eu
cat "${DEMO_LS_FIXTURE:?}"
printf '%s\n' 'operator-private-diagnostic' >&2
exit "${DEMO_LS_STATUS:-0}"
STUB
chmod 0700 "${test_directory}/ls-stub"
DEMO_LS_FIXTURE="${test_directory}/fixture"
PLUNDARR_DEMO_REAL_LS="${test_directory}/ls-stub"
PLUNDARR_DEMO_LISTING_VERIFIED="${test_directory}/verified"
export DEMO_LS_FIXTURE PLUNDARR_DEMO_REAL_LS PLUNDARR_DEMO_LISTING_VERIFIED

# Verify owner/group replacement while preserving the real metadata columns.
cat >"${DEMO_LS_FIXTURE}" <<'LISTING'
total 76K
drwxr-xr-x  3 operator operator-group  192B Nov 14 10:42 .
-rw-------@ 1 operator operator-group   16K Nov 14 10:42 .env
-rw-r--r--@ 1 operator operator-group   50K Nov 14 10:42 docker-compose.yml
LISTING
sh "${script_directory}/../../docs/demo/demo-ls.sh" -lah >"${test_directory}/safe"
test -f "${PLUNDARR_DEMO_LISTING_VERIFIED}"
grep -F 'scott users' "${test_directory}/safe" >/dev/null
grep -F -- '-rw-------@ 1 scott users   16K Nov 14 10:42 .env' "${test_directory}/safe" >/dev/null
if grep -F 'operator' "${test_directory}/safe" >/dev/null; then
    echo "Demo listing exposed an original ownership field." >&2
    exit 1
fi

# Reject an unexpected filename without publishing an earlier valid row.
rm -f "${PLUNDARR_DEMO_LISTING_VERIFIED}"
printf '%s\n' '-rw-r--r-- 1 operator operator-group 2K Nov 14 10:42 unexpected-file' >>"${DEMO_LS_FIXTURE}"
if sh "${script_directory}/../../docs/demo/demo-ls.sh" -lah >"${test_directory}/rejected" 2>"${test_directory}/error"; then
    echo "Demo listing accepted an unreviewed row." >&2
    exit 1
fi
test ! -s "${test_directory}/rejected"
test ! -e "${PLUNDARR_DEMO_LISTING_VERIFIED}"

# Propagate the actual listing command's failure without showing its raw output.
if DEMO_LS_STATUS=31 sh "${script_directory}/../../docs/demo/demo-ls.sh" -lah >"${test_directory}/failed" 2>"${test_directory}/error"; then
    echo "Demo listing hid a command failure." >&2
    exit 1
else
    test "$?" -eq 31
fi
test ! -s "${test_directory}/failed"
if grep -F 'operator-private-diagnostic' "${test_directory}/error" >/dev/null; then
    echo "Demo listing exposed a raw command diagnostic." >&2
    exit 1
fi
test ! -e "${PLUNDARR_DEMO_LISTING_VERIFIED}"

# Do not broaden this recording wrapper to unreviewed listing options.
if sh "${script_directory}/../../docs/demo/demo-ls.sh" -la >"${test_directory}/unsupported" 2>"${test_directory}/error"; then
    echo "Demo listing accepted unsupported arguments." >&2
    exit 1
fi
test ! -s "${test_directory}/unsupported"
test ! -e "${PLUNDARR_DEMO_LISTING_VERIFIED}"

echo "Demo listing privacy fixtures passed."
