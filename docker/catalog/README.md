# Maraudarr Catalog 🗺️

This hold contains the metadata Maraudarr uses to order services, resolve
dependencies, describe interactive choices, and define named presets.

[`catalog.toml`](catalog.toml) is intentionally verbose and commented. Service
charts and environment settings do not belong here; those live together under
[`../services/`](../services/).

Each preset owns its Compose project name, network defaults, high-level media
root, and the library mounts used when Plex is selected. Jellyfin always mounts
that high-level root at `/data`; its library names remain application settings,
not alternate Compose shapes.

Preset `core` services cannot be removed. Preset `defaults` are only preselected
in the interactive picker and may be unchecked. Plundarr and Boudoirr use this
boundary to default to qBittorrent while leaving SABnzbd, NZBGet, and Watchtower
as independent opt-in services.

> [!IMPORTANT]
> Keep service IDs aligned with their directory names. Maraudarr derives
> `services/<id>/compose.yml`, `environment.env`, and `config/` from that ID.
