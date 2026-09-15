# Monitor media servers with Tracearr 🔎

Tracearr is Plundarr's preferred media monitor and a removable default. It connects to Plex, Jellyfin, or Emby over the network; the media server can run in another project or on another host. Duplex focuses on Kometa and ImageMaid, with removable PATTRMM, Notifiarr, and Overlay Reset companions. Tautulli remains an optional Plex monitor in every preset.

## Select monitoring services

A fresh Plundarr generation includes Tracearr:

```sh
make ship PRESET=plundarr
```

For an existing project, select Tracearr in `make configure` or explicitly include it while generating. The single `tracearr` selection includes the application, TimescaleDB, and Redis together; its internal containers are not separate choices:

```sh
make ship PRESET=duplex ADD_SERVICES=tracearr
```

To omit it from Plundarr or select Tautulli instead:

```sh
make ship PRESET=plundarr REMOVE_SERVICES=tracearr
make ship PRESET=plundarr REMOVE_SERVICES=tracearr ADD_SERVICES=tautulli
```

Both monitors may run together. Regeneration preserves existing application configuration and previously configured environment values, including values belonging to temporarily unselected services. Keep your complete service selection when regenerating a project.

## Configure and launch

Edit the generated `dist/<preset>/.env`. The standard deployment follows [Tracearr's Docker Compose installation](https://docs.tracearr.com/getting-started/installation) with three containers and supports `linux/amd64` and `linux/arm64`. It does not support `linux/arm/v7`.

| Setting | Default | Purpose |
| --- | --- | --- |
| `TRACEARR_TAG` | `latest` | Official stable application image channel |
| `TRACEARR_WEBUI_PORT` | `3080` in Plundarr | Host web port; other presets may offset it |
| `TRACEARR_NODE_ENV` | `production` | Node.js runtime mode |
| `TRACEARR_HOST` | `0.0.0.0` | Container listen address |
| `TRACEARR_PORT` | `3000` | Internal web port shared by the service, healthcheck, and Homepage |
| `TRACEARR_DB_USER` / `TRACEARR_DB_NAME` | `tracearr` | PostgreSQL account and database name |
| `TRACEARR_DATABASE_URL` | Derived from database settings | Application PostgreSQL connection URI |
| `TRACEARR_REDIS_URL` | `redis://tracearr-redis:6379` | Application Redis connection URI |
| `TRACEARR_DB_TAG` | `pg18` | TimescaleDB HA channel tracking PostgreSQL 18 patch and TimescaleDB releases |
| `TRACEARR_DB_SHM_SIZE` | `512mb` | Database shared-memory allocation |
| `TRACEARR_DB_NOFILE_SOFT` / `TRACEARR_DB_NOFILE_HARD` | `65536` | Database open-file limits; soft must not exceed hard |
| `TRACEARR_REDIS_TAG` | `8-alpine` | Redis image channel |
| `TRACEARR_LOG_LEVEL` | `info` | Application logging verbosity |
| `TRACEARR_TRUST_PROXY` | `false` | Enable only behind a trusted reverse proxy |

Maraudarr generates separate random values for `TRACEARR_DB_PASSWORD`, `TRACEARR_JWT_SECRET`, `TRACEARR_COOKIE_SECRET`, and `TRACEARR_AUTH_SECRET` in `.env`. It preserves those values on subsequent runs; `example.env` contains empty placeholders. Keep `.env` private and back it up securely alongside exported database backups. Changing the database password in `.env` does not change the password inside an initialized PostgreSQL database; coordinate credential changes with PostgreSQL.

Start the selected project:

```sh
make up PRESET=plundarr
```

Open `http://YOUR-HOST:3080`, using the actual generated host port, create the owner account, and connect your media server using Tracearr's setup flow. Supply a server address reachable from the Tracearr container; `localhost` refers to that container. No VPN dependency or media-library filesystem mount is required. PostgreSQL and Redis have no published host ports.

After changing `.env`, run `make up PRESET=plundarr` again to recreate affected containers. A plain container restart does not reload environment settings. Use the corresponding preset name throughout when deploying elsewhere.

## Connect Homepage

When Homepage and Tracearr are selected together, Maraudarr seeds a native Tracearr widget. Set `HOMEPAGE_VAR_TRACEARR_HREF` to the browser-accessible URL and `HOMEPAGE_VAR_TRACEARR_KEY` to an API key created in Tracearr. The internal `HOMEPAGE_VAR_TRACEARR_URL` defaults to `http://tracearr:3000`, deriving its port from `TRACEARR_PORT` independently of the published host port. Recreate Homepage after editing `.env`.

Existing operator-edited Homepage files are preserved. Add the [Tracearr widget](https://gethomepage.dev/widgets/services/tracearr/) to an existing `config/homepage/services.yaml` if it does not already contain the generated card. Tautulli's card remains available when Tautulli is selected.

## Back up and update

Tracearr's database, Redis state, and backup workspace use project-scoped named Docker volumes. Docker manages their permissions; regeneration and `make down` preserve them. Watchtower can update Tracearr automatically. Its database and Redis remain excluded from unattended updates. Review upstream release notes and export a backup before deliberately changing image tags or database versions.

Create a consistent application backup, then export it into the generated config tree so your existing host backup tooling can collect it:

```sh
docker compose --project-directory dist/plundarr exec -T tracearr node apps/server/scripts/backup.ts
mkdir -p dist/plundarr/config/tracearr/backups
docker compose --project-directory dist/plundarr cp tracearr:/data/backup/. dist/plundarr/config/tracearr/backups/
make backup PRESET=plundarr
```

`make backup` archives the host config tree; it does not dump databases or copy named volumes. Duplicati likewise needs exported backup files in its configured source paths. Downloading a backup through Tracearr's web interface is another option. Use the application's backup and restore interface for restoration; do not copy live PostgreSQL data files.

> [!CAUTION]
> `make nuke` deletes this project's named volumes, including Tracearr history and backups still inside its backup volume. Export and verify a backup first. `make delete-config` deletes the host config tree, including exports stored there. Keep a separate backup copy before either destructive operation.

Retain the matching `.env` and an off-host copy of exported backups. Your viewing history deserves a lifeboat.
