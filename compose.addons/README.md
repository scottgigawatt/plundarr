# Compose Addons

These scrolls add optional cargo to Plundarr before the final deployable Compose file is rendered.

Use `make ship ADDONS=...` to build `dist/docker-compose.yml`.

## Addons

- `qbittorrent` - Torrent download client and Gluetun port-forwarding hook.
- `sabnzbd` - Usenet download client.
- `cleanuparr` - Cleanup service for the default qBittorrent voyage.
- `sonarr-anime` - Second Sonarr instance for anime TV cargo.

## Examples

```bash
make ship
make ship ADDONS=sabnzbd
make ship ADDONS=qbittorrent,sabnzbd
make ship ADDONS=qbittorrent,cleanuparr
make ship ADDONS=qbittorrent,cleanuparr,sonarr-anime
```

Deploy only the rendered file:

```bash
docker compose -f dist/docker-compose.yml up -d
```
