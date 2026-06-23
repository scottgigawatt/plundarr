# ⚓️ Config Booty

Ahoy, ye scurvy devils! Welcome to the **`config`** directory of the grand vessel _Plundarr_. This here be the treasure chest holdin' all the config maps for every fine piece of software in our Docker stack, includin' PIA WireGuard and port-forwarding scrolls. Clone this repo, chart yer own configs, and set sail with ease — _no scallywag left behind_! 🏴‍☠️

> [!IMPORTANT]
> Every tool has its own subfolder in `config/`, ready to drop anchor with persistent volumes. Ye need only fill in the blanks, and hoist the docker-compose sails!

## 🗺️ Tools in the Plundarr Fleet

| Tool Name        | Purpose on the High Seas                             |
|------------------|------------------------------------------------------|
| 🏴‍☠️ `bazarr`         | Subtitle swabbie, makin' sure ye always read what's said |
| 🧹 `cleanuparr`     | Cleans up the seas of orphaned files and debris     |
| 💾 `duplicati`      | Backup ye booty — protect it from Davy Jones        |
| 🌩️ `flaresolverr`   | Bypasses cloudflare storms to get yer bounty        |
| 🛡️ `gluetun`        | PIA WireGuard tunnel and port-forwarding quartermaster |
| 🗺️ `homepage`       | Central map to all yer ports — a true dashboard     |
| 📜 `seerr`          | Request board for new treasures — media requests ahoy |
| 🕵️‍♂️ `privateerr`     | PIA WireGuard and port-forwarding mapmaker for Gluetun |
| 🧭 `prowlarr`       | Jack of all trackers, finder of torrents            |
| ⚓ `qbittorrent`    | Torrentin' machine — yer cargo hauler               |
| 🎬 `radarr`         | Movies! Add ‘em, find ‘em, automate ‘em             |
| 📺 `sonarr`         | TV shows, season packs, binge treasures             |
| 🌬️ `speedtest-tracker` | Measure the wind in yer sails (or yer bandwidth) |

> [!TIP]
> Each folder follows the same general format. Config files go in, persistent storage stays. If ye be usin' `docker-compose`, these mounts be auto-mapped for ye.

## Reset the Hold 🧽

To scrub generated service config back to a fresh-clone state without deleting yer local `.env`, run:

```bash
make reset-service-configs
```

This removes ignored generated files under `config/`, leaves tracked README files and seed config aboard, and restores the example WireGuard and Privateerr metadata files.

> [!CAUTION]
> Don't commit any sensitive keys, secrets, or VPN credentials to this here public code — or the sharks'll be on ye in no time.

---

Happy plunderin' and may yer logs be ever green! ☠️⚓️
