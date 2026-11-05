# Discover and request adult media with Cruisarr 🔞

[Cruisarr](https://github.com/scottgigawatt/cruisarr) discovers adult movies and scenes, sends approved requests to Whisparr v3, and connects users to Jellyfin playback. Boudoirr selects Cruisarr and Jellyfin by default; you can remove either service in the CLI or interactive picker.

Use this guide to generate Boudoirr, complete Cruisarr setup, and maintain its application data.

## Before you start

You need:

- An AMD64 or ARM64 host. The Cruisarr image does not support ARMv7.
- Access to the private Cruisarr repository and its GitHub Container Registry (GHCR) package. The [authentication procedure](#authenticate-and-select-the-image) uses an account with package access and a personal access token (classic) with `read:packages`.
- A Jellyfin server, its API key, and an account that can access the intended libraries. Jellyfin provides owner setup and user authentication; Plex alone cannot provide that login.
- Whisparr v3 and its API key to fulfill requests. Whisparr and Jellyfin can run in this project or on another reachable host.
- Credentials for the metadata providers you select in Cruisarr. TMDB movie discovery requires a TMDB API read access token; scenes use StashDB.

The examples use Boudoirr. For another preset, replace `boudoirr` in commands and paths with your preset ID.

Run commands from the Plundarr repository root. Set `MARAUDARR_IMAGE` to the [source-built generator](../development/maraudarr/index.md#choose-the-generator-revision) for this checkout before generating a project.

## Select the services

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

To omit both companions, use `REMOVE_SERVICES=cruisarr,jellyfin`. Other presets can select either service through `ADD_SERVICES` or `make configure`. Include your complete service selection whenever you regenerate a project.

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

The base host port is `6699`. Boudoirr adds `10000`, and Custom adds `30000`. Internal service URLs always use the container port. Only `.env` receives generated secrets; `example.env` remains a secret-free reference. Regeneration preserves existing `.env` assignments, including empty values and operator overrides.

The application runs as `DEFAULT_PUID:DEFAULT_PGID` with `DEFAULT_GROUP`, matching other rootless service charts. Set the shared user and group IDs from `id -u` and `id -g` for your host account. Confirm that account can write the selected config directory before launch; startup does not change existing host ownership. The image defaults to UID/GID `10001:10001`, but Plundarr selects the process identity through Compose `user:`. `CRUISARR_UID` and `CRUISARR_GID` are image build arguments, so adding them to the runtime environment does not remap that identity.

Cruisarr does not need media or download mounts; it connects to Whisparr and Jellyfin over the project network. SQLite state uses this host bind mount rather than a named volume or separate database service.

## Authenticate and select the image

The default image is `ghcr.io/scottgigawatt/cruisarr:latest`. Anonymous pulls fail because the package is private. Keep the registry token out of `.env`, Compose files, shell history, and logs.

On the deployment host, run the following command. Enter your GitHub username and use the personal access token as the password. A successful login reports `Login Succeeded`.

```sh
docker login ghcr.io
```

Synology Container Manager must also have authenticated access to `ghcr.io` when it pulls the project. A login on your workstation does not authenticate the NAS. See [Cruisarr's private-image guide](https://github.com/scottgigawatt/cruisarr/blob/main/docs/operations/private-images.md) for package requirements.

The Compose chart uses `${CRUISARR_IMAGE}:${CRUISARR_TAG}`. Keep the repository and tag separate in `dist/boudoirr/.env`; do not put a tag or digest in `CRUISARR_IMAGE`. Publication provides `latest` and commit-specific `sha-` tags. The [Cruisarr v0.39.4 release](https://github.com/scottgigawatt/cruisarr/releases/tag/v0.39.4) also has a verified `v0.39.4` image tag. For example, these assignments select its published source revision:

```sh
CRUISARR_IMAGE="ghcr.io/scottgigawatt/cruisarr"
CRUISARR_TAG="sha-c01d10b30c35d8e73720ff6e9dc254048a4e92de"
```

Regeneration preserves your image assignments. To update an existing installation, follow [Update Cruisarr](#update-cruisarr) after creating a backup.

## Configure browser access

Set `CRUISARR_ORIGIN` in `.env` when using a reverse proxy. It accepts one exact browser origin: the scheme, hostname or IP address, and a nonstandard port if needed. Omit paths, queries, and trailing slashes. Replace the example address with the one you open:

```sh
CRUISARR_ORIGIN="https://cruisarr.example.com"
```

For direct private-network HTTP, an example origin is `http://192.168.1.210:16699`. For a Synology HTTPS reverse proxy, forward to host port `16699` and pass `X-Forwarded-Proto: https`.

Keep `CRUISARR_ALLOW_HTTP=1` when Whisparr or Jellyfin connections use private HTTP. Set it to `0` only when those non-loopback connections use HTTPS. The saved **Allow private HTTP** choice in Cruisarr overrides this environment fallback for outgoing connections.

After changing `.env` for a running container, recreate it with `docker compose --project-directory dist/boudoirr up -d cruisarr`. A restart alone does not reload its environment.

## Launch and complete setup

1. Start the generated project:

    ```sh
    make up PRESET=boudoirr
    ```

2. Open your host address on port `16699`, or the configured HTTPS reverse proxy. Read `CRUISARR_SETUP_SECRET` locally from `dist/boudoirr/.env` and supply it during owner setup.
3. Connect Jellyfin using your account, API key, and selected adult-media libraries. Use `http://jellyfin:8096` for a Jellyfin container in this project. For a separate server, use an address reachable from the Cruisarr container.
4. Set Jellyfin's external URL to the address users open in their browsers. An internal Docker hostname is not a browser playback address.
5. Connect Whisparr v3 at `http://whisparr:6969` with its API key. Select the movie provider configured in that Whisparr instance.
6. Configure credentials for each selected metadata provider in Cruisarr settings.

### Configure Whisparr libraries

Cruisarr supports TPDB and TMDB movies, StashDB scenes, and multiple Whisparr connections. If you select the optional [Whisparr Alt service](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/whisparr-alt/README.md), connect it at `http://whisparr-alt:6969` with its own API key. Either instance can handle either movie provider.

Assign each connection the movie provider configured in its Whisparr instance. Choose a default instance for scenes, then set root folders, quality profiles, and path mappings separately for movies and scenes. With this chart, the Whisparr root is `/data` and folder-format prefixes are `movies/` and `scenes/`.

Whisparr mounts individual libraries beneath `/data`; Jellyfin mounts the whole media root. Use these mappings with the default host mounts, and review them whenever you change host paths:

| Library | Whisparr path | Jellyfin path |
| --- | --- | --- |
| Main movies | `/data/movies` | `/data/movies/main` |
| Main scenes | `/data/scenes` | `/data/scenes/main` |
| Alt movies | `/data/movies` | `/data/movies/alt` |
| Alt scenes | `/data/scenes` | `/data/scenes/alt` |

Host directory names do not select metadata providers. See [Cruisarr connection setup](https://github.com/scottgigawatt/cruisarr/blob/main/docs/operations/setup-and-configuration.md#tmdb-movies-and-multiple-whisparr-connections) for the application settings.

### Verify setup

1. Check that Cruisarr reports `healthy`:

    ```sh
    make ps PRESET=boudoirr
    ```

2. Admit the intended Jellyfin users in Cruisarr and test their sign-in.
3. Check saved provider connections and submit representative movie and scene requests. Confirm that each request reaches the intended Whisparr instance and appears in the expected Jellyfin library after fulfillment.

The `/api/status` healthcheck confirms application storage access. It does not verify owner setup, sign-in, or provider connections. If Cruisarr stays unhealthy, check that the configured host identity can write `CRUISARR_CONFIG_PATH` and inspect the container logs locally. Redact secrets and private details before sharing logs.

If pulling reports `unauthorized` or `denied`, check package access and registry authentication on the deployment host. If no matching manifest exists, check the host architecture and selected tag. An origin error during setup requires `CRUISARR_ORIGIN` to match the browser address. `localhost` in a service connection refers to the Cruisarr container, not your host.

## Connect Homepage

When Homepage and Cruisarr are selected together, Maraudarr seeds a link card. `HOMEPAGE_VAR_CRUISARR_HREF` defaults to `http://host.or.ip:${CRUISARR_WEBUI_PORT}` and follows the published host port, including preset offsets and overrides. Replace `host.or.ip` with your browser-accessible hostname or set the full HTTPS URL in `.env`.

Maraudarr refreshes its generated `config/homepage/services.yaml` from the selected service charts during regeneration. Existing Homepage settings and environment values are preserved; edit the source fragment if you customize generated cards. This card is a link; it does not require an API key or assume compatibility with Seerr's widget.

## Update Cruisarr

Cruisarr is excluded from Watchtower updates because the shared Watchtower service has no private-registry credentials. Use an authenticated deployment account for intentional updates.

1. [Back up the configured data directory](#back-up-and-recover) and retain its encryption key. Review the selected image's release notes and storage requirements.
2. If selecting another image tag, update `CRUISARR_IMAGE` and `CRUISARR_TAG` in `dist/boudoirr/.env`.
3. Pull and recreate only Cruisarr:

    ```sh
    docker compose --project-directory dist/boudoirr pull cruisarr
    docker compose --project-directory dist/boudoirr up -d cruisarr
    ```

4. Repeat [setup verification](#verify-setup), including sign-in, saved connections, and request fulfillment.

## Back up and recover

> [!IMPORTANT]
> Keep an off-host copy of `CRUISARR_SECRET_KEY` with every backup. Losing the matching key prevents recovery of encrypted credentials.

`make backup PRESET=boudoirr` archives `dist/boudoirr/config` by default. It excludes `.env` and any data outside that tree. If `CRUISARR_CONFIG_PATH` points elsewhere, archive that host directory separately. Other applications and named volumes need their own consistent backup methods.

### Create a stopped-container backup

Stopping Cruisarr makes its database files safe to copy. It does not make the other applications in a host config archive consistent. Include the complete Cruisarr data directory, including any SQLite journal or write-ahead log files.

1. Stop Cruisarr:

    ```sh
    docker compose --project-directory dist/boudoirr stop cruisarr
    ```

2. For data inside the default config tree, create the archive:

    ```sh
    make backup PRESET=boudoirr
    ```

    For an external data directory, replace `/PATH/TO/CRUISARR-DATA` with the host directory configured by `CRUISARR_CONFIG_PATH`:

    ```sh
    make backup PRESET=boudoirr CONFIG_PATH="/PATH/TO/CRUISARR-DATA"
    ```

3. Start Cruisarr again, including after an unsuccessful backup attempt:

    ```sh
    docker compose --project-directory dist/boudoirr start cruisarr
    ```

4. Confirm that the backup command succeeded and the reported archive under `dist/boudoirr/backups` contains the Cruisarr data directory and database. Retain an off-host copy with the matching encryption key. If the backup failed, investigate the error and repeat this procedure before treating the archive as a recovery copy.

### Restore into fresh storage

Keep the current data directory and its encryption key until you have verified recovery. Do not extract a backup over a running database or overwrite existing application state.

1. Stop the target Cruisarr container.
2. Extract the backed-up Cruisarr data into a fresh directory, preserving any SQLite companion files from the stopped-container archive.
3. In `.env`, point `CRUISARR_CONFIG_PATH` at that directory and restore the matching `CRUISARR_SECRET_KEY`. Give the configured host user and group write access to the directory.
4. Recreate Cruisarr with `docker compose --project-directory dist/boudoirr up -d cruisarr`.
5. Verify health, sign-in, saved connections, and requests before returning the service to users.

For an online SQLite snapshot, follow [Cruisarr backup and recovery](https://github.com/scottgigawatt/cruisarr/blob/main/docs/operations/setup-and-configuration.md#backup-and-recovery). Restore that snapshot as `cruisarr.sqlite` in fresh storage with its matching key.

`make down`, `make nuke`, and regeneration preserve bind-mounted application state. `make delete-config` deletes the selected host config tree, including Cruisarr data and backups stored inside it. A `CRUISARR_CONFIG_PATH` outside that tree is not deleted by this target. Keep recovery copies outside the config tree and off the deployment host.
