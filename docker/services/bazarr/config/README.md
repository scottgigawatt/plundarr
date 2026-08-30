# Bazarr configuration 📝

Bazarr stores its database, settings, logs, and subtitle-provider credentials in this directory. Connect Bazarr to Radarr and Sonarr after first launch, and keep its internal media paths aligned with the `/movies` and `/tv` mounts in the generated Compose file.

Treat this directory as private application state and back it up before running `make delete-config`.
