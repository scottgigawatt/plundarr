# Discover and request adult media with Cruisarr 🔞

[Cruisarr](https://github.com/scottgigawatt/cruisarr) discovers adult movies and scenes, sends approved requests to Whisparr v3, and connects users to Jellyfin playback. It is selected by default in Boudoirr alongside Jellyfin; both can be removed independently in the CLI or interactive picker. The private image supports `linux/amd64` and `linux/arm64`; ARMv7 is not supported. You need access to the private repository and GHCR package before launch.

Run generation examples from the repository root with `MARAUDARR_IMAGE` set to the [source-built generator](../development/maraudarr/index.md#choose-the-generator-revision) for this checkout.

## Select the services

You need a Jellyfin server, an account allowed to access the intended libraries, and a Jellyfin API key. Jellyfin is required for owner setup and user authentication; Plex alone cannot provide that login. To fulfill requests, also configure Whisparr v3 and its API key. Metadata provider credentials are entered in Cruisarr's interface.

Generate Boudoirr with Cruisarr and a local Jellyfin server:

```sh
make ship PRESET=boudoirr
```

If Jellyfin already runs in another project or on another host, omit the local Jellyfin container and connect the existing server during setup:

```sh
make ship PRESET=boudoirr REMOVE_SERVICES=jellyfin
```

To omit Cruisarr, clear its initially checked box in `make configure`, or use:

```sh
make ship PRESET=boudoirr REMOVE_SERVICES=cruisarr
```

To omit both companions, use `REMOVE_SERVICES=cruisarr,jellyfin`. Other presets can select either service through `ADD_SERVICES` or `make configure`. Whisparr and Jellyfin are recommended integrations, so Maraudarr does not force local containers for either service. Include your complete service selection when regenerating an existing project.

## Review the generated defaults

Edit `dist/boudoirr/.env`. Defaults follow Plundarr's existing service conventions and Synology paths rather than requiring a separate environment file.

| Setting | Boudoirr default | Purpose |
| --- | --- | --- |
| `CRUISARR_IMAGE` | `ghcr.io/scottgigawatt/cruisarr` | Image repository without a tag; private package; authenticated pull required |
| `CRUISARR_TAG` | `latest` | Image channel or version; floating image from validated `main` builds |
| `CRUISARR_WEBUI_PORT` | `16699` | Published host port; the container always listens on `6699` |
| `CRUISARR_CONFIG_PATH` | `./config/cruisarr` | Persistent data mounted at `/data` |
| `CRUISARR_SECRET_KEY` | Generated | 64 hexadecimal characters used to encrypt stored credentials |
| `CRUISARR_SETUP_SECRET` | Generated | Secret required for one-time owner setup |
| `CRUISARR_ORIGIN` | Empty | Optional exact browser origin; set it for a reverse proxy |
| `CRUISARR_ALLOW_HTTP` | `1` | Permit HTTP to private-network addresses, including Docker service names |
| `CRUISARR_UPDATE_CHECK` | `0` | Disable unauthenticated release checks for the private repository |
| `CRUISARR_WHISPARR_LIBRARY_LIMIT_MIB` | `64` | Decoded Whisparr library-response limit in MiB; whole numbers from `2` to `256` |
| `CRUISARR_DISCORD_WEBHOOK_URL` | Empty | Optional private HTTPS Discord webhook |
| `CRUISARR_DISCORD_DETAIL` | `0` | Send identity-only notifications; `1` also includes titles |

The base host port is `6699`; Boudoirr adds its normal `10000` offset, while Custom adds `30000`. Internal service URLs never receive the host-port offset. Both `.env` and `example.env` contain these defaults, but only `.env` receives generated secrets. Existing assignments, including empty values and operator overrides, survive regeneration exactly.

The application runs as `DEFAULT_PUID:DEFAULT_PGID` with `DEFAULT_GROUP`, matching other rootless service charts. Set the shared IDs from `id -u` and `id -g` for your Synology account and confirm that account can write the selected config directory. Cruisarr does not need media or download mounts; it connects to Whisparr and Jellyfin over the project network. SQLite state uses this host bind mount rather than a named volume or separate database service.

## Authenticate and select the image

The generated `.env` and `example.env` default to `ghcr.io/scottgigawatt/cruisarr:latest`. This is a private package: anonymous pulls fail. On the deployment host, authenticate with a GitHub account granted package access and a personal access token (classic) with `read:packages`. Enter the token at the password prompt; keep it out of `.env`, Compose files, shell history, and logs.

```sh
docker login ghcr.io
```

Synology Container Manager must also have authenticated access to `ghcr.io` when it pulls the project. A login on your workstation does not authenticate the NAS. See [Cruisarr's private-image guide](https://github.com/scottgigawatt/cruisarr/blob/main/docs/operations/private-images.md) for package requirements.

The Compose chart uses `${CRUISARR_IMAGE}:${CRUISARR_TAG}`. Keep the repository and tag separate in `dist/boudoirr/.env`; do not put a tag or digest in `CRUISARR_IMAGE`. Publication provides `latest` and `sha-<full-commit>` tags. A GitHub release version does not imply a matching container tag. To select an immutable published revision, use:

```sh
CRUISARR_IMAGE="ghcr.io/scottgigawatt/cruisarr"
CRUISARR_TAG="sha-5802d86a077a33932a1a2b858545fc5979ac854c"
```

Regeneration preserves these assignments. Cruisarr is excluded from Watchtower updates because the shared Watchtower service has no private-registry credentials. Back up the config and encryption key before an intentional update, review the selected image's requirements, then pull and recreate Cruisarr from the authenticated deployment account:

```sh
docker compose --project-directory dist/boudoirr pull cruisarr
docker compose --project-directory dist/boudoirr up -d cruisarr
```

If pulling reports `unauthorized` or `denied`, check package access and registry authentication on the deployment host. If no matching manifest exists, check the host architecture and selected tag. After recreating, check health, sign-in, saved connections, and request fulfillment.

## Launch and complete setup

1. Start the generated project:

    ```sh
    make up PRESET=boudoirr
    ```

2. Open your host address on port `16699`, or the configured HTTPS reverse proxy. Read `CRUISARR_SETUP_SECRET` locally from `dist/boudoirr/.env` and supply it during owner setup.
3. Connect Jellyfin using your account, API key, and selected adult-media libraries. Use `http://jellyfin:8096` for a Jellyfin container in this project. For a separate server, use an address reachable from the Cruisarr container.
4. Set Jellyfin's external URL to the address users open in their browsers. An internal Docker hostname is not a browser playback address.
5. Connect Whisparr v3 at `http://whisparr:6969` with its API key. Match Cruisarr's movie provider to the provider chosen in that Whisparr instance, and review root folders, quality profiles, and path mappings. Scenes use StashDB. Whisparr mounts individual libraries beneath `/data`, while Jellyfin mounts the whole media root. With Boudoirr defaults, map main Whisparr's `/data/movies` to Jellyfin's `/data/movies/main` and `/data/scenes` to `/data/scenes/main`. Review mappings when changing host paths.
6. Configure credentials for each supported provider in Cruisarr's metadata-provider settings. TMDB movie discovery requires a TMDB API read access token. Verify movie and scene request fulfillment independently.

Cruisarr supports TPDB and TMDB movies, StashDB scenes, and multiple Whisparr connections. If you select the optional [Whisparr Alt service](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/whisparr-alt/README.md), connect it at `http://whisparr-alt:6969` with its own API key. Assign a movie provider matching each instance's Whisparr configuration and choose the default instance for scenes. Either instance can handle either movie provider. With the default mounts, map Alt's `/data/movies` to Jellyfin's `/data/movies/alt` and `/data/scenes` to `/data/scenes/alt`. Host paths do not select provider identities.

Choose root folders, quality profiles, and path mappings independently for movies and scenes on each connection. With this chart, the Whisparr root is `/data` and folder-format prefixes are `movies/` and `scenes/`. Follow [Cruisarr's connection setup](https://github.com/scottgigawatt/cruisarr/blob/main/docs/operations/setup-and-configuration.md#tmdb-movies-and-multiple-whisparr-connections). Admit the intended Jellyfin users in Cruisarr before testing their sign-in.

Check that the container becomes healthy:

```sh
make ps PRESET=boudoirr
```

The storage-aware `/api/status` healthcheck comes from [upstream's Dockerfile](https://github.com/scottgigawatt/cruisarr/blob/main/Dockerfile), using Plundarr's shared interval, timeout, start period, and retries. It checks that the application can read its data directory; it does not prove owner setup or upstream integrations are complete. Upstream's [Compose example](https://github.com/scottgigawatt/cruisarr/blob/main/compose.yaml) does not set `read_only: true`; Plundarr adds that hardening while leaving `/data` and `/tmp` writable. The chart has no `depends_on` because Cruisarr starts before owner setup and can connect to external Jellyfin and Whisparr servers. `localhost` in a service URL refers to the Cruisarr container, not the Synology host.

`CRUISARR_ORIGIN` is the exact address you open in your browser: scheme, hostname or IP address, and port when nonstandard. It has no path, query, or trailing slash. For example, use one of these values, replacing the example host with yours:

```sh
CRUISARR_ORIGIN="http://192.168.1.210:16699"
```

```sh
CRUISARR_ORIGIN="https://cruisarr.example.com"
```

For a Synology HTTPS reverse proxy, set `CRUISARR_ORIGIN` to the exact browser origin, such as `https://cruisarr.example.com`, forward to host port `16699`, and pass `X-Forwarded-Proto: https`. Keep `CRUISARR_ALLOW_HTTP=1` when internal Whisparr or Jellyfin connections use private HTTP. Set it to `0` only when those non-loopback connections use HTTPS. The saved **Allow private HTTP** choice in Cruisarr overrides this environment fallback for outgoing connections. Recreate the container with `make up PRESET=boudoirr` after changing `.env`; a restart alone does not reload its environment.

## Connect Homepage

When Homepage and Cruisarr are selected together, Maraudarr seeds a link card. `HOMEPAGE_VAR_CRUISARR_HREF` defaults to `http://host.or.ip:${CRUISARR_WEBUI_PORT}` and follows the published host port, including preset offsets and overrides. Replace `host.or.ip` with your browser-accessible hostname or set the full HTTPS URL in `.env`.

Maraudarr refreshes its generated `config/homepage/services.yaml` from the selected service charts during regeneration. Existing Homepage settings and environment values are preserved; edit the source fragment if you customize generated cards. This card is a link; it does not require an API key or assume compatibility with Seerr's widget.

## Back up and recover

> [!IMPORTANT]
> Keep an off-host copy of `CRUISARR_SECRET_KEY` with every backup. The key is not stored in the database backup; losing it prevents recovery of encrypted credentials. `make backup` archives config files, not `.env`.

For a file-copy backup, stop Cruisarr first and copy its entire `config/cruisarr` directory, including any SQLite journal or write-ahead log files. Keep the matching encryption key separately. For a consistent host config archive, stop only Cruisarr while the archive is created. A live SQLite database can have pending writes in its write-ahead log, so do not copy only its main database file while it is running.

```sh
docker compose --project-directory dist/boudoirr stop cruisarr
make backup PRESET=boudoirr
docker compose --project-directory dist/boudoirr start cruisarr
```

Confirm that the archive exists under `dist/boudoirr/backups`, save the matching encryption key separately, and keep a verified off-host copy. If backup fails, start Cruisarr again after investigating the failure.

Restore the Cruisarr config files from a stopped-container archive into a fresh data directory. Point `CRUISARR_CONFIG_PATH` at that directory, restore the matching `CRUISARR_SECRET_KEY`, check permissions, and recreate Cruisarr. Preserve any SQLite companion files included in the archive. For an upstream online snapshot, restore it as `cruisarr.sqlite` in a fresh directory with the same key; see [Cruisarr backup and recovery](https://github.com/scottgigawatt/cruisarr/blob/main/docs/operations/setup-and-configuration.md#backup-and-recovery).

`make down`, `make nuke`, and regeneration preserve this bind-mounted application state. `make delete-config` deletes the host config tree, including Cruisarr data and any backups stored inside that tree. Keep recovery copies outside it. Cruisarr requires intentional authenticated updates. Keep regular backups and review release notes before updating its image.

Your requests deserve a lifeboat, too.
