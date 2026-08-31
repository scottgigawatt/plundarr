# Maraudarr catalog 🗺️

This hold contains the metadata Maraudarr uses to order services, resolve dependencies, describe interactive choices, and define named presets.

[`catalog.toml`](catalog.toml) is intentionally verbose and commented. Service charts and environment settings do not belong here; those live together under [`../services/`](../services/).

Each preset owns its Compose project name, network defaults, high-level media root, expected libraries, and optional host-port offset. Those identities keep fresh presets separate when several stacks share one Docker host. Jellyfin always mounts the high-level root at `/data`; its library names remain application settings, not alternate Compose shapes. Plex uses the same generic library profile to select its read-only mounts. Calibre-Web Automated owns separate config, destructive ingest, and library mounts instead of using the video-library profile.

Preset `core` services cannot be removed. Preset `defaults` are only preselected in the interactive picker and may be unchecked. Plundarr and Boudoirr use this boundary to default to qBittorrent and Watchtower while leaving SABnzbd and NZBGet as independent opt-in services. Calibre-Web Automated is another removable Plundarr default and the only core service in its standalone preset. The focused Watchtower preset makes the same updater available as its own persistent or one-shot project.

Preset bridge subnets occupy the private, sequential `172.20.0.0/16` through `172.28.0.0/16` range, with `172.26.0.0/16` intentionally left outside this catalog for the separately deployed Paperless project. Each bridge uses its preset's `.5.0/24` address pool and `.5.254` gateway.

Duplex keeps Kometa, ImageMaid, and Tautulli in `core`. PATTRMM, Notifiarr, and the profile-gated Overlay Reset tool live in `defaults`, so the generated preset includes them out of the box while the interactive picker may remove them. Watchtower remains selectable but is not a Duplex default. PATTRMM and Overlay Reset require Kometa because both consume its external configuration tree.

> [!IMPORTANT]
> Keep service IDs aligned with their directory names. Maraudarr derives `services/<id>/compose.yml`, `environment.env`, and `config/` from that ID.
