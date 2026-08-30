# ImageMaid Service Chart 🧹

Runs the official ImageMaid companion for Plex artwork reporting and cleanup. It keeps its own state under `IMAGEMAID_CONFIG_PATH` and receives the Plex application-data directory at `/plex`.

`IMAGEMAID_PLEX_PATH` must point to the directory containing Plex's `Cache`, `Metadata`, and `Plug-in Support` folders. Configure ImageMaid's operational mode and Plex credentials in its mounted config directory before enabling cleanup behavior.

See the [official ImageMaid guide](https://kometa.wiki/en/latest/kometa/scripts/imagemaid/).
