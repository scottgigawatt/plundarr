# Modular Compose Plan

Plundarr needs to keep one big deployable `docker-compose.yml` artifact for Docker Compose and Synology Container Manager while letting each captain choose optional cargo like qBittorrent, SABnzbd, and extra Sonarr instances.

## Goal

- Keep source Compose files modular.
- Render one complete Compose file before deployment.
- Let Synology users select one generated file.
- Keep qBittorrent as the default Plundarr voyage.
- Let users choose SABnzbd instead of qBittorrent, or run both.

## First PR Scope

1. Keep `docker-compose.yml` as the core source stack.
2. Move qBittorrent into `compose.addons/qbittorrent.yml`.
3. Move SABnzbd into `compose.addons/sabnzbd.yml`.
4. Move Cleanuparr into `compose.addons/cleanuparr.yml` with the default qBittorrent voyage.
5. Add generated output path `dist/docker-compose.yml`.
6. Add `make ship` to render and validate the final file.
7. Make `ADDONS ?= qbittorrent,cleanuparr` so `make ship` keeps the current default torrent voyage.
8. Update Compose-backed Make targets to use the rendered file.
9. Remove hard downloader dependencies from core Radarr and Sonarr.
10. Move qBittorrent-specific Gluetun ports and port-forwarding hooks into the qBittorrent addon.
11. Move SABnzbd-specific Gluetun port mapping into the SABnzbd addon.
12. Move Prowlarr, Radarr, Sonarr, and Bazarr off Gluetun by default.
13. Document how to build final Compose files for Docker Compose and Synology.

## Later PRs

1. Add `compose.addons/sonarr-anime.yml`.
2. Add `SONARR_ANIME_*` and `HOST_ANIME_TV_PATH` variables.
3. Add `config/sonarr-anime/README.md`.
4. Decide whether Homepage config should be generated from addon fragments.
5. Decide whether Cleanuparr needs downloader-specific addons.
6. Decide whether optional `prowlarr-vpn` or direct `sabnzbd` addons are useful.

## Target Commands

```bash
make ship
make ship ADDONS=sabnzbd
make ship ADDONS=qbittorrent,sabnzbd
make ship ADDONS=qbittorrent,sabnzbd,sonarr-anime
```

Each command writes:

```text
dist/docker-compose.yml
```

That generated file is the one true deployment chart:

```bash
docker compose -f dist/docker-compose.yml up -d
```

Synology users should select `dist/docker-compose.yml` in Container Manager.
