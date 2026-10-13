# Themerr service chart 🎵

One official `lizardbyte/themerr:latest` instance manages theme songs for Plex and Jellyfin. Themerr is required in Duplex and selectable elsewhere; it does not require local Plex or Jellyfin containers. Configure server connections through its UI.

The chart uses the configured numeric host UID/GID directly because the image creates its user at build time. Runtime `PUID`/`PGID` values alone do not remap that user. `HOME=/tmp` permits temporary caches, while Docker mode keeps application state in `/config`. The service drops capabilities, prevents privilege escalation, and retains the upstream healthcheck. The official image currently supports amd64 and arm64.

The admin UI publishes HTTPS port 9494. HTTP port 9495 serves connector files for Jellyfin when the UI uses self-signed TLS. Persistent state is writable; the separate token-encryption key is read-only and must exist. No Docker socket, Plex metadata directory, SSH credentials, or media directory is mounted into Themerr. The Jellyfin connector writes themes through Jellyfin, so Jellyfin itself needs writable media folders.

See the [operator guide](../../../docs/project-guides/themerr.md) and [upstream Docker documentation](https://docs.lizardbyte.dev/projects/themerr/latest/about/docker.html).
