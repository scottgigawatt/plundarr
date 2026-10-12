# Velvarr application data 🔞

This directory is mounted at `/data` and holds Velvarr's SQLite database, encrypted integration credentials, and artwork cache. The container runs as `DEFAULT_PUID:DEFAULT_PGID` with the shared `DEFAULT_GROUP`; these settings must match a host identity that can write this directory. The default host path is `./config/velvarr`, relative to the generated deployment.

Maraudarr creates missing seed files and refreshes this README. It preserves existing application state. The generated `.env` contains `VELVARR_SETUP_SECRET` for one-time owner setup and `VELVARR_SECRET_KEY` for decrypting stored credentials. Read the setup secret locally and keep an off-host copy of the encryption key; neither belongs in logs or source control.

Configure an existing Jellyfin server or select the local Jellyfin service before completing setup. For a server in this project, use `http://jellyfin:8096`; use `http://whisparr:6969` for Whisparr v3. Browser playback URLs must instead point to the host address or reverse proxy. Provider credentials and application connections are configured through Velvarr's interface.

Stop Velvarr before archiving its live SQLite files. `make backup PRESET=boudoirr` archives the host config tree but does not include `.env`; keep the matching encryption key separately. Restore into a fresh data directory with the same key. `make down` and `make nuke` preserve this directory; `make delete-config` deletes it. See the repository's Velvarr setup guide for the complete backup and recovery procedure.
