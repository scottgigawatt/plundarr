# Kometa service chart 🎭

Runs the official Kometa image as a persistent scheduled service. The independently managed configuration checkout is mounted at `/config`; Maraudarr does not clone, seed, or replace that repository.

Set `KOMETA_CONFIG_PATH` in the generated deployment's `.env` to the host directory containing `config.yml`, assets, metadata, overlays, and any other files Kometa needs. `KOMETA_TIMES` accepts a comma-separated list of `HH:MM` times for the current stable image.

`KOMETA_RUNTIME_CONFIG_PATH` selects the existing live YAML file mounted at `/config/config.yml` for both Kometa and PATTRMM. It defaults to `${KOMETA_CONFIG_PATH}/config.yml`. To keep credentials outside tracked source, point it at an ignored private file such as `/path/to/kometa-config/.secrets/config.yml`. Create and configure that file before startup; a missing file fails the bind mount instead of becoming an empty directory. Maraudarr preserves the selected path during regeneration and never creates or overwrites the external file.

See the [official Docker walkthrough](https://kometa.wiki/en/latest/kometa/install/docker/) and [runtime environment reference](https://kometa.wiki/en/latest/kometa/environmental/).
