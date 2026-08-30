# Plundarr Docker Setup Guide ⚓🐳🏴‍☠️

Avast ye! This guide rigs a Docker Compose fleet with PIA WireGuard and port
forwarding. Plundarr is tested on Synology DiskStations running DSM
7.4.1-90080 and on macOS Tahoe 26; compatible Linux Docker hosts can sail by
the same chart. 🏴‍☠️

## Choose Yer Voyage 🧭

Run the interactive generator from the cloned repository:

> [!TIP]
>
> ```sh
> make configure
> ```

Or generate a known voyage directly:

> [!TIP]
>
> ```sh
> make ship
> make ship PRESET=boudoirr ADD_SERVICES=jellyfin
> make ship PRESET=jellyfin
> make ship PRESET=plex
> make ship PRESET=watchtower
> make ship ADD_SERVICES=sonarr-anime
> ```

Plundarr and Boudoirr use qBittorrent as their only default downloader.
SABnzbd, NZBGet, and Watchtower remain optional choices. Use
`ADD_SERVICES` and `REMOVE_SERVICES` for repeatable changes:

For Usenet only, remove the default torrent client and its cleanup companion.
To keep torrents and add Usenet plus update checks, leave the defaults intact:

> [!TIP]
>
> ```sh
> make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=sabnzbd
> make ship PRESET=boudoirr ADD_SERVICES=sabnzbd,watchtower
> ```

Default Plundarr includes one Sonarr instance for television. The separate
Sonarr Anime instance appears only when selected through `make configure` or `ADD_SERVICES=sonarr-anime`.

Maraudarr generates each voyage using the following directory structure:

- `dist/<preset>/docker-compose.yml`
- `dist/<preset>/example.env`
- `dist/<preset>/.env`
- `dist/<preset>/config/` (selected service directories)

Review that preset's `.env` before launch, especially user IDs, host paths, timezone, network values, and PIA credentials when the voyage includes Privateerr and Gluetun. Startup stops with a corrective message when resolved `PIA_USER` or `PIA_PASS` values are missing or still use Maraudarr's generated examples.

## Chartin' the Docker Network Waters 🌍🧭

Maraudarr assigns each preset a distinct Docker IPAM network. Most captains do
not need to change these values.

Fresh presets receive distinct project and network defaults:

| Preset     | Project      | Subnet          | Published Ports                          |
| ---------- | ------------ | --------------- | ---------------------------------------- |
| Plundarr   | `plundarr`   | `172.28.0.0/16` | Standard service ports                   |
| Boudoirr   | `boudoirr`   | `172.29.0.0/16` | Selected service ports offset by `10000` |
| Jellyfin   | `jellyfin`   | `172.30.0.0/16` | Jellyfin `28096` (`8096` + `20000`)      |
| Plex       | `plex`       | `172.31.0.0/16` | Plex host networking                     |
| Watchtower | `watchtower` | `172.25.0.0/16` | No published ports                       |
| Custom     | `custom`     | `172.27.0.0/16` | Selected service ports offset by `30000` |

Container names include the project, service, and image tag, such as
`plundarr-bazarr-latest`. The default Plundarr, default Boudoirr, standalone
Jellyfin, standalone Plex, and standalone Watchtower voyages can therefore run
side by side without sharing container names, subnets, or published ports. The
host-port bands retain the familiar tail of common ports: qBittorrent is `8080`
for Plundarr and `18080` for Boudoirr. Existing values in a preset's `.env`
remain preserved during regeneration, so review and change older project names,
network values, or ports before placing an existing deployment beside another
preset.

Change the generated values whenever they overlap another Docker network, VPN,
LAN route, or host service. When a collision exists, update
`COMPOSE_NETWORK_SUBNET`, `COMPOSE_NETWORK_IP_RANGE`, and
`COMPOSE_NETWORK_GATEWAY` together in that preset's `.env`; otherwise keep the
generated defaults. See the [Docker Compose IPAM documentation](https://docs.docker.com/compose/compose-file/06-networks/#ipam)
for custom network planning. Plex uses host networking, so only one Plex server
can claim its standard host ports unless Plex itself is configured differently.

## Watchtower Update Modes 🔭

Use Watchtower as an optional persistent service in another preset, or generate
its focused standalone project:

> [!TIP]
>
> ```sh
> make ship ADD_SERVICES=watchtower
> make ship PRESET=watchtower
> make up PRESET=watchtower
> ```

The standalone project can instead perform one update pass and exit:

> [!TIP]
>
> ```sh
> make watchtower-run-once PRESET=watchtower
> ```

> [!WARNING]
> Watchtower controls the host Docker daemon through its socket. By default it
> examines eligible running and stopped containers across that Docker host, not
> only services in the generated Compose project. Containers labeled
> `com.centurylinklabs.watchtower.enable=false` remain excluded. Run one
> persistent Watchtower daemon per host and stop it before a one-shot pass.

## Batten Down the Hatches 🖥️⚓

Fer them sailin' with Synology DiskStations, here be the riggin' details ye need!

### Guardin' the Ship 🔥🛡️

> [!WARNING]
> 🏴‍☠️ Misfirin' yer firewall could leave yer crew stranded! Double-check them source IPs and subnet details before ye weigh anchor.

If the Synology firewall is enabled, add one allow rule for every deployed
preset that uses a bridge network. One Plundarr deployment needs one rule;
deploying Plundarr, Boudoirr, and Jellyfin side by side needs three rules. Plex
uses host networking and does not need a preset-subnet rule.

Use the subnet from that preset's generated `.env`. For the default Plundarr
voyage:

1. Open **Control Panel** → **Security** → **Firewall**.
2. Select **Edit Rules**, then select **Create**.
3. Configure the rule with these values:

   | Setting     | Value                    |
   | ----------- | ------------------------ |
   | Ports       | `All`                    |
   | Source IP   | `Specific IP` → `Subnet` |
   | IP address  | `172.28.0.0`             |
   | Subnet mask | `255.255.0.0`            |
   | Action      | `Allow`                  |

4. Select **OK** to save the rule.

Repeat the rule with `172.29.0.0` for Boudoirr, `172.30.0.0` for standalone
Jellyfin, or the generated subnet for a custom voyage. Every listed preset uses
the `255.255.0.0` mask by default. These rules allow internal container traffic
while Gluetun carries selected downloader traffic through PIA.

### Launchin' Yer Fleet 📦🚀

> [!NOTE]
> 📜 Plundarr is tested with Container Manager on DSM 7.4.1-90080. Keep DSM and
> Container Manager current before launching the fleet.

To deploy a project using Synology Container Manager:

1. Log in to the Synology DSM web interface.
2. Run `make configure` from the cloned repository to chart the selected
   `dist/<preset>/docker-compose.yml`, `.env`, and `config/` directories.
3. Open **Container Manager**, then open the **Project** tab.
4. Select **Create** and use these values:

   | Setting      | Value                                  |
   | ------------ | -------------------------------------- |
   | Project name | For example, `plundarr`                |
   | Project path | The selected `dist/<preset>` directory |
   | Compose file | `docker-compose.yml`                   |

5. Review the settings and deploy the project.

Refer to the [official Synology documentation](https://kb.synology.com/en-id/DSM/help/ContainerManager/docker_project?version=7) for further details.

## Jellyfin and Plex Libraries 🎞️

| Server                               | Host mount behavior                                                            | Libraries to add               | Notes                                                                         |
| ------------------------------------ | ------------------------------------------------------------------------------ | ------------------------------ | ----------------------------------------------------------------------------- |
| Jellyfin with Plundarr or standalone | `JELLYFIN_DATA_PATH` mounts read/write at `/data`                              | `/data/movies`, `/data/tv`     | Persistent `/config` and `/cache`; logs stay under `/config/log`.             |
| Jellyfin with Boudoirr               | The shared Whisparr/Jellyfin high-level data root mounts read/write at `/data` | `/data/movies`, `/data/scenes` | Set `WHISPARR_DATA_PATH` and `JELLYFIN_DATA_PATH` to the same host directory. |
| Plex with Plundarr                   | Separate read-only library mounts                                              | Movies, TV, anime              | Plex also has persistent config and transcode mounts.                         |
| Plex with Boudoirr                   | Separate read-only library mounts                                              | Movies, scenes                 | Choose Plex explicitly; it is not included by default.                        |
| Plex standalone                      | Separate read-only library mounts                                              | Movies, TV                     | Uses host networking.                                                         |

---

These secrets should have ye sailin' smooth seas 🚢 — may yer containers stay hearty 🏴‍☠️ and yer logs whisper like the calm before a storm 🌊. Fair winds and followin' seas, matey! 🐳🏴‍☠️
