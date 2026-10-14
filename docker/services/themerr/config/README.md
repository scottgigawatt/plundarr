# Themerr generated state 🎵

This directory contains Themerr settings, its SQLite database, logs, and certificates. Maraudarr seeds conservative cleanup and restart settings once, then preserves application edits. Use the Themerr UI to change processing and connection preferences.

The separate `../secrets/themerr-tokens.key` file encrypts stored credentials. Keep it private, readable by the configured host user, and backed up with this directory. Regeneration never replaces a key. If the managed state already exists and the key is missing, restore it before regenerating. External paths in `.env` remain operator-managed and are not populated by Maraudarr.

Open `https://HOST:9494` using the generated host port. Read the first-run admin setup link locally in container logs, create the administrator account, and add Plex and Jellyfin on the Servers page. Jellyfin must reach Themerr's connector address using a host address and its published connector port. Review automatic connector installation, restart, and older-plugin migration preferences before connecting.

Read the [Themerr project guide](https://github.com/scottgigawatt/plundarr/blob/main/docs/project-guides/themerr.md) for permissions, setup, backups, and media-library requirements.
