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

---

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

### 🔁 `compose_restart.sh` – Raise Any Fleet from the Depths

This script be the mighty call to arms for rebuildin' any Docker fleet from scratch, not just Plundarr's!

**Features:**

- Stops all containers and scuttles volumes with `docker compose down --volumes` 🧨.
- Rebuilds and restarts yer containers in the right order, nice and tidy ⚓.
- Blocks until the deed is done — no async sea serpents here 🐍❌.

🦜 [Consult the compose_restart.sh Codex](./compose_restart.sh)

> [!TIP]
> 🔄 Useful when ye be updatin' configurations or need to purge the bilge and start anew.

#### 🧙‍♂️ Make the Deckhands Run It Manually (or on Command)

To run this script whenever the seas get rough, just hoist this flag:

```sh
sh /volume1/docker/plundarr/scripts/compose_restart.sh /volume1/docker/plundarr
```

#### 🧙‍♂️ Command the Fleet to Rise on Boot

To ensure the Docker fleet sets sail in the right order after every reboot, set this script to run automatically at boot:

1. **Open Synology's Task Scheduler:**

    - Go to **Control Panel** -> **Task Scheduler** 🗓️.

2. **Create a Task for `compose_restart.sh`:**

    - Click **Create** -> **Triggered Task** -> **User-defined script** ✍️.
    - Name the task, e.g., 'Restart Docker Stack' 🛳️.
    - Set the user to `root` 🧙.
    - Set the event to **Boot-up** 🚀.
    - Check **Enabled** ✅.
    - Under **Task Settings**, enter the following command under **Run command** 💻:

      ```sh
      sh /volume1/docker/plundarr/scripts/compose_restart.sh /volume1/docker/plundarr
      ```

    - Click **OK** to save the task 💾.

> [!TIP]
> 🏴‍☠️ This makes sure yer containers always rise in proper order after a restart, without liftin’ a finger.

---

### 🕵️‍☠️ `test_vpn.sh` – Spyglass into the VPN Abyss

This script helps ye confirm whether yer VPN tunnel be secure and active by comparin' the public IP and location from inside a container with that o' the host.

**Features:**

- Runs a container hooked into yer VPN network (like Gluetun).
- Fetches the container's public IP and location via `ipinfo.io`.
- Compares it against the host's own info to spot any leaks.
- Uses `jq` to pretty-print responses if installed, or falls back to a plaintext method.

🦜 [Unfurl the test_vpn.sh Chart](./test_vpn.sh)

> [!TIP]
> 🔍 Useful fer confirm'n that yer containers be masked and the host be hidin' in the fog! Call it straight from the Makefile with:
>
> ```sh
> make test-vpn
> ```

---

### 🧭 `set-inotify-limits.sh` – Strengthen the Watchtowers

This script raises Linux inotify limits on Synology so Plex can keep watch over massive media hoards without droppin’ the spyglass. When the watch limit be too small, Plex can’t track every folder and starts hollerin’ about “No space left on device,” even when the hold be full o’ storage.

**Features:**

- Raises inotify watch limits for large Plex libraries 🏰.
- Verifies the new values be applied proper and true ⚖️.
- Writes a persistent sysctl config when supported 📜.
- Safe for high‑RAM ships like the DS1522+ and other beefy vessels 💪.

🦜 [Study the set-inotify-limits.sh Map](./set-inotify-limits.sh)

> [!TIP]
> 🧭 Perfect fer pirates with giant media empires. More folders mean more watchtowers, and this script makes sure Plex never runs out o’ eyes.

#### 🧙‍♂️ Raise the Watchtowers at Boot

To keep yer limits high after every reboot, set the script to run at boot:

1. **Open Synology’s Task Scheduler:**

   - Go to **Control Panel** -> **Task Scheduler** 🗓️.

2. **Create a Task for `set-inotify-limits.sh`:**

   - Click **Create** -> **Triggered Task** -> **User-defined script** ✍️.
   - Name the task, e.g., ‘Raise Watch Limits’ 🏰.
   - Set the user to `root` 🧙.
   - Set the event to **Boot-up** 🚀.
   - Check **Enabled** ✅.
   - Under **Task Settings**, enter the following command under **Run command** 💻:

     ```sh
     sh /volume1/docker/plundarr/scripts/set-inotify-limits.sh
     ```

   - Click **OK** to save the task 💾.

> [!TIP]
> 🏴‍☠️ This keeps Plex watchin’ every corner of yer library without missin’ a single crate o’ loot.

May yer setup be swift and yer configurations flawless! 🌊🏴‍☠️

May this scroll guide all yer Docker fleets to set sail true and in order! ⚓🏴‍☠️
