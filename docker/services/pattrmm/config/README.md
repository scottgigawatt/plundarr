# PATTRMM Neo runtime state 📅

Create `data/` here and give the configured `PATTRMM_PUID:PATTRMM_PGID` write access. Neo stores its cache in that directory.

Authored settings live in `PATTRMM_SETTINGS_PATH`, normally the Kometa checkout's `pattrmm/` directory. `PATTRMM_SETTINGS` selects `settings.yml`. Neo reads private connection values from the shared Kometa runtime configuration and writes generated collections beneath the Kometa checkout.

See the [Neo service guide](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/pattrmm/README.md) for permissions, schedules, and manual runs.
