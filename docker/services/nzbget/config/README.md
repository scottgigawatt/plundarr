# 📰 NZBGet Configuration 🏴‍☠️

Ahoy, matey! This be the config hold for **NZBGet**, Plundarr's lean Usenet
download runner. NZBGet grabs NZBs, repairs and extracts the cargo, then leaves
completed files where Radarr and Sonarr can import them.

## Purpose 🌊

NZBGet provides another selectable Usenet path alongside SABnzbd. Its traffic
routes through Gluetun, and Maraudarr generates a strong first-run control
password in `.env` instead of sailing with NZBGet's upstream default.

Maraudarr creates this directory and refreshes this README, but it does not
seed or replace `nzbget.conf`. NZBGet owns that application state after its
first launch.

## Add Your Usenet Provider 🔐

Before testing a download, open **Settings > News-Servers** and add the server
hostname, port, encryption setting, username, and password supplied by your
Usenet provider. These provider credentials belong in NZBGet's application
configuration; `NZBGET_USER` and `NZBGET_PASS` protect only the Web UI.

## Download Folders 📦

Plundarr maps `HOST_USENET_DOWNLOADS_PATH` to `/downloads/usenet` inside
NZBGet. Use this low-risk Synology layout:

```text
/volume1/downloads/torrents
/volume1/downloads/usenet
/volume1/plex/movies
/volume1/plex/tv
```

In NZBGet, open **Settings > Paths** and use:

```text
MainDir: /downloads/usenet
InterDir: ${MainDir}/incomplete
DestDir: ${MainDir}/complete
NzbDir: ${MainDir}/nzb
```

Create NZBGet categories so the automation fleet can sort completed jobs:

```text
Category: radarr
DestDir: ${MainDir}/complete/movies

Category: sonarr
DestDir: ${MainDir}/complete/tv
```

Then set the NZBGet download client category in Radarr to `radarr` and in
Sonarr to `sonarr`. Keep media roots at `/movies` for Radarr and `/tv` for
Sonarr.

## Shared Gluetun Port 🧭

NZBGet shares Gluetun's network namespace and listens on internal port `6789`.
When adding NZBGet to Radarr or Sonarr, use:

```text
Host: gluetun
Port: 6789
Use SSL: No
```

Use the `NZBGET_USER` and `NZBGET_PASS` values from `.env` for authentication.
`NZBGET_WEBUI_PORT` controls only the host-side Web UI port. The Homepage link
defaults to `http://host.or.ip:6789`; replace `host.or.ip` in `.env` with the
NAS address yer browser can reach.

> [!IMPORTANT]
> Keep NZBGet's internal control port at `6789`. Changing it also requires
> updating the Compose healthcheck, Gluetun port mapping, Homepage widget URL,
> and every connected automation service.

## Path Parity 🗺️

Radarr and Sonarr mount the broader host download root at `/downloads`, so
NZBGet's completed cargo appears to them under `/downloads/usenet/complete`.
Because every service sees the same host path through the same internal path,
remote path mappings are unnecessary.

Fer more details, set yer spyglass on the generated
`dist/<preset>/docker-compose.yml` and `.env` files. May yer Usenet cargo
arrive repaired, unpacked, and ready for the library hold! ⚓
