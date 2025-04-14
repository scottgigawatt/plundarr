# 🏴‍☠️ Plundarr's Bag o' Bootstrappin' Scripts ⚓️

Ahoy, mateys! This be the treasure chest holdin' extra scripts to help with the setup and configuration of Plundarr on Synology. Each script be a valuable tool, guidin' ye through various tasks to ensure smooth sailin'.

> [!NOTE]
> 🏴‍☠️ The `tun.sh` script ensures yer VPN sails smooth by creatin' the `/dev/net/tun` device when needed.

## 📜 Scrolls in the Captain's Chest

### 🪝 `tun.sh` – Forge the VPN Passage

This script ensures the `/dev/net/tun` device exists on Synology Disk Station for use with VPN applications like Gluetun. The `/dev/net/tun` device be a virtual network device that implements point-to-point network tunnels, essential for VPNs to create secure and private connections over the internet.

**Features:**

- Checks if the `/dev/net/tun` device exists and creates it if necessary.
- Creates the `/dev/net` directory if it does not exist.
- Creates the `/dev/net/tun` device node with the correct permissions.
- Loads the `tun` module if it is not already loaded.

📜 [Spy the tun.sh Scroll](./tun.sh)

> [!TIP]
> 🛠️ Settin' this script to run at boot keeps yer VPN tunnels shipshape without manual riggin'.

#### 🧙‍♂️ Teach the Ship to Hoist `tun.sh` at Dawn

To ensure ye script be running on boot, follow these steps, ye salty dogs:

1. **Open Synology's Task Scheduler:**

    - Go to **Control Panel** -> **Task Scheduler** 🗓️.

2. **Create a Task for `tun.sh`:**

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

### ⚙️ `entware.sh` – Summon the Tools o' the Deep

> [!NOTE]
> ⚓️ Entware be optional for Plundarr but handy for pirates wantin' extra tools aboard.

> [!IMPORTANT]
> 🧙 Entware must be installed first! Follow the [Entware Installation Guide](https://github.com/Entware/Entware/wiki/Install-on-Synology-NAS) to prepare yer vessel.

This script ensures Entware is properly set up on boot, so all Entware tools are ready when needed.

**Features:**

- Creates the `/opt` directory if it does not exist and mounts Entware to `/opt`.
- Starts the Entware services using the init script.
- Checks if the Entware profile is included in the global profile; adds it if missing.
- Updates the Entware package list to ensure the latest packages are available.

🦜 [Peruse the entware.sh Parchment](./entware.sh)

> [!TIP]
> ⚙️ Automatin' this task on boot ensures yer Entware toolkit is always ready when ye need it.

#### 🧙‍♂️ Command the Entware Spirits on Boot

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

---

May yer setup be swift and yer configurations flawless! 🌊🏴‍☠️
