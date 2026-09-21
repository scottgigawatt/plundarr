# PATTRMM Neo runtime state 📅

Create `data/` here and give the shared `DEFAULT_PUID:DEFAULT_PGID` identity write access. Neo also inherits the supplementary `DEFAULT_GROUP` media-management group and stores its cache in this directory.

Authored settings live in `PATTRMM_SETTINGS_PATH`, normally the Kometa checkout's `pattrmm/` directory. `PATTRMM_SETTINGS` selects `settings.yml`. Neo reads private connection values from the shared Kometa runtime configuration and writes generated collections beneath the Kometa checkout.

See the [Neo service guide](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/pattrmm/README.md) for permissions, schedules, and manual runs.
