# Kometa Service Chart 🎭

Runs the official Kometa image as a persistent scheduled service. The independently managed configuration checkout is mounted at `/config`; Maraudarr does not clone, seed, or replace that repository.

Set `KOMETA_CONFIG_PATH` in the generated deployment's `.env` to the host directory containing `config.yml`, assets, metadata, overlays, and any other files Kometa needs. `KOMETA_TIMES` accepts a comma-separated list of `HH:MM` times for the current stable image.

See the [official Docker walkthrough](https://kometa.wiki/en/latest/kometa/install/docker/) and [runtime environment reference](https://kometa.wiki/en/latest/kometa/environmental/).
