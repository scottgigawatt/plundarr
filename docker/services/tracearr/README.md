# Tracearr service chart 🔎

Tracearr is the removable default media monitor in Plundarr and an optional service in every other preset. It connects to Plex, Jellyfin, or Emby over the project network or a reachable server address.

One catalog entry owns all three containers in this directory: `tracearr`, `tracearr-db`, and `tracearr-redis`. The shared `compose.yml` defines the complete group, and `environment.env` holds all of its settings. The internal database and Redis containers cannot be selected independently. Tracearr uses the official application image and waits for both dependencies to become healthy. The app uses its upstream non-root identity; its writable backup workspace is a project-scoped named volume. Database and authentication credentials are generated into `.env` on first generation and preserved afterward.

The host port defaults to `3080`; the container and Homepage widget use `3000`. Tracearr is eligible for automatic Watchtower updates; its database and Redis remain excluded. See the [monitoring guide](../../../docs/project-guides/monitoring.md) for setup, supported architectures, backup exports, and cleanup behavior.

The database uses the upstream-recommended TimescaleDB HA image with PostgreSQL 18 and Toolkit. Redis uses append-only persistence for queued jobs. Both use project-scoped named volumes and have no published host ports. The shared environment fragment defines database settings before application connection URIs so Compose can resolve their references.
