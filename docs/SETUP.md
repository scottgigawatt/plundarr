# Plundarr Docker Setup Guide ⚓🐳🏴‍☠️

Avast ye! This here be the guide for riggin' up yer Docker Compose fleet with PIA WireGuard and port-forwarding support. It covers the treacherous waters of Synology DiskStations with DSM 7.2 or later, but landlubbers usin' Linux and macOS can sail by these charts too! 🏴‍☠️

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
2. 🗺️ Run `make ship` from the cloned repository to chart `docker-compose.yml`, `.env`, and the selected `config/` directories.
3. 📦 Open **Container Manager** and navigate to the **Project** tab 📂.
4. 🆕 Click **Create** and configure:
   - 🏷️ **Project Name**: (e.g., `plundarr`)
   - 📂 **Project Path**: Path to the cloned repository.
   - 📜 **Compose File**: `docker-compose.yml`
5. 🚀 Review and confirm the settings to deploy the project.

Refer to the [official Synology documentation](https://kb.synology.com/en-id/DSM/help/ContainerManager/docker_project?version=7) for further details.

---

These secrets should have ye sailin' smooth seas 🚢 — may yer containers stay hearty 🏴‍☠️ and yer logs whisper like the calm before a storm 🌊. Fair winds and followin' seas, matey! 🐳🏴‍☠️
