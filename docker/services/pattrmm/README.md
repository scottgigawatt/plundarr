# PATTRMM service chart 📅

Runs PATTRMM on its daily internal schedule and shares the external Kometa configuration checkout so generated metadata and overlay files land where Kometa can use them.

PATTRMM is included in the Duplex preset for feature parity, but it is a removable default rather than a core service. Check the upstream project before depending on it long-term, and remove it from the preset whenever it no longer fits the deployment.

See the [upstream PATTRMM documentation](https://github.com/InsertDisc/pattrmm).
