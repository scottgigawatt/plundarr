# Seerr configuration 📜

Seerr stores its database, settings, logs, authentication data, and connected media-service credentials in this directory. Complete the first-run wizard through the Web UI, then connect the selected Plex or Jellyfin server and automation services.

Protect this directory as durable, sensitive application state. A fresh `make ship` preserves it; `make delete-config` removes it.
