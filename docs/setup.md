# Set up Plundarr with Docker or Synology ⚓

Generate the default Plundarr stack, edit its settings, and open the running applications. You need Docker with Compose, an amd64 or arm64 Docker host, a PIA subscription, and writable host storage. Run the commands in a terminal on the Docker host; macOS Docker Desktop must have access to the storage directories you select.

## Generate a deployment

Create a working directory and open the published Maraudarr image:

```sh
mkdir -p plundarr
cd plundarr
docker run --rm -it --pull always \
  --user "$(id -u):$(id -g)" \
  --read-only --network none \
  --cap-drop ALL --security-opt no-new-privileges:true \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  --volume "$PWD:/output:rw" \
  ghcr.io/scottgigawatt/maraudarr:latest configure
```

Choose **Plundarr** and keep the default services. Use the arrow keys to move, Space to toggle optional services, and Enter to continue. Git and Make are optional shortcuts, covered in [customization](customize.md).

The generated project is self-contained:

```text
dist/plundarr/
├── docker-compose.yml
├── .env
├── example.env
└── config/
```

Keep these files and directories together. Edit `.env`; `example.env` is a reference without working generated passwords. Maraudarr generates files and exits. The Compose commands below start the applications.

## Review the settings

Open `dist/plundarr/.env` in a text editor. Start with these settings; the `Edit before launch` and `Edit for your host` comments help identify values that need your attention.

| Settings | What to do |
| --- | --- |
| `PIA_USER`, `PIA_PASS` | Enter your PIA VPN username and password. The username is `p` or `P` followed by seven digits, not an email address. |
| `DEFAULT_PUID`, `DEFAULT_PGID`, `DEFAULT_GROUP` | Match the host user/group that owns storage and any required additional group. Run `id` to see your numeric IDs and group memberships. |
| `TZ` | Set your timezone, such as `America/New_York`. |
| `HOST_*_PATH` | Choose real absolute host paths. Keep torrents and Usenet directories beneath the shared downloads root. |
| Service config/library paths | Confirm every selected service can access its configured directories. |
| `HOMEPAGE_EXTERNAL_URL` | Set the full address you will open, such as `http://192.0.2.10:3000`, using your host's real address. |
| `HOMEPAGE_ALLOWED_HOSTS` | Set the matching host and port without the scheme, such as `192.0.2.10:3000`. |
| `HOMEPAGE_VAR_*_HREF` | Replace `host.or.ip` with browser-accessible service addresses so dashboard links work. |
| `COMPOSE_NETWORK_*`, `*_WEBUI_PORT` | Change only to avoid an existing route or port conflict; see [network planning](customize.md#plan-project-networks). |

Keep generated passwords and API keys in the private `.env`. Homepage uses `HOMEPAGE_AUTH_PASSWORD`; Privateerr and Gluetun share the generated recovery API key. Do not put `.env`, VPN files, or logs containing private values in Git or public support reports.

Create the host directories you selected and grant the configured numeric identity access. Docker Desktop also needs permission to share them. Do not change ownership of an existing library indiscriminately.

The default Calibre-Web Automated service needs separate config, ingest, and library directories. For a new library, choose an empty writable directory; CWA creates and registers the library on startup. To use an existing Calibre library, select its directory containing `metadata.db`. See the [CWA storage instructions](https://github.com/crocodilestick/Calibre-Web-Automated/blob/main/README.md#explanation-of-the-container-bindings). CWA removes files from its ingest directory after processing: use completed books only, never an active downloads directory. Keep `CWA_NETWORK_SHARE_MODE=false` for local disks and use `true` for NFS/SMB storage.

Watchtower is selected by default and can update eligible containers across the Docker host. Run one persistent Watchtower instance per host; deselect it if you already have one. The [Watchtower chart](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/watchtower/README.md) explains its scope and exclusions.

Using Synology? [Configure its firewall](#configure-the-synology-firewall) before launch, then choose the Compose procedure below or [Container Manager](#deploy-with-synology-container-manager).

## Launch with Docker Compose

From the directory where you ran Maraudarr, enter the generated project:

```sh
cd dist/plundarr
docker compose config --quiet
```

A successful validation produces no output. Correct any reported settings or syntax errors before starting. This checks the Compose configuration; it does not check storage permissions or establish a VPN connection.

Start and inspect the stack:

```sh
docker compose up --detach --pull always
docker compose ps
```

The first run downloads images and may take several minutes. Check Privateerr's startup readiness first, Gluetun's healthy VPN connection second, and qBittorrent third. The Privateerr container generates the PIA WireGuard configuration file; the Gluetun VPN container carries VPN traffic. Other applications have their own startup dependencies.

## Open your applications

Use your Docker host's address and the ports in `.env`. Use `localhost` only when your browser is on that host.

| Application | Default port | First action |
| --- | --- | --- |
| Homepage | `3000` | Sign in with `HOMEPAGE_AUTH_PASSWORD` from `.env`; no username is required. |
| qBittorrent | `8080` | Use the initial administrator credentials reported in its local logs, then change the password. |
| Prowlarr | `9696` | Finish its initial setup and configure your indexers. |
| Radarr | `7878` | Finish initial setup and use `/movies` for the movie root. |
| Sonarr | `8989` | Finish initial setup and use `/tv` for the television root. |
| Calibre-Web Automated | `8213` | Complete library setup using `/calibre-library` and change the initial login. |

Read qBittorrent's initial password locally:

```sh
docker compose logs qbittorrent
```

Keep that output private. Homepage widget API keys are optional for initial access; configure them after the applications work. Follow the generated `config/homepage/README.md` for login and link settings. Protect public access with appropriate proxy controls or a VPN; Homepage does not rate-limit login attempts itself.

You have completed basic startup when the VPN is healthy, Homepage accepts the generated password, and qBittorrent opens. Continue with [connect your applications](https://scottgigawatt.github.io/plundarrpedia/projects/plundarr/connect-applications/) to link the downloader, indexers, and media managers.

## If startup fails

From the generated directory, use `docker compose ps` to find the affected service. Read its logs locally with `docker compose logs SERVICE`, replacing `SERVICE` with its name. Resolve PIA credential/VPN errors before troubleshooting qBittorrent; check host paths and ownership for permission errors. Keep the full logs private and sanitize any excerpt before asking for [support](SUPPORT.md).

For region selection and automatic recovery, use the [VPN guide](project-guides/vpn.md). For a planned shutdown, run `docker compose down`; it preserves images and volumes. Read [maintenance](maintain.md) before updating or resetting anything.

## Configure the Synology firewall

Plundarr supports Container Manager on DSM 7.4. When its firewall is enabled, allow the generated bridge subnet before launch. In **Control Panel → Security → Firewall → Edit Rules → Create**, allow all ports from the preset subnet. For default Plundarr, the source is `172.20.0.0` with mask `255.255.0.0`. Use the actual subnet from `.env` when customized; repeat for each bridge-network preset. Plex uses host networking.

## Deploy with Synology Container Manager

After reviewing settings, preparing directories, and configuring the firewall:

1. Keep `docker-compose.yml`, `.env`, and `config/` together in the generated preset directory on the NAS.
2. Open **Container Manager → Project → Create**.
3. Select that directory as the project path and select `docker-compose.yml`.
4. Review settings and deploy. Check container status and follow [Open your applications](#open-your-applications).

The [Synology project documentation](https://kb.synology.com/en-id/DSM/help/ContainerManager/docker_project?version=7) describes the surrounding interface. Use either Container Manager or the Compose launch procedure to manage a project.

<a id="add-cruisarr-to-boudoirr"></a>
<a id="choose-boudoirr-companions"></a>
<a id="plan-project-networks"></a>
<a id="configure-media-libraries"></a>
<a id="customize-jellyfin-playback"></a>
<a id="configure-lidarr"></a>
<a id="preview-and-sync-recyclarr"></a>
<a id="configure-calibre-web-automated"></a>
<a id="configure-duplex-services"></a>
<a id="configure-watchtower"></a>

For host preparation and coordinated stack startup after a reboot, follow the [Synology boot-task guide](project-guides/scripts.md#create-a-synology-boot-task).

## Customize further

Use [customization](customize.md) to select services, plan networks, configure libraries, and prepare optional integrations. Service-specific instructions are listed in the [service guides](project-guides/index.md).
