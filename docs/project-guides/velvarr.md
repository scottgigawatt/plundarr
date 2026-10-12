# Discover and request adult media with Velvarr 🔞

[Velvarr](https://github.com/Skare69/velvarr) discovers adult movies and scenes, sends approved requests to Whisparr v3, and connects users to Jellyfin playback. It is recommended beside Whisparr in Maraudarr and remains opt-in. The current official image supports `linux/amd64` only.

## Select the services

You need a Jellyfin server, an account allowed to access the intended libraries, and a Jellyfin API key. Jellyfin is required for owner setup and user authentication; Plex alone cannot provide that login. To fulfill requests, also configure Whisparr v3 and its API key. Metadata provider credentials are entered in Velvarr's interface.

Generate Boudoirr with Velvarr and a local Jellyfin server:

```sh
make ship PRESET=boudoirr ADD_SERVICES=velvarr,jellyfin
```

If Jellyfin already runs in another project or on another host, select only Velvarr:

```sh
make ship PRESET=boudoirr ADD_SERVICES=velvarr
```

Other presets can select `velvarr` through `ADD_SERVICES` or `make configure`. Whisparr and Jellyfin are recommended integrations, so Maraudarr does not force local containers for either service. Include your complete service selection when regenerating an existing project.

## Review the generated defaults

Edit `dist/boudoirr/.env`. Defaults follow Plundarr's existing service conventions and Synology paths rather than requiring a separate environment file.

| Setting | Boudoirr default | Purpose |
| --- | --- | --- |
| `VELVARR_TAG` | `latest` | Official floating stable image channel |
| `VELVARR_WEBUI_PORT` | `16699` | Published host port; the container always listens on `6699` |
| `VELVARR_CONFIG_PATH` | `./config/velvarr` | Persistent data mounted at `/data` |
| `VELVARR_SECRET_KEY` | Generated | 64 hexadecimal characters used to encrypt stored credentials |
| `VELVARR_SETUP_SECRET` | Generated | Secret required for one-time owner setup |
| `VELVARR_ORIGIN` | Empty | Optional exact browser origin; set it for a reverse proxy |
| `VELVARR_ALLOW_HTTP` | `1` | Permit HTTP to private-network addresses, including Docker service names |
| `VELVARR_UPDATE_CHECK` | `1` | Enable upstream release notices |
| `VELVARR_DISCORD_WEBHOOK_URL` | Empty | Optional private HTTPS Discord webhook |
| `VELVARR_DISCORD_DETAIL` | `0` | Send identity-only notifications; `1` also includes titles |

The base host port is `6699`; Boudoirr adds its normal `10000` offset, while Custom adds `30000`. Internal service URLs never receive the host-port offset. Both `.env` and `example.env` contain these defaults, but only `.env` receives generated secrets. Existing assignments, including empty values and operator overrides, survive regeneration exactly.

The application runs as `DEFAULT_PUID:DEFAULT_PGID` with `DEFAULT_GROUP`, matching other rootless service charts. Set the shared IDs from `id -u` and `id -g` for your Synology account and confirm that account can write the selected config directory. Velvarr does not need media or download mounts; it connects to Whisparr and Jellyfin over the project network.

## Launch and complete setup

1. Start the generated project:

    ```sh
    make up PRESET=boudoirr
    ```

2. Open your host address on port `16699`, or the configured HTTPS reverse proxy. Read `VELVARR_SETUP_SECRET` locally from `dist/boudoirr/.env` and supply it during owner setup.
3. Connect Jellyfin using your account, API key, and selected adult-media libraries. Use `http://jellyfin:8096` for a Jellyfin container in this project. For a separate server, use an address reachable from the Velvarr container.
4. Set Jellyfin's external URL to the address users open in their browsers. An internal Docker hostname is not a browser playback address.
5. Connect Whisparr v3 at `http://whisparr:6969` with its API key. Review root folders, quality profiles, and path mappings in Velvarr. Whisparr and Jellyfin in this preset share `/data`, so corresponding library paths can match.
6. Configure TPDB or StashDB credentials in Velvarr's metadata-provider settings, then verify discovery and request fulfillment.

Check that the container becomes healthy:

```sh
make ps PRESET=boudoirr
```

The public healthcheck confirms the application is responding; it does not prove owner setup or upstream integrations are complete. `localhost` in a service URL refers to the Velvarr container, not the Synology host.

For a Synology HTTPS reverse proxy, set `VELVARR_ORIGIN` to the exact browser origin, such as `https://velvarr.example.com`, forward to host port `16699`, and pass `X-Forwarded-Proto: https`. Keep `VELVARR_ALLOW_HTTP=1` when internal Whisparr or Jellyfin connections use private HTTP. Set it to `0` only when those non-loopback connections use HTTPS. Recreate the container with `make up PRESET=boudoirr` after changing `.env`; a restart alone does not reload its environment.

## Connect Homepage

When Homepage and Velvarr are selected together, Maraudarr seeds a link card. `HOMEPAGE_VAR_VELVARR_HREF` defaults to `http://host.or.ip:${VELVARR_WEBUI_PORT}` and follows the published host port, including preset offsets and overrides. Replace `host.or.ip` with your browser-accessible hostname or set the full HTTPS URL in `.env`.

Maraudarr refreshes its generated `config/homepage/services.yaml` from the selected service charts during regeneration. Existing Homepage settings and environment values are preserved; edit the source fragment if you customize generated cards. This card is a link; it does not require an API key or assume compatibility with Seerr's widget.

## Back up and recover

> [!IMPORTANT]
> Keep an off-host copy of `VELVARR_SECRET_KEY` with every backup. The key is not stored in the database backup; losing it prevents recovery of encrypted credentials. `make backup` archives config files, not `.env`.

For a consistent host config archive, stop only Velvarr while the archive is created. A live SQLite database can have pending writes in its write-ahead log, so do not copy only its main database file while it is running.

```sh
docker compose --project-directory dist/boudoirr stop velvarr
make backup PRESET=boudoirr
docker compose --project-directory dist/boudoirr start velvarr
```

Confirm that the archive exists under `dist/boudoirr/backups`, save the matching encryption key separately, and keep a verified off-host copy. If backup fails, start Velvarr again after investigating the failure.

Restore the Velvarr config files from a stopped-container archive into a fresh data directory. Point `VELVARR_CONFIG_PATH` at that directory, restore the matching `VELVARR_SECRET_KEY`, check permissions, and recreate Velvarr. Preserve any SQLite companion files included in the archive. For an upstream online snapshot, restore it as `velvarr.sqlite` in a fresh directory with the same key; see [upstream backup and recovery](https://github.com/Skare69/velvarr#backup-and-recovery).

`make down`, `make nuke`, and regeneration preserve this bind-mounted application state. `make delete-config` deletes the host config tree, including Velvarr data and any backups stored inside that tree. Keep recovery copies outside it. Watchtower updates are disabled for Velvarr; export a backup and review upstream release notes before deliberately updating its floating tag.

Your requests deserve a lifeboat, too.
