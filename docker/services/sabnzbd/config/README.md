# 📰 SABnzbd Configuration 🏴‍☠️

Ahoy, matey! This be the config hold for **SABnzbd**, Plundarr's Usenet download runner. SABnzbd grabs NZBs, repairs the cargo, extracts the haul, and drops completed files where Radarr and Sonarr can find them.

## Purpose 🌊

SABnzbd gives the stack a Usenet path alongside qBittorrent's torrent path. The SABnzbd service routes it through Gluetun and writes only under `/downloads/usenet`, while Radarr and Sonarr mount the broader `/downloads` path for imports.

## Download Folders 📦

Plundarr maps `HOST_USENET_DOWNLOADS_PATH` to `/downloads/usenet` inside SABnzbd. Use this low-risk Synology layout:

```text
/volume1/downloads/torrents
/volume1/downloads/usenet
/volume1/plex/movies
/volume1/plex/tv
```

Inside SABnzbd, set folders like this:

```text
Temporary Download Folder: /downloads/usenet/incomplete
Completed Download Folder: /downloads/usenet
```

Create SABnzbd categories so Radarr and Sonarr can sort completed jobs by library type:

```text
Category: radarr
Folder/Path: movies

Category: sonarr
Folder/Path: tv
```

That makes completed jobs land in `/downloads/usenet/movies` and `/downloads/usenet/tv`. Then set the SABnzbd download client category in Radarr to `radarr` and in Sonarr to `sonarr`. Keep media roots at `/movies` for Radarr and `/tv` for Sonarr.

## Shared Gluetun Port 🧭

qBittorrent uses internal port `8080` inside Gluetun's network namespace. SABnzbd uses internal port `8085`, so both download clients can share Gluetun cleanly.

Use `SABNZBD_WEBUI_PORT` in the generated preset's `.env` to choose the host-side port. Plundarr defaults the host port to `8081` and maps it to SABnzbd's fixed internal `8085`. Leave the internal port alone unless ye also update the Compose healthcheck and Gluetun port mapping.

## Homepage Widget 🗺️

After SABnzbd starts, copy its API key into `HOMEPAGE_VAR_SABNZBD_KEY` in the generated preset's `.env` if ye want Homepage to show the widget status.

Fer more details, inspect yer generated `dist/<preset>/docker-compose.yml` and `.env` files.

May yer Usenet cargo arrive repaired, extracted, and ready for the library hold! ⚓
