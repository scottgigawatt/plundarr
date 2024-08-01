# 📜 Plundarr Scripts Directory ⚓️

Ahoy, mateys! This be the treasure chest holdin' extra scripts to help with the setup and configuration of Plundarr on Synology. Each script be a valuable tool, guidin' ye through various tasks to ensure smooth sailin'.

## Available Scripts 📜

### `tun.sh`

This script ensures the `/dev/net/tun` device exists on Synology Disk Station for use with VPN applications like Gluetun. The `/dev/net/tun` device be a virtual network device that implements point-to-point network tunnels, essential for VPNs to create secure and private connections over the internet.

**Features:**

- Checks if the `/dev/net/tun` device exists and creates it if necessary.
- Creates the `/dev/net` directory if it does not exist.
- Creates the `/dev/net/tun` device node with the correct permissions.
- Loads the `tun` module if it is not already loaded.

[View the `tun.sh` script](./tun.sh)

#### Usage 🛠️

To make sure the `/dev/net/tun` device be present on Synology Disk Station for use with VPN applications like Gluetun, follow these steps, me hearties:

1. **Setup Task Scheduler on Synology NAS:**

    Open Synology's Control Panel and follow these steps to run the script on boot:

    - Go to **Task Scheduler** 🗓️.
    - Click **Create** -> **Triggered Task** -> **User-defined script** ✍️.
    - Give the task a name, e.g., 'Create Tunnel' 🌉.
    - Set the user to `root` 🧙.
    - Set the event to **Boot-up** 🚀.
    - Check **Enabled** ✅.
    - Under **Task Settings**, enter the following command under **Run command** 💻:

      ```bash
      bash /volume1/docker/plundarr/scripts/tun.sh
      ```

    - Click **OK** to save the task 💾.

This ensures that the `/dev/net/tun` device be available whenever yer Synology NAS boots up, so ye can sail the seas with yer VPN secure and sound. Arrr! 🏴‍☠️

---

May yer setup be swift and yer configurations flawless! 🌊🏴‍☠️
