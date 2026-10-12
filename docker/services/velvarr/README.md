# Velvarr service chart 🔞

Adds the [Velvarr adult-media discovery and request application](https://github.com/Skare69/velvarr) to Maraudarr's selectable catalog. Whisparr and Jellyfin are recommended integrations rather than forced container dependencies: either can run in another project or on another host. Jellyfin is required to complete Velvarr's owner setup and authenticate users; Whisparr v3 fulfills approved requests.

The chart uses the official floating `latest` channel, the shared host UID/GID mapping, a read-only root filesystem, and a writable `/data` bind mount. The image currently supports `linux/amd64` only. Its public healthcheck uses Node.js rather than assuming `wget` or `curl` is installed. Watchtower updates are disabled so database migrations remain deliberate.

Maraudarr generates both required secrets once and preserves existing assignments. Homepage receives a link card only when both services are selected. See the [Velvarr setup guide](../../../docs/project-guides/velvarr.md) for connection URLs, permissions, backups, and recovery.
