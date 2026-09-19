# PATTRMM service chart 📅

Runs PATTRMM on its daily schedule and writes generated metadata and overlays into the external Kometa checkout.

PATTRMM reads the same `/config/config.yml` as Kometa. Configure that file through the [Kometa service settings](../kometa/README.md). Working data and operator-managed preferences stay under `PATTRMM_CONFIG_PATH`.

PATTRMM is a removable default in Duplex. See the [upstream documentation](https://github.com/InsertDisc/pattrmm) for its settings and templates.
