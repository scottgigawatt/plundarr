# 🎥 Radarr Configuration 🏴‍☠️

Shiver me timbers! This be the treasure chest holdin' the configuration files fer the **Radarr** service. These files will be mounted into the Radarr container as the service config directory, guidin' yer movie collection to safe harbor.

## Purpose 🌊

Radarr be yer trusty mate, helpin' ye manage and organize yer movie collection, makin' sure ye never miss out on any cinematic treasures.

## Downloads and Movie Imports 📦

Radarr sees qBittorrent downloads at `/downloads` and yer movie library at `/movies`. In Plundarr, `/downloads` maps to the same `HOST_DOWNLOADS_PATH` used by qBittorrent, and `/movies` maps to `HOST_MOVIES_PATH`.

Keep Radarr's download client path pointed at `/downloads`. That shared path lets Radarr import completed movie downloads cleanly and use hardlinks when the host filesystem supports them.

If ye keep seeding, leave the original torrent payload in `/downloads` so qBittorrent can keep sharing it while Radarr manages the imported movie in `/movies`.

Fer more details, set yer spyglass on the [docker-compose.yml](../../docker-compose.yml) file in the root of the repository.

May yer movie collection be as vast as the seven seas, with hidden treasures awaitin' at every turn! 🌊⚔️
