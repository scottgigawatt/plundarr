# 🏴‍☠️ Duplicati Configuration 🔄

Ahoy, matey! This be the stash of configuration files fer the **Duplicati** service. These here files will be mounted into the Duplicati container as the service config directory, protectin' yer precious data like a chest o' treasure.

## Purpose 🌊

Duplicati be yer steadfast mate, keepin' backups of all yer important data, ensuring it be safe from any storm or scallywag.

## First Launch Key 🗝️

The LinuxServer Duplicati image requires `DUPLICATI_SETTINGS_ENCRYPTION_KEY` for a new config directory. If that key be missing, Duplicati stops during init and the web UI never opens on port `8200`.

Set `DUPLICATI_SETTINGS_ENCRYPTION_KEY` and `DUPLICATI_WEBSERVICE_PASSWORD` in the generated preset's `.env` before launchin' a fresh stack.

If ye need more details, inspect yer generated `dist/<preset>/docker-compose.yml` and `.env` files.

Arrr, may yer backups be as safe and sound as gold doubloons in a pirate's chest! 💰🏴‍☠️
