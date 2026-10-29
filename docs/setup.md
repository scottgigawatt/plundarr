# Set up Plundarr with Docker or Synology ⚓

This guide generates a Plundarr deployment, reviews the host-specific settings, and launches the resulting one-file Docker Compose project with Docker Compose or Synology Container Manager.

## Generate a deployment

Install the prerequisites in the [repository README](https://github.com/scottgigawatt/plundarr#readme) and run commands from the cloned repository root. These instructions target the checkout's catalog and seeds. Build and select its generator through [generator revision selection](development/maraudarr/index.md#choose-the-generator-revision); keep `MARAUDARR_IMAGE` set to that reference for the generation commands on this page.

Run the interactive Maraudarr Docker Compose project generator:

```sh
make configure
```

For non-interactive generation, use `make ship PRESET=YOUR-PRESET`, replacing `YOUR-PRESET` with an ID from `make presets`. Add or remove comma-separated service IDs with `ADD_SERVICES` or `REMOVE_SERVICES`. For example, a Usenet-only deployment uses:

```sh
make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=sabnzbd
```

Maraudarr writes a complete project beneath `dist/<preset>/`:

```text
dist/<preset>/
├── docker-compose.yml
├── example.env
├── .env
└── config/
```

> [!IMPORTANT]
> Review the generated `.env` before launch. Confirm user and group IDs, host storage paths, timezone, project network values, and published ports. Presets containing Privateerr and Gluetun also require real `PIA_USER` and `PIA_PASS` values; startup rejects missing or generated example credentials.

When regenerating, repeat your complete intended `ADD_SERVICES` and `REMOVE_SERVICES` selection. Each run resolves the requested preset again; preserved environment values and inactive footer assignments do not restore earlier service choices. Generation preserves application state and does not stop running containers omitted from the new chart; review orphaned containers separately.

`.env` selects Compose values and paths; application-specific configuration may also need editing. Jellyfin Web settings and CSS, Recyclarr YAML, and the external Kometa/PATTRMM settings are operator-owned exceptions. Regeneration seeds missing managed files and preserves existing application edits; it does not configure the applications for you.

## Configure Homepage password login

Presets containing Homepage enable its native password login. Maraudarr generates `HOMEPAGE_AUTH_PASSWORD` and `HOMEPAGE_AUTH_SECRET` in `dist/<preset>/.env`, preserving existing values on later runs. Read the password locally from that file; no username is required.

Before launch, set `HOMEPAGE_EXTERNAL_URL` to the URL you will open in your browser and `HOMEPAGE_ALLOWED_HOSTS` to its hostname, including a nonstandard port but omitting the scheme. For a Synology HTTPS reverse proxy, use values such as `https://homepage.example.com` and `homepage.example.com`, configure the certificate and proxy separately, and forward to `HOMEPAGE_WEBUI_PORT`. Recreate Homepage after changing `.env`.

Homepage requires v2 or later for native login. Generated secrets are created when absent and remain stable across regeneration. Homepage does not rate-limit password attempts; public access also needs appropriate proxy access controls and rate limiting, or a VPN. See the generated `config/homepage/README.md` for password changes, session invalidation, and proxy details.

## Add Velvarr to Boudoirr

Boudoirr selects removable Velvarr and Jellyfin companions. Use `REMOVE_SERVICES=jellyfin` for an existing Jellyfin server, `REMOVE_SERVICES=velvarr` to omit requests, or both IDs to omit both. Jellyfin provides Velvarr login; Plex cannot replace it. Follow the [Velvarr setup guide](project-guides/velvarr.md) for architecture support, owner setup, paths, and recovery.

The optional [Whisparr Alt guide](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/whisparr-alt/README.md) covers a second instance. Keep its database, libraries, categories, and API key separate. Movie providers are selected in Whisparr; directory names do not select them.

## Plan project networks

Maraudarr gives each preset a distinct Compose project, bridge network, and default host-port range so fresh deployments can run side by side.

| Preset | Project | Default subnet | Published ports |
| --- | --- | --- | --- |
| Plundarr | `plundarr` | `172.20.0.0/16` | Standard service ports; CWA `8213` |
| Boudoirr | `boudoirr` | `172.21.0.0/16` | Selected ports offset by `10000` |
| Jellyfin | `jellyfin` | `172.22.0.0/16` | Jellyfin `28096` |
| Plex | `plex` | `172.23.0.0/16` | Plex host networking |
| Calibre-Web Automated | `calibre-web-automated` | `172.24.0.0/16` | CWA `48213` |
| Duplex | `duplex` | `172.25.0.0/16` | Themerr HTTPS `9494`, connector HTTP `9495`; Notifiarr `5454` |
| Watchtower | `watchtower` | `172.26.0.0/16` | No published ports |
| Portainer | `portainer` | `172.27.0.0/16` | HTTPS `9443`, Edge `8888` |
| Custom | `custom` | `172.28.0.0/16` | Selected ports offset by `30000` |

Every bridge-network preset uses `.5.0/24` as its container address pool and `.5.254` as its gateway inside the listed `/16`. These are catalog defaults, not reservations for separately deployed applications; check every existing host network before generating another project. Container names include the project, service, and image tag, such as `plundarr-bazarr-latest`.

Change the generated network only when it overlaps another Docker network, virtual private network (VPN), local-area network route, or host service. Update `COMPOSE_NETWORK_SUBNET`, `COMPOSE_NETWORK_IP_RANGE`, and `COMPOSE_NETWORK_GATEWAY` together. The [Docker Compose IPAM reference](https://docs.docker.com/compose/compose-file/06-networks/#ipam) explains custom address planning.

Plex uses host networking. Only one Plex server can claim its standard host ports unless Plex itself is configured differently.

## Launch with Docker Compose

Replace `YOUR-PRESET` with the selected preset ID, such as `boudoirr`, in commands and paths below. Start that generated project through Make:

```sh
make up PRESET=YOUR-PRESET
```

Omit `PRESET` for the default `plundarr` deployment. Validate the Compose model without printing interpolated credentials, then inspect service status:

```sh
docker compose --env-file dist/YOUR-PRESET/.env -f dist/YOUR-PRESET/docker-compose.yml config --quiet
make ps PRESET=YOUR-PRESET
```

## Configure the Synology firewall

If the Synology firewall is enabled, add one allow rule for every deployed preset that uses a bridge network. Plex uses host networking and does not need a preset-subnet rule.

For the default Plundarr network:

1. Open **Control Panel**, then **Security**, then **Firewall**.
2. Select **Edit Rules**, then **Create**.
3. Configure the rule:

    | Setting | Value |
    | --- | --- |
    | Ports | `All` |
    | Source IP | `Specific IP` → `Subnet` |
    | IP address | `172.20.0.0` |
    | Subnet mask | `255.255.0.0` |
    | Action | `Allow` |

4. Select **OK**.
5. Repeat the process for every additional generated bridge subnet.

Use the actual subnet from each preset's `.env`, especially when you changed a generated default. An incorrect firewall source or mask can block internal container traffic.

## Deploy with Synology Container Manager

Plundarr is tested with Container Manager on DSM 7.4. Keep DSM and Container Manager current before deployment.

1. Generate the selected project from the cloned repository.
2. Keep `docker-compose.yml`, `.env`, and `config/` together beneath `dist/<preset>/`.
3. Open **Container Manager**, then **Project**.
4. Select **Create**.
5. Choose the generated `dist/<preset>` directory as the project path.
6. Select `docker-compose.yml` as the Compose file.
7. Review the resolved settings and deploy the project.

The [Synology Container Manager project documentation](https://kb.synology.com/en-id/DSM/help/ContainerManager/docker_project?version=7) describes the surrounding user interface.

## Configure media libraries

Configure libraries in each application after startup; Maraudarr prepares mounts but does not create library records.

- **Jellyfin:** `JELLYFIN_DATA_PATH` mounts read/write at `/data`. Plundarr and standalone libraries normally use `/data/movies` and `/data/tv`; config and cache persist separately.
- **Boudoirr:** Main Whisparr's `/data/movies` and `/data/scenes` correspond to Jellyfin's `/data/movies/main` and `/data/scenes/main`. Alt uses the matching `/alt` directories. Keep import/recycle directories out of media libraries and review mappings after host-path changes.
- **Plex:** Media mounts are read-only. Plundarr exposes movies, television, and anime; Boudoirr exposes movies and scenes; standalone Plex exposes movies and television. Config and transcode paths persist separately, and Plex uses host networking.
- **Calibre-Web Automated:** `CWA_LIBRARY_PATH` mounts at `/calibre-library` and must contain `metadata.db`. Configuration, destructive ingest, and the library use separate host paths; follow the preparation below.

When Lidarr is selected, its `HOST_MUSIC_PATH` mounts read/write at `/music`; use that root in Lidarr. Plex receives the same library read-only at `/music`. Jellyfin gets no additional music bind: it can see that library only if its host directory is beneath `JELLYFIN_DATA_PATH`. Align those paths deliberately.

## Customize Jellyfin playback

Boudoirr and standalone Jellyfin can add the optional Vue client with `ADD_SERVICES=jellyfin-vue`. Jellyfin Web also receives a configurable read-only settings file and local CSS directory. Read the [Jellyfin customization guide](project-guides/jellyfin.md) for client URLs, theme activation, menu links, image compatibility, and plugin choices.

## Configure Lidarr

Select `ADD_SERVICES=lidarr`, set `HOST_MUSIC_PATH` to the host library, and configure `/music` as Lidarr's root folder after launch. Connect Prowlarr and a downloader; set `HOMEPAGE_VAR_LIDARR_KEY` if using the widget. Plex receives the same host library read-only when selected; Jellyfin sees it only when it is beneath `JELLYFIN_DATA_PATH`, as described above. The [Lidarr chart](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/lidarr/README.md) records image/architecture limits.

## Preview and sync Recyclarr

Generate Plundarr with Recyclarr, then set API access for the in-stack Radarr and Sonarr instances. Selecting Recyclarr adds both services and their indexing chain when the preset does not already contain them:

```sh
make ship ADD_SERVICES=recyclarr
```

| Setting | Purpose |
| --- | --- |
| `RECYCLARR_RADARR_URL` | Radarr base URL; defaults to the in-stack service |
| `RECYCLARR_RADARR_API_KEY` | Radarr API key required before synchronization |
| `RECYCLARR_SONARR_URL` | Sonarr base URL; defaults to the in-stack service |
| `RECYCLARR_SONARR_API_KEY` | Sonarr API key required before synchronization |
| `RECYCLARR_CONFIG_PATH` | Regeneration-safe Recyclarr configuration and cache directory |

Maraudarr seeds `config/recyclarr/recyclarr.yml` once. The starter syncs upstream quality-size definitions only, preserves existing custom formats, and can be extended with the templates and profiles appropriate for the library.

Preview and apply Recyclarr through separate profile-aware targets:

```sh
make recyclarr-preview PRESET=plundarr
make recyclarr-sync PRESET=plundarr
```

> [!CAUTION]
> The sync target changes the configured Radarr and Sonarr instances. Confirm the URLs, API keys, configuration, and preview output before running it. Ordinary `make up` does not start Recyclarr.

See the official [Recyclarr feature reference](https://recyclarr.dev/guide/features/) and [`sync` command reference](https://recyclarr.dev/cli/sync/) before adding custom formats, quality profiles, naming rules, or additional instances.

## Configure Calibre-Web Automated

Plundarr includes Calibre-Web Automated as a removable default. Generate it alone when the ebook library should have its own Compose project, network, and host port:

```sh
make ship PRESET=calibre-web-automated
make up PRESET=calibre-web-automated
```

Review these values in the selected preset's `.env`:

| Setting | Purpose |
| --- | --- |
| `CWA_WEBUI_PORT` | Host port for the web interface; `8213` in Plundarr and `48213` standalone |
| `CWA_CONFIG_PATH` | Persistent users, settings, logs, plugins, and application databases |
| `CWA_INGEST_PATH` | Temporary import directory whose files CWA removes after processing |
| `CWA_LIBRARY_PATH` | Calibre library containing `metadata.db` and managed ebook files |
| `CWA_NETWORK_SHARE_MODE` | Use `true` only for NFS or SMB storage; keep `false` for local Synology volumes |

> [!CAUTION]
> Keep the config, ingest, and library paths as three separate directories. Never use an active download directory as the ingest path, and never place incomplete downloads there. Back up the complete config directory and Calibre library before updating CWA or changing its storage.

The default Plundarr Homepage card uses CWA's native widget. Replace `HOMEPAGE_VAR_CWA_USER` and `HOMEPAGE_VAR_CWA_PASS` with a CWA account in the generated `.env` to enable book, author, and series counts.

CWA is excluded from unattended Watchtower updates so application image changes remain a deliberate operator action. Its published image supports `linux/amd64` and `linux/arm64`, not `linux/arm/v7`.

See the [Calibre-Web Automated project](https://github.com/crocodilestick/Calibre-Web-Automated) for application-level setup and the [Homepage Calibre-Web widget guide](https://gethomepage.dev/widgets/services/calibre-web/) for dashboard integration details.

## Configure Duplex services

Generate Duplex and review `dist/duplex/.env`:

```sh
make ship PRESET=duplex
```

Prepare the external Kometa checkout selected by `KOMETA_CONFIG_PATH`; Maraudarr does not clone or replace it. Kometa and PATTRMM share its private runtime YAML. Follow the [Kometa chart](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/kometa/README.md) for overrides and [PATTRMM Neo chart](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/pattrmm/README.md) for settings, rootless cache/output permissions, and scheduling. Neo must finish generating collections before Kometa reads them; the [companion configuration](https://github.com/scottgigawatt/kometa-config) owns collection behavior.

Set `IMAGEMAID_PLEX_PATH` to Plex application data containing `Cache`, `Metadata`, and `Plug-in Support`. Begin ImageMaid in report mode. Prepare Themerr's separate encryption key and writable state, then complete [administrator and connector setup](project-guides/themerr.md). Keep the key with application backups; fresh settings disable cleanup and automatic Jellyfin restarts.

After preparing required paths, start persistent services with `make up PRESET=duplex`. Overlay Reset is an opt-in service selected with `ADD_SERVICES=overlay-reset`; its `tools` profile keeps it out of normal startup.

> [!CAUTION]
> Overlay Reset is destructive and has no undo. Back up posters, confirm the Plex URL, token, and library, keep `OVERLAY_RESET_DRY_RUN=True`, and inspect output before deliberately setting it to `False`.

Invoke it explicitly:

```sh
make kometa-overlay-reset PRESET=duplex
```

## Configure Watchtower

Use the standalone `watchtower` preset or add `watchtower` to another preset. Plundarr and Boudoirr include it as a removable default; Duplex does not. The [Watchtower chart](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/watchtower/README.md) covers persistent startup and one-shot updates.

Watchtower controls the host Docker daemon and may update eligible containers outside its own Compose project. Run only one persistent daemon per host and stop it before a one-shot pass. Containers labelled `com.centurylinklabs.watchtower.enable=false` stay excluded.

## Continue the voyage

- Use the [root README on GitHub](https://github.com/scottgigawatt/plundarr/blob/main/README.md) for preset selection and common commands.
- Use the [host script guide](project-guides/scripts.md) for Synology and Linux helpers.
- Use the [testing guide](project-guides/testing.md) before running credential-backed VPN or stack tests.
- Use the [support guide](SUPPORT.md) when setup does not behave as documented.

Fair winds, sensible subnets, and no surprise port collisions. 🏴‍☠️
