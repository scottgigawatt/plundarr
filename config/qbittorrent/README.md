# ⚓ qBittorrent Configuration 🏴‍☠️

Avast, me hearties! This be the treasure trove holdin' the configuration files fer the **qBittorrent** service. These files will be mounted into the qBittorrent container as the service config directory, guidin' yer downloads to port.

## Purpose 🌊

qBittorrent be yer steadfast mate, helpin' ye manage and organize yer downloads with ease, plunderin' the digital depths for all yer desired treasures.

## Shared Download Hold 📦

qBittorrent writes downloads to `/downloads` inside the container. In Plundarr, that path maps to `HOST_DOWNLOADS_PATH` on the host. Radarr and Sonarr mount that same host path at `/downloads` too, so all three containers see the same files at the same container path.

Keep qBittorrent, Radarr, and Sonarr aligned on `/downloads`. If qBittorrent saves to a different path that Radarr or Sonarr cannot see, imports can fail or copy files instead of using hardlinks.

## Seeding and Imports ⚓

If ye seed torrents, qBittorrent needs the original downloaded payload to remain in `/downloads`. Radarr and Sonarr can import media into `/movies` or `/tv` while qBittorrent keeps seeding from `/downloads`.

If ye do not plan to seed, configure qBittorrent, Radarr, and Sonarr cleanup behavior intentionally so completed torrents do not pile up in the download hold after import.

## Port Forwarding 🧭

Gluetun updates qBittorrent's listening port when PIA assigns a forwarded port. For that local API call to work, enable qBittorrent's Web UI setting to bypass authentication for clients on localhost.

When the port-forwarding script runs, it sets qBittorrent to:

- Listen on Gluetun's forwarded port.
- Bind to Gluetun's VPN interface.
- Disable random ports.
- Disable UPnP port mapping.

Fer more details, set yer spyglass on the [docker-compose.yml](../../docker-compose.yml) file in the root of the repository.

May yer sails be full and yer seas calm as ye plunder the digital depths! ⚔️🌊
