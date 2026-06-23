# 📺 Sonarr Configuration 🏴‍☠️

Avast, me hearties! This here be the treasure chest where ye store the configuration scrolls fer the **Sonarr** service. These scrolls will be hoisted into the Sonarr container as the service config directory, keepin' yer TV show library in shipshape order.

## Purpose 🌊

Sonarr be yer trusty mate, helpin' ye manage and organize yer TV show library, makin' sure ye never miss an episode of yer favorite series.

## Downloads and TV Imports 📦

Sonarr sees qBittorrent downloads at `/downloads` and yer TV library at `/tv`. In Plundarr, `/downloads` maps to the same `HOST_DOWNLOADS_PATH` used by qBittorrent, and `/tv` maps to `HOST_TV_PATH`.

Keep Sonarr's download client path pointed at `/downloads`. That shared path lets Sonarr import completed episode downloads cleanly and use hardlinks when the host filesystem supports them.

If ye keep seeding, leave the original torrent payload in `/downloads` so qBittorrent can keep sharing it while Sonarr manages the imported episode in `/tv`.

For more details, set yer sights on the [docker-compose.yml](../../docker-compose.yml) parchment in the root of the repository.

May yer TV show library be as vast as the seven seas, with adventures awaitin' at every watch! 📺⚔️
