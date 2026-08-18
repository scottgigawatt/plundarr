# Plundarr Docker Setup Guide ⚓🐳🏴‍☠️

Avast ye! This here be the guide for riggin' up yer Docker Compose fleet with PIA WireGuard and port-forwarding support. It covers the treacherous waters of Synology DiskStations with DSM 7.2 or later, but landlubbers usin' Linux and macOS can sail by these charts too! 🏴‍☠️

## Choose Yer Voyage 🧭

Run the interactive generator from the cloned repository:

```bash
make configure
```

Or generate a known voyage directly:

```bash
make ship
make ship PRESET=boudoirr ADD_SERVICES=jellyfin
make ship PRESET=jellyfin
make ship PRESET=plex
make ship ADD_SERVICES=sonarr-anime
```

Plundarr and Boudoirr use qBittorrent as their only default downloader.
SABnzbd, NZBGet, and Watchtower remain optional choices. Use
`ADD_SERVICES` and `REMOVE_SERVICES` for repeatable changes:

```bash
# Usenet only
make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=sabnzbd

# Torrents and Usenet, with optional update checks
make ship PRESET=boudoirr ADD_SERVICES=sabnzbd,watchtower
```

Default Plundarr includes one Sonarr instance for television. The separate
Sonarr Anime instance appears only when selected through `make configure` or
`ADD_SERVICES=sonarr-anime`.

Maraudarr writes `docker-compose.yml`, `example.env`, `.env`, and the selected
service directories under `config/`. Review `.env` before launch, especially
user IDs, host paths, timezone, network values, and PIA credentials when the
voyage includes Privateerr and Gluetun.

## Chartin' the Docker Network Waters 🌍🧭

> [!IMPORTANT]
> ⚓️ Set yer IPAM settings right in `.env` before settin' sail, or ye'll find yerself adrift in a sea of network woes!

Docker IPAM (IP Address Management) lets ye carve out yer own slice of the subnet seas, makin' yer fleet easier to command and troubleshoot 🛠️.

Update these settings in yer generated `.env` file:

```bash
#
# Broad waters fer the subnet (Subnet range: 172.28.0.1 - 172.28.255.254)
# Chart mask: 255.255.0.0
#
COMPOSE_NETWORK_SUBNET="${COMPOSE_NETWORK_SUBNET:-172.28.0.0/16}"

#
# Where the crew drops anchor (IP range fer containers: 172.28.5.1 - 172.28.5.254)
# Chart mask: 255.255.255.0
#
COMPOSE_NETWORK_IP_RANGE="${COMPOSE_NETWORK_IP_RANGE:-172.28.5.0/24}"

#
# Gateway to the open seas (Network gateway IP address)
#
COMPOSE_NETWORK_GATEWAY="${COMPOSE_NETWORK_GATEWAY:-172.28.5.254}"
```

For detailed documentation, refer to the [Docker Compose IPAM documentation](https://docs.docker.com/compose/compose-file/06-networks/#ipam).

Fresh presets receive distinct project and network defaults:

<!-- markdownlint-disable MD060 -->
| Preset | Project | Subnet | Published Ports |
| ------ | ------- | ------ | --------------- |
| Plundarr | `plundarr` | `172.28.0.0/16` | Standard service ports |
| Boudoirr | `boudoirr` | `172.29.0.0/16` | Selected service ports offset by `10000` |
| Jellyfin | `jellyfin` | `172.30.0.0/16` | Jellyfin `8096` |
| Plex | `plex` | `172.31.0.0/16` | Plex host networking |
| Custom | `custom` | `172.27.0.0/16` | Selected service ports offset by `20000` |
<!-- markdownlint-enable MD060 -->

Container names also include the project name. The default Plundarr, default
Boudoirr, standalone Jellyfin, and standalone Plex voyages can therefore run
side by side on one host without sharing container names, subnets, or published
ports. Existing values in `.env` remain preserved during regeneration, so
review and change older project names, network values, or ports before placing
an existing deployment beside another preset.

Change the generated values whenever they overlap another Docker network, VPN,
LAN route, or host service. Plex uses host networking, so only one Plex server
can claim its standard host ports unless Plex itself is configured differently.

## Batten Down the Hatches 🖥️⚓

Fer them sailin' with Synology DiskStations, here be the riggin' details ye need!

### Guardin' the Ship 🔥🛡️

> [!WARNING]
> 🏴‍☠️ Misfirin' yer firewall could leave yer crew stranded! Double-check them source IPs and subnet details before ye weigh anchor.

If your Synology DiskStation firewall is enabled, allow traffic for the custom Docker network:

1. 🛠️ Open **Control Panel** → **Security** (under Connectivity).
2. 🛡️ Go to the **Firewall** tab → Click **Edit Rules**.
3. ➕ Click **Create** to add a rule:
   - 🎯 **Ports**: Select `All`
   - 🌐 **Source IP**: Select `Specific IP`
   - 🧩 Click `Select` → Choose `Subnet`
   - 📝 Enter `172.28.0.0` for **IP Address** and `255.255.0.0` for **Subnet mask/Prefix length**
   - ✅ **Action**: Select `Allow`
4. 💾 Click **OK** to apply.

This allows containers to communicate internally within the defined Docker network while Gluetun hauls selected download-client traffic and port-forwarding through the proper PIA tunnel.

### Launchin' Yer Fleet 📦🚀

> [!NOTE]
> 📜 If yer on DSM 7.2 or later, Synology's Container Manager Project be the swiftest way to get yer fleet underway. Make sure yer vessel's firmware be up-to-date!

To deploy a project using Synology Container Manager:

1. 🔑 Log in to the Synology DSM web interface.
2. 🗺️ Run `make configure` from the cloned repository to chart `docker-compose.yml`, `.env`, and the selected `config/` directories.
3. 📦 Open **Container Manager** and navigate to the **Project** tab 📂.
4. 🆕 Click **Create** and configure:
   - 🏷️ **Project Name**: (e.g., `plundarr`)
   - 📂 **Project Path**: Path to the cloned repository.
   - 📜 **Compose File**: `docker-compose.yml`
5. 🚀 Review and confirm the settings to deploy the project.

Refer to the [official Synology documentation](https://kb.synology.com/en-id/DSM/help/ContainerManager/docker_project?version=7) for further details.

## Jellyfin and Plex Libraries 🎞️

Jellyfin mounts `JELLYFIN_DATA_PATH` as writable `/data`, with separate
persistent `/config` and `/cache` mounts. Add `/data/movies` and `/data/tv` as
libraries for standalone Jellyfin or Plundarr. For Boudoirr, add
`/data/movies` and `/data/scenes`, then point `WHISPARR_DATA_PATH` and
`JELLYFIN_DATA_PATH` at the same high-level host directory. Logs persist under
`/config/log` without a separate log mount.

Plex uses separate read-only library mounts: movies, TV, and anime for
Plundarr; movies and scenes for Boudoirr; movies and TV standalone.

---

These secrets should have ye sailin' smooth seas 🚢 — may yer containers stay hearty 🏴‍☠️ and yer logs whisper like the calm before a storm 🌊. Fair winds and followin' seas, matey! 🐳🏴‍☠️
