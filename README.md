<!-- markdownlint-disable-next-line MD033 MD041 -->
<hr />

<!-- markdownlint-disable MD033 -->
<p align="center">
  <em>🏴‍☠️ Enjoyin' the spoils? Drop us a ⭐️ an' let the whole crew know about this fine treasure!</em>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/scottgigawatt/plundarr?style=social&label=Treasure%20Hunters" alt="Treasure Hunters" />
  <img src="https://img.shields.io/github/forks/scottgigawatt/plundarr?style=social&label=Mutinous%20Forks" alt="Mutinous Forks" />
  <img src="https://img.shields.io/github/watchers/scottgigawatt/plundarr?style=social&label=Crow%27s%20Nest%20Lookouts" alt="Crow's Nest Lookouts" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Containers-Ahoy%21-blue?logo=docker" alt="Containers Ahoy" />
  <img src="https://img.shields.io/badge/Cloaked-by%20PIA%20%26%20WireGuard-green?logo=protonvpn" alt="Cloaked" />
  <img src="https://img.shields.io/github/license/scottgigawatt/plundarr?label=Legal%20Scroll&color=blue" alt="Legal Scroll" />
  <img src="https://img.shields.io/github/last-commit/scottgigawatt/plundarr?label=Last%20Plunder&logo=git" alt="Last Plunder" />
  <img src="https://img.shields.io/badge/Sea--Tested-Synology%20%7C%20macOS-blue" alt="Sea-Tested" />
  <img src="https://img.shields.io/badge/Rum%20Supply-Full-orange" alt="Rum Supply" />
</p>

<p align="center">─── ⛧ ───</p>

<p align="center">
    <em>☠️ Questions or cursed code? Cross the Styx — <strong>Enter 🔥HADES🔥</strong>.</em>
</p>

<p align="center">
  <a href="https://discord.gg/BpEGzWwGYf">
    <img src="https://img.shields.io/discord/1403601106315116626?label=%F0%9F%94%A5HADES%F0%9F%94%A5&logo=discord&logoColor=white&color=5865F2" alt="🔥HADES🔥 Discord" />
  </a>
</p>

<!-- markdownlint-enable MD033 -->
<!-- markdownlint-disable-next-line MD033 -->
<hr />

# Plundarr 🏴‍☠️

Ahoy, mateys! Welcome to Plundarr, the ultimate Docker Compose setup for all ye media needs. Manage yer favorite 'arr' apps, PIA WireGuard VPN, and port-forwarded download routes with ease, all while sailin' the high seas of secure and automated media management. ⚓️

## Captain's Log 📜

Plundarr be a collection of Docker Compose configurations to run a shipshape array of 'arr' tools like Sonarr, Radarr, and more, all securely navigated through Private Internet Access with WireGuard and port forwarding, managed by Gluetun. Avast, set sail on the digital seas with yer media safe from pryin' eyes—tucked away like treasure on a deserted isle! 🏝️

- [Contributing](./docs/CONTRIBUTING.md)
- [Keep to the Code](./docs/CODE_OF_CONDUCT.md)
- [Security Policy](./docs/SECURITY.md)

## Treasure Map 🗺️

| Shipmate          | What It Be                                                                                                                                                  | Yo Ho Ho and More Info                                               |
|-------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------|
| Privateerr        | 🏴‍☠️ Arrr, generate yer PIA WireGuard config and Gluetun metadata so port forwarding knows which dock to hail.                                             | [More info](https://github.com/scottgigawatt/privateerr)             |
| Gluetun           | 🌊 Batten down the hatches! Secure yer VPN route with WireGuard and PIA port forwarding, keepin' yer online doin's hidden from pryin' landlubber eyes.      | [More info](https://github.com/qdm12/gluetun)                        |
| FlareSolverr      | 🔥 Outsmart them scurvy web defenses and keep yer plunderin' smooth as a fine barrel o' rum.                                                                | [More info](https://github.com/FlareSolverr/FlareSolverr)            |
| Prowlarr          | 🐾 The savvy first mate fer wranglin' all yer indexers, keepin' yer treasure map up-to-date with the latest and greatest booty.                             | [More info](https://github.com/Prowlarr/Prowlarr)                    |
| qBittorrent       | 🌊 Default addon fer torrentin', hoist the colors and download with the might of a thousand cannons.                                                       | [More info](https://github.com/qbittorrent/qBittorrent)              |
| SABnzbd           | 📰 Optional addon fer Usenet cargo, grabbin' NZBs, repairin' the haul, and droppin' finished loot into the same download hold.                             | [More info](https://sabnzbd.org)                                     |
| Radarr            | 🎥 Chart yer course fer cinematic riches! Automatically plunder new films and keep yer ship's library filled to the brim.                                   | [More info](https://github.com/Radarr/Radarr)                        |
| Sonarr            | 📺 Set sail on the seas of TV shows! Fetch new episodes and keep yer watchlist shipshape and Bristol fashion.                                               | [More info](https://github.com/Sonarr/Sonarr)                        |
| Sonarr Anime      | 🍜 Optional second Sonarr addon fer anime TV cargo with its own port, config hold, and library root.                                                        | [More info](https://github.com/Sonarr/Sonarr)                        |
| Bazarr            | 🦜 The parrot on yer shoulder squawkin' subtitles in many tongues fer all yer movies and TV shows.                                                          | [More info](https://github.com/morpheus65535/bazarr)                 |
| **~~Readarr~~**   | ❌ Scuttled, matey—she sails no more. Hoist 📚 [Calibre Web Automated](https://github.com/scottgigawatt/calibre-web-automated) fer smooth e-book plunderin'. | [Set Sail ⚓](https://github.com/scottgigawatt/calibre-web-automated) |
| Seerr             | ⚓️ The quartermaster fer handlin' all yer crew's media requests, keepin' the ship runnin' smooth and the crew satisfied.                                    | [More info](https://github.com/seerr-team/seerr)                     |
| Cleanuparr        | 🧹 The swabbie keepin' yer ship clean by removin' blocked or unwanted downloads from Sonarr, Radarr, and yer download mates like qBittorrent.               | [More info](https://github.com/Cleanuparr/Cleanuparr)                |
| Speedtest Tracker | ⚡️ Keep a log of yer internet speed to make sure yer ISP ain't sellin' ye snake oil. Monitor yer connection and track yer speeds over time.                 | [More info](https://docs.speedtest-tracker.dev/)                     |
| Duplicati         | 💣 Guard yer precious booty with backups, lest the kraken strike and sink yer ship.                                                                         | [More info](https://www.duplicati.com)                               |
| Homepage          | 🏠 The captain's command deck fer all yer apps! A fully customizable, static dashboard fer keepin' tabs on all yer ship's systems.                          | [More info](https://gethomepage.dev)                                 |

## Hoist the Sails ⚓️

> [!IMPORTANT]
> 🏴‍☠️ Before settin' sail, copy [`example.env`](./example.env) to `.env` and tweak it to yer own pirate code.

Manage Docker configuration environment variables in the `.env` file. Override these variables easily on the command line when startin' the Docker Compose stack:

```bash
# Hoist the Jolly Roger and clone the repository
git clone git@github.com:scottgigawatt/plundarr.git
cd plundarr

# Copy the example environment file
cp example.env .env

# Open .env and adjust the few settings that steer yer voyage
vim .env
```

Most settings can stay at their defaults. Start with these:

| Setting | Why Ye Care |
|---------|-------------|
| 🔐 `PIA_USER` / `PIA_PASS` | Required for Private Internet Access and Gluetun port forwarding |
| 📦 `HOST_DOWNLOADS_PATH` | Shared download hold visible to Radarr, Sonarr, and download clients |
| 🌊 `HOST_TORRENTS_DOWNLOADS_PATH` | qBittorrent cargo path when using the torrent addon |
| 📰 `HOST_USENET_DOWNLOADS_PATH` | SABnzbd cargo path when using the Usenet addon |
| 🎥 `HOST_MOVIES_PATH` | Radarr movie library root |
| 📺 `HOST_TV_PATH` | Sonarr TV library root |
| 🍜 `HOST_ANIME_TV_PATH` | Sonarr Anime library root when using the anime addon |
| 🚪 `*_WEBUI_PORT` | Change only when a host port conflicts |
| 🏠 `HOMEPAGE_VAR_*_HREF` | Browser click targets shown in Homepage |
| 🔑 `HOMEPAGE_VAR_*_KEY` | API keys for Homepage widgets after apps are configured |

Ye can also override settings for one command without editing `.env`:

```bash
PIA_USER=p1234567 PIA_PASS=abc123 make ship
```

For every available variable, see:

- 🏴‍☠️ [Peek at the Pirate's Env Code](./example.env)

### Render the Final Chart 🗺️

Plundarr source files be modular, but deployment still sails from one complete Compose chart:

```bash
make ship
```

That writes the final deployable chart:

```text
dist/docker-compose.yml
```

Every `make ship` run also rewrites Homepage service cards so the dashboard matches selected addons.

Start here if ye just want to try the default voyage:

```bash
make ship
make services
```

Launch that generated chart:

```bash
make up
```

Or select `dist/docker-compose.yml` in Synology Container Manager.

Choose optional cargo with `ADDONS`. Addons are comma-separated, with no spaces:

| Voyage | Command | What Ye Get |
|---------|---------|-------------|
| 🌊 Default torrent fleet | `make ship` | qBittorrent, Cleanuparr, and core apps |
| 📰 SABnzbd only | `make ship ADDONS=sabnzbd` | SABnzbd and core apps, no qBittorrent |
| ⚓ Both download mates | `make ship ADDONS=qbittorrent,sabnzbd,cleanuparr` | qBittorrent, SABnzbd, Cleanuparr, and core apps |
| 🍜 Anime Sonarr | `make ship ADDONS=qbittorrent,cleanuparr,sonarr-anime` | Default fleet plus second Sonarr on port `8990` |
| 💰 Full cargo hold | `make ship ADDONS=qbittorrent,sabnzbd,cleanuparr,sonarr-anime` | qBittorrent, SABnzbd, Cleanuparr, Sonarr Anime, and core apps |

`make ship` uses the default voyage:

```bash
make ship ADDONS=qbittorrent,cleanuparr
```

After switching addon choices, run `make ship` again before `make up` so `dist/docker-compose.yml` and Homepage cards match yer chosen fleet.

To inspect without launchin' containers:

```bash
make services
make config
```

By default, the VPN tunnel protects selected download-client addons. Prowlarr, Radarr, Sonarr, and Bazarr sail on the normal Docker network to avoid indexer bans, Cloudflare snarls, and upstream API weirdness.

### Synology Notes 📦

Running on Synology? Read the setup scroll before launchin':

- 🖥️ [Docker Project Setup](./docs/SETUP.md)
- 🦜 [Synology helper scripts](scripts/README.md)

### 🔎 Spyglass Check

Basic test voyages:

```bash
make test-vpn
make test-e2e
make test-stack
```

> [!WARNING]
> ⚠️☠️ VPN tests can use real PIA credentials from `.env`. Read the full testing chart before a live voyage: [`test/README.md`](./test/README.md).

To scrub generated service config back to a fresh-clone state without deleting `.env`, run:

```bash
make reset-service-configs
```

> [!NOTE]
> 🏴‍☠️ Privateerr writes PIA WireGuard and port-forwarding metadata for Gluetun, then Gluetun runs the VPN tunnel. When qBittorrent is selected, Gluetun calls [`qbittorrent-port-forwarding.sh`](./config/gluetun/scripts/qbittorrent-port-forwarding.sh) to keep qBittorrent's listening port aligned with PIA's forwarded port.

## Navigatin' Troubled Waters ☠️🌊

> [!TIP]
> ️🧭🗺️ These configs be as wordy as an old sea dog's yarn! Use the Makefile commands if ye prefer less squawkin' 🦜 and cleaner decks 🧹.

The `Makefile` be yer trusty first mate. These are the commands ye will actually use most often:

| Command | What It Does |
|---------|--------------|
| 🗺️ `make ship` | Builds `dist/docker-compose.yml` and Homepage cards from selected addons |
| 🧾 `make services` | Lists services in the rendered Compose file |
| 🔎 `make config` | Prints the full rendered Compose model |
| 🚀 `make up` | Runs `docker compose -f dist/docker-compose.yml up ...` |
| ⚓ `make down` | Stops and removes the rendered stack |
| 📊 `make ps` | Shows running stack containers |
| 📜 `make logs` | Tails stack logs |
| 🧪 `make test-e2e` | Starts VPN plus selected download addons, validates, then cleans up |
| 🧽 `make reset-service-configs` | Scrubs generated service config files back to a fresh clone |

Need the whole chart? Run `make help`.

## Ship's Log 🏝️

Plundarr has been tested on Synology DS1522+ and DS916+ runnin' DSM 7.2. But fear not, me hearties—this treasure ain't just fer Synology! She oughta run smooth on other shores like macOS, Linux, an' any land where Docker sails free.

## Articles of Agreement ⚖️

This project be licensed under the Apache 2 License—see the [LICENSE](LICENSE) scroll for details.

Privateerr uses the unmodified upstream [PIA manual-connections](https://github.com/pia-foss/manual-connections) scripts, which are licensed under the [MIT license](https://github.com/pia-foss/manual-connections/blob/master/LICENSE). Plundarr consumes the published Privateerr image and does not vendor those scripts.

---

```text
               |    |    |
              )_)  )_)  )_)
             )___))___))___)\
            )____)____)_____)\\
         _____|____|____|____\\\__
  ~~ ~~  \_______________________/  ~~ ~~
  ~  ~   ~~~ ~~~~~ ~~~~~ ~~~ ~~~   ~  ~~
      ~   ~   ~  ~~~  ~~~~ ~  ~~   ~ ~

       🏴‍☠️  The Plunderer's Docker Fleet ☠️⚓️
       "Code ho! Containers below deck!"
```

Contribute or provide feedback to improve Plundarr. Arrr, happy sailing! 🏴‍☠️
