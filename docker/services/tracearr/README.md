# Tracearr service chart 🔎

Tracearr is the removable default media monitor in Plundarr and an optional service in every other preset. It connects to Plex, Jellyfin, or Emby over the project network or a reachable server address.

The chart uses the official application image, requires `tracearr-db` and `tracearr-redis`, and waits for both dependencies to become healthy. The app uses its upstream non-root identity; its writable backup workspace is a project-scoped named volume. Database and authentication credentials are generated into `.env` on first generation and preserved afterward.

The host port defaults to `3080`; the container and Homepage widget use `3000`. Watchtower updates are disabled for all three services. See the [monitoring guide](../../../docs/project-guides/monitoring.md) for setup, supported architectures, backup exports, and cleanup behavior.
