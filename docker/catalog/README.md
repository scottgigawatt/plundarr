# Maraudarr Catalog 🗺️

This hold contains the metadata Maraudarr uses to order services, resolve
dependencies, describe interactive choices, and define named presets.

[`catalog.toml`](catalog.toml) is intentionally verbose and commented. Service
charts and environment settings do not belong here; those live together under
[`../services/`](../services/).

> [!IMPORTANT]
> Keep service IDs aligned with their directory names. Maraudarr derives
> `services/<id>/compose.yml`, `environment.env`, and `config/` from that ID.
