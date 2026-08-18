# ⚓ qBittorrent Configuration 🏴‍☠️

Avast, me hearties! This be the treasure trove holdin' the configuration files fer the **qBittorrent** service. These files will be mounted into the qBittorrent container as the service config directory, guidin' yer downloads to port.

## Purpose 🌊

qBittorrent be yer steadfast mate, helpin' ye manage and organize yer downloads with ease, plunderin' the digital depths for all yer desired treasures.

## Torrent Download Hold 📦

qBittorrent writes downloads under `/downloads/torrents` inside the container. In Plundarr, that path maps to `HOST_TORRENTS_DOWNLOADS_PATH` on the host. Radarr and Sonarr mount the broader `HOST_DOWNLOADS_PATH` at `/downloads`, so they see the same completed torrent files at `/downloads/torrents/...`.

Keep qBittorrent, Radarr, and Sonarr aligned under `/downloads`. If qBittorrent saves to a different path that Radarr or Sonarr cannot see, imports can fail or copy files instead of using hardlinks.

With SABnzbd aboard, keep torrent cargo in its own lane:

```text
Default Save Path: /downloads/torrents
Keep incomplete torrents in: /downloads/torrents/incomplete
```

Create qBittorrent categories so Radarr and Sonarr can sort downloads by library type:

```text
Category: radarr
Save path: /downloads/torrents/movies

Category: sonarr
Save path: /downloads/torrents/tv
```

Then set the qBittorrent download client category in Radarr to `radarr` and in Sonarr to `sonarr`.

## Seeding and Imports ⚓

If ye seed torrents, qBittorrent needs the original downloaded payload to remain under `/downloads/torrents`. Radarr and Sonarr can import media into `/movies` or `/tv` while qBittorrent keeps seeding from `/downloads/torrents`.

If ye do not plan to seed, configure qBittorrent, Radarr, and Sonarr cleanup behavior intentionally so completed torrents do not pile up in the download hold after import.

## Port Forwarding 🧭

Gluetun updates qBittorrent's listening port when PIA assigns a forwarded port. For that local API call to work, enable qBittorrent's Web UI setting to bypass authentication for clients on localhost.

When the port-forwarding script runs, it sets qBittorrent to:

- Listen on Gluetun's forwarded port.
- Bind to Gluetun's VPN interface.
- Disable random ports.
- Disable UPnP port mapping.

Fer more details, inspect yer generated `dist/<preset>/docker-compose.yml` and
`.env` files.

May yer sails be full and yer seas calm as ye plunder the digital depths! ⚔️🌊
