# Discover and request adult media with Velvarr 🔞

[Velvarr](https://github.com/Skare69/velvarr) discovers adult movies and scenes, sends approved requests to Whisparr v3, and connects users to Jellyfin playback. It is selected by default in Boudoirr alongside Jellyfin; both can be removed independently in the CLI or interactive picker. The current official image supports `linux/amd64` only.

## Select the services

You need a Jellyfin server, an account allowed to access the intended libraries, and a Jellyfin API key. Jellyfin is required for owner setup and user authentication; Plex alone cannot provide that login. To fulfill requests, also configure Whisparr v3 and its API key. Metadata provider credentials are entered in Velvarr's interface.

Generate Boudoirr with Velvarr and a local Jellyfin server:

```sh
make ship PRESET=boudoirr
```

If Jellyfin already runs in another project or on another host, omit the local Jellyfin container and connect the existing server during setup:

```sh
make ship PRESET=boudoirr REMOVE_SERVICES=jellyfin
```

To omit Velvarr, clear its initially checked box in `make configure`, or use:

```sh
make ship PRESET=boudoirr REMOVE_SERVICES=velvarr
```

To omit both companions, use `REMOVE_SERVICES=velvarr,jellyfin`. Other presets can select either service through `ADD_SERVICES` or `make configure`. Whisparr and Jellyfin are recommended integrations, so Maraudarr does not force local containers for either service. Include your complete service selection when regenerating an existing project.

## Review the generated defaults

Edit `dist/boudoirr/.env`. Defaults follow Plundarr's existing service conventions and Synology paths rather than requiring a separate environment file.

| Setting | Boudoirr default | Purpose |
| --- | --- | --- |
| `VELVARR_IMAGE` | `ghcr.io/skare69/velvarr` | Image repository without a tag; defaults to the official image |
| `VELVARR_TAG` | `latest` | Image channel or version; defaults to the official floating stable channel |
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

The application runs as `DEFAULT_PUID:DEFAULT_PGID` with `DEFAULT_GROUP`, matching other rootless service charts. Set the shared IDs from `id -u` and `id -g` for your Synology account and confirm that account can write the selected config directory. Velvarr does not need media or download mounts; it connects to Whisparr and Jellyfin over the project network. SQLite state uses this host bind mount rather than a named volume or separate database service.

## Switch between stable and fork images

Both freshly generated `.env` and `example.env` files default to the official stable image. The Compose chart uses `${VELVARR_IMAGE}:${VELVARR_TAG}`, so you can switch repositories and channels by editing only `dist/boudoirr/.env`. Existing deployments receive the official `VELVARR_IMAGE` default when regenerated; existing image and tag overrides are preserved. The reference `example.env` keeps the official defaults.

For a fork image, replace `YOUR-GITHUB-USER` with the publisher's lowercase registry namespace and set these assignments in `.env`:

```sh
VELVARR_IMAGE="ghcr.io/YOUR-GITHUB-USER/velvarr"
VELVARR_TAG="edge"
```

To use the official floating stable image again, set:

```sh
VELVARR_IMAGE="ghcr.io/skare69/velvarr"
VELVARR_TAG="latest"
```

Keep the repository and tag separate; do not include `:edge` or `:latest` in `VELVARR_IMAGE`. Pull the selected image and recreate only Velvarr:

```sh
docker compose --project-directory dist/boudoirr pull velvarr
docker compose --project-directory dist/boudoirr up -d velvarr
```

If your generated chart still contains the fixed image repository, regenerate it with your complete service selection before switching images. Changing `.env` or restarting the old container alone does not replace its image. Check that the selected image supports your host architecture and preserves compatibility with your existing application data; review its release notes before switching versions.

## Launch and complete setup

1. Start the generated project:

    ```sh
    make up PRESET=boudoirr
    ```

2. Open your host address on port `16699`, or the configured HTTPS reverse proxy. Read `VELVARR_SETUP_SECRET` locally from `dist/boudoirr/.env` and supply it during owner setup.
3. Connect Jellyfin using your account, API key, and selected adult-media libraries. Use `http://jellyfin:8096` for a Jellyfin container in this project. For a separate server, use an address reachable from the Velvarr container.
4. Set Jellyfin's external URL to the address users open in their browsers. An internal Docker hostname is not a browser playback address.
5. Connect Whisparr v3 at `http://whisparr:6969` with its API key. Review root folders, quality profiles, and path mappings in Velvarr. Whisparr mounts individual libraries beneath `/data`, while Jellyfin mounts the whole media root. With Boudoirr defaults, main Whisparr and Jellyfin movie and scene paths already match at `/data/movies` and `/data/scenes`. Review mappings when changing host paths.
6. Configure TPDB or StashDB credentials in Velvarr's metadata-provider settings, then verify discovery and request fulfillment.

If you select the optional [Whisparr Alt service](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/whisparr-alt/README.md) for TPDB movies, connect Velvarr to `http://whisparr-alt:6969` with that instance's API key. With the default mounts, map Alt's `/data/movies` to Jellyfin's `/data/movies-alt`; review both the host-library path and chosen movie provider before using Alt for requests. Velvarr currently connects to one Whisparr endpoint.

Check that the container becomes healthy:

```sh
make ps PRESET=boudoirr
```

The public healthcheck comes from [upstream's Dockerfile](https://github.com/Skare69/velvarr/blob/main/Dockerfile), using Plundarr's shared interval, timeout, start period, and retries. It confirms the application is responding; it does not prove owner setup or upstream integrations are complete. Upstream's [Compose example](https://github.com/Skare69/velvarr/blob/main/compose.yaml) does not set `read_only: true`; Plundarr adds that hardening while leaving `/data` and `/tmp` writable. The chart has no `depends_on` because Velvarr starts before owner setup and can connect to external Jellyfin and Whisparr servers. `localhost` in a service URL refers to the Velvarr container, not the Synology host.

`VELVARR_ORIGIN` is the exact address you open in your browser: scheme, hostname or IP address, and port when nonstandard. It has no path, query, or trailing slash. For example, use one of these values, replacing the example host with yours:

```sh
VELVARR_ORIGIN="http://192.168.1.210:16699"
```

```sh
VELVARR_ORIGIN="https://velvarr.example.com"
```

For a Synology HTTPS reverse proxy, set `VELVARR_ORIGIN` to the exact browser origin, such as `https://velvarr.example.com`, forward to host port `16699`, and pass `X-Forwarded-Proto: https`. Keep `VELVARR_ALLOW_HTTP=1` when internal Whisparr or Jellyfin connections use private HTTP. Set it to `0` only when those non-loopback connections use HTTPS. Recreate the container with `make up PRESET=boudoirr` after changing `.env`; a restart alone does not reload its environment.

## Connect Homepage

When Homepage and Velvarr are selected together, Maraudarr seeds a link card. `HOMEPAGE_VAR_VELVARR_HREF` defaults to `http://host.or.ip:${VELVARR_WEBUI_PORT}` and follows the published host port, including preset offsets and overrides. Replace `host.or.ip` with your browser-accessible hostname or set the full HTTPS URL in `.env`.

Maraudarr refreshes its generated `config/homepage/services.yaml` from the selected service charts during regeneration. Existing Homepage settings and environment values are preserved; edit the source fragment if you customize generated cards. This card is a link; it does not require an API key or assume compatibility with Seerr's widget.

## Back up and recover

> [!IMPORTANT]
> Keep an off-host copy of `VELVARR_SECRET_KEY` with every backup. The key is not stored in the database backup; losing it prevents recovery of encrypted credentials. `make backup` archives config files, not `.env`.

For a file-copy backup, stop Velvarr first and copy its entire `config/velvarr` directory, including any SQLite journal or write-ahead log files. Keep the matching encryption key separately. For a consistent host config archive, stop only Velvarr while the archive is created. A live SQLite database can have pending writes in its write-ahead log, so do not copy only its main database file while it is running.

```sh
docker compose --project-directory dist/boudoirr stop velvarr
make backup PRESET=boudoirr
docker compose --project-directory dist/boudoirr start velvarr
```

Confirm that the archive exists under `dist/boudoirr/backups`, save the matching encryption key separately, and keep a verified off-host copy. If backup fails, start Velvarr again after investigating the failure.

Restore the Velvarr config files from a stopped-container archive into a fresh data directory. Point `VELVARR_CONFIG_PATH` at that directory, restore the matching `VELVARR_SECRET_KEY`, check permissions, and recreate Velvarr. Preserve any SQLite companion files included in the archive. For an upstream online snapshot, restore it as `velvarr.sqlite` in a fresh directory with the same key; see [upstream backup and recovery](https://github.com/Skare69/velvarr#backup-and-recovery).

`make down`, `make nuke`, and regeneration preserve this bind-mounted application state. `make delete-config` deletes the host config tree, including Velvarr data and any backups stored inside that tree. Keep recovery copies outside it. Velvarr is eligible for Watchtower updates. Keep regular backups and review upstream release notes when managing its floating image tag.

Your requests deserve a lifeboat, too.
