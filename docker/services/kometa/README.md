# Kometa service chart 🎭

Runs Kometa on a daily schedule using an independently managed checkout. Maraudarr does not clone, seed, or overwrite that checkout.

Set `KOMETA_CONFIG_PATH` to the host directory containing `config.yml`, assets, metadata, and overlays. Both Kometa and PATTRMM mount it at `/config` and read the root `config.yml` by default.

`KOMETA_RUNTIME_CONFIG_PATH` defaults to `${KOMETA_CONFIG_PATH}/config.yml`. Set it only when using a different live file. The selected file replaces `/config/config.yml` inside both containers, so edits to the checkout's root file have no effect while an override is active. The file must exist before startup; regeneration preserves the selected path.

Keep credentials out of commits. PATTRMM needs literal connection values in the shared YAML rather than Kometa environment-secret substitutions.

Set `KOMETA_TIMES` to one or more comma-separated `HH:MM` times. See the [Docker walkthrough](https://kometa.wiki/en/latest/kometa/install/docker/) and [runtime options](https://kometa.wiki/en/latest/kometa/environmental/) for manual runs and validation.
