# PATTRMM Neo service chart 📅

Runs `ghcr.io/insertdisc/pattrmm:neo` and writes collection YAML and paired Plex-GUID text lists into the external Kometa checkout. Neo is a removable Duplex default.

## Settings and storage

`PATTRMM_SETTINGS_PATH` defaults to `${KOMETA_CONFIG_PATH}/pattrmm` and mounts read-only at `/settings`. The directory must exist. `PATTRMM_SETTINGS` selects `settings.yml` by default; comma-separated names select multiple files. The companion [Kometa configuration](https://github.com/scottgigawatt/kometa-config/blob/main/pattrmm/settings.yml) owns the library names, enabled cores, and collection presentation. Maraudarr does not seed or overwrite that external directory.

Neo reads `/config/config.yml`, shared with Kometa through [its service settings](../kometa/README.md). Use literal private Plex URL/token and TMDb key, language, and region values. Do not commit that live file. Generated collection files and their paired text lists must remain together beneath the configured `collection_dir`.

`PATTRMM_CONFIG_PATH/data` mounts writable at `/data` for the cache. Neo inherits the shared `rootless-container` anchor: `DEFAULT_PUID:DEFAULT_PGID` is its process identity, and `DEFAULT_GROUP` supplies the supplementary media-management group. Create the cache directory before startup and ensure that identity can write to it and the configured output directories in the Kometa checkout. Settings and the runtime connection file only need read access.

## Schedule and manual runs

`PATTRMM_TIMES` defaults to `02:00,14:00` in the configured `TZ`, ahead of Kometa's `05:00,17:00` runs. Allow enough time for generation to finish before Kometa reads its files. By Size can take longer for TV libraries because Neo retrieves episode sizes.

From the generated Duplex directory, run the selected settings immediately:

```sh
docker compose run --rm --no-deps pattrmm --run
```

Confirm each settings file reports `All operations complete` and no failed-settings messages or tracebacks before running Kometa. Neo can finish its parent process even when a settings run fails, so exit status alone is not sufficient. Start the scheduler normally with `docker compose up -d pattrmm`.

The companion configuration enables collections only, preserving its custom overlays. See the [Neo settings and core reference](https://github.com/InsertDisc/pattrmm/blob/neo/README.md) for In History, By Size, Extended Status, and optional generated overlays.
