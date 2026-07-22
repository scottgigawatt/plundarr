# 📺 Sonarr Anime Configuration 🏴‍☠️

Avast, matey! This hold stores the configuration scrolls fer the optional **Sonarr Anime** service. It runs as a second Sonarr instance with its own database, settings, port, and anime TV root.

## Purpose 🌊

Sonarr Anime keeps animated TV cargo separate from the main Sonarr library so quality profiles, release profiles, naming rules, and root folders can sail their own course.

## Downloads and Anime Imports 📦

Sonarr Anime sees download clients at `/downloads` and imports finished anime into `/tv`. In Plundarr, `/tv` maps to `HOST_ANIME_TV_PATH` for this service only.

Use a separate root folder from the main Sonarr service. Mixing both captains into the same root can confuse imports, monitoring, and library cleanup.

Use these download client categories:

```text
qBittorrent category: sonarr-anime
qBittorrent category save path: /downloads/torrents/anime-tv

SABnzbd category: sonarr-anime
SABnzbd category folder/path: anime-tv
```

For Usenet, point SABnzbd completed jobs at `/downloads/usenet` and temporary jobs at `/downloads/usenet/incomplete`; the `sonarr-anime` category then lands episode jobs in `/downloads/usenet/anime-tv`.

Render the service into yer final chart:

```bash
make ship OPTIONAL_SERVICES=qbittorrent,cleanuparr,sonarr-anime
```

For more details, set yer sights on the [docker-compose.yml](../../docker-compose.yml) parchment in the root of the repository.
