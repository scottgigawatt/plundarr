# Cruisarr application data 🔞

This directory holds the Cruisarr SQLite database and encrypted integration credentials. The default host path is `./config/cruisarr`, relative to the generated deployment, and the container mounts it at `/data`. Maraudarr refreshes this README during generation and preserves existing application state.

## Before launch

- Confirm that the host identity set by `DEFAULT_PUID`, `DEFAULT_PGID`, and `DEFAULT_GROUP` can write this directory. Startup does not repair bind-mount ownership. Cruisarr image build arguments such as `CRUISARR_UID` and `CRUISARR_GID` are not runtime user-remapping settings; Plundarr selects the process identity through Compose `user:`.
- Read `CRUISARR_SETUP_SECRET` locally from the generated `.env` for one-time owner setup. Keep an off-host copy of `CRUISARR_SECRET_KEY` for decrypting stored credentials. Keep both values out of logs and source control.
- Prepare an existing Jellyfin server or select the local Jellyfin service. For services in this project, use `http://jellyfin:8096` and `http://whisparr:6969` in Cruisarr. Browser playback URLs must use the host address or reverse proxy.

## Backups and cleanup

Stop Cruisarr before copying its complete data directory, including any SQLite journal or write-ahead log files. Keep the matching encryption key separately. Restore into fresh storage with that key.

Replace `YOUR-PRESET` with your selected preset ID. `make backup PRESET=YOUR-PRESET` archives `dist/YOUR-PRESET/config` by default. It excludes `.env` and any data outside that tree. If `CRUISARR_CONFIG_PATH` points elsewhere, back up that host directory separately. Stopping Cruisarr does not make backups of other running applications consistent.

`make down` and `make nuke` preserve bind-mounted data. `make delete-config` deletes the selected host config tree, including Cruisarr data only when it is stored inside that tree. Keep backups outside the config tree and off the deployment host.

Follow the [Cruisarr setup and recovery guide](https://github.com/scottgigawatt/plundarr/blob/main/docs/project-guides/cruisarr.md#back-up-and-recover) for backup commands, verification, and recovery steps.
