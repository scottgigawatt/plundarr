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

#### Setup `tun.sh` to Run on Boot 🛠️

To ensure ye script be running on boot, follow these steps, ye salty dogs:

1. **Open Synology's Task Scheduler:**

    - Go to **Control Panel** -> **Task Scheduler** 🗓️.

2. **Create a Task for `tun.sh`:**

    - Click **Create** -> **Triggered Task** -> **User-defined script** ✍️.
    - Name the task, e.g., 'Create Tunnel' 🌉.
    - Set the user to `root` 🧙.
    - Set the event to **Boot-up** 🚀.
    - Check **Enabled** ✅.
    - Under **Task Settings**, enter the following command under **Run command** 💻:

    ```bash
    bash /volume1/docker/plundarr/scripts/tun.sh
    ```

    - Click **OK** to save the task 💾.

### `entware.sh`

**Prerequisite:** Entware must be installed on your Synology NAS as a prerequisite. Follow the [Entware Installation Guide](https://github.com/Entware/Entware/wiki/Install-on-Synology-NAS) to complete the installation.

> **Note:** Entware is not required for the Plundarr Compose stack to run. This `entware.sh` setup script is provided here for convenience if you choose to use Entware on your system.

This script ensures Entware is properly set up on boot, so all Entware tools are ready when needed.

**Features:**

- Creates the `/opt` directory if it does not exist and mounts Entware to `/opt`.
- Starts the Entware services using the init script.
- Checks if the Entware profile is included in the global profile; adds it if missing.
- Updates the Entware package list to ensure the latest packages are available.

[View the `entware.sh` script](./entware.sh)

#### Setup `entware.sh` to Run on Boot 🛠️

To ensure the script runs on boot, follow these steps:

1. **Open Synology's Task Scheduler:**

    - Go to **Control Panel** -> **Task Scheduler** 🗓️.

2. **Create a Task for `entware.sh`:**

    - Click **Create** -> **Triggered Task** -> **User-defined script** ✍️.
    - Name the task, e.g., 'Entware Setup' ⚙️.
    - Set the user to `root` 🧙.
    - Set the event to **Boot-up** 🚀.
    - Check **Enabled** ✅.
    - Under **Task Settings**, enter the following command under **Run command** 💻:

    ```bash
    bash /volume1/docker/plundarr/scripts/entware.sh
    ```

    - Click **OK** to save the task 💾.

These tasks ensure both scripts be runnin' every time yer Synology NAS starts up, keepin' yer VPNs secure and Entware in shipshape condition! 🏴‍☠️

---

May yer setup be swift and yer configurations flawless! 🌊🏴‍☠️
