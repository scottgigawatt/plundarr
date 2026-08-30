# Maraudarr 🏴‍☠️⚒️

Maraudarr is the short-lived generator image for [Plundarr](https://github.com/scottgigawatt/plundarr). It turns presets and selectable service charts into one commented Docker Compose file, one matching environment file, and the selected service config directories.

> [!IMPORTANT]
> Plundarr is the generated media stack. Maraudarr creates that stack and exits; it is not a long-running media service.

## Quick Voyage

The repository Makefile supplies the hardened Docker invocation:

> [!TIP]
>
> ```sh
> git clone https://github.com/scottgigawatt/plundarr.git
> cd plundarr
> make ship
> ```

Generated cargo lands in its preset directory:

```text
dist/plundarr/
├── docker-compose.yml
├── example.env
├── .env
└── config/
```

Run `make configure` for the interactive preset and service picker, or choose a preset directly:

> [!TIP]
>
> ```sh
> make ship PRESET=jellyfin
> make ship PRESET=plex
> make ship PRESET=duplex
> make ship PRESET=watchtower
> make ship PRESET=boudoirr ADD_SERVICES=jellyfin
> make ship ADD_SERVICES=sonarr-anime
> ```

Plundarr and Boudoirr use qBittorrent as their only default downloader and include Watchtower as a removable default. SABnzbd and NZBGet remain optional selections through `make configure` or `ADD_SERVICES`. Plundarr includes one Sonarr instance; `sonarr-anime` adds the optional second instance. Review `dist/<preset>/.env`, then start the generated stack with `make up PRESET=<preset>`. The standalone Watchtower project may instead run one update pass with `make watchtower-run-once PRESET=watchtower`.

The Duplex preset keeps Kometa's configuration in an independent host checkout selected by `KOMETA_CONFIG_PATH`. Its PATTRMM, Notifiarr, and Overlay Reset defaults are removable; Watchtower may be added explicitly. Kometa Overlay Reset is excluded from normal startup by its Compose profile and runs explicitly with `make kometa-overlay-reset PRESET=duplex`; its generated default is dry-run.

## Image Details

- Registries: `ghcr.io/scottgigawatt/maraudarr` and `scottgigawatt/maraudarr`
- Platforms: `linux/amd64`, `linux/arm64`, and `linux/arm/v7`
- Stable tag: `latest`
- Main branch tag: `edge`
- Stable release aliases: exact, minor, and major versions such as `1.2.3`, `1.2`, and `1`
- Immutable revision tag: `sha-...`
- Security: non-root, read-only, no-network generation with dropped capabilities
- Supply chain: Trivy scanning, SBOM, provenance, and OCI metadata

Major version zero omits the broad `0` alias. Prereleases publish only their exact version and immutable revision tag, never moving stable aliases. Release publication accepts only `v`-prefixed annotated SemVer tags whose commits already belong to `main`.

Full commands, tag policy, architecture, and maintenance notes live in the [Maraudarr README](https://github.com/scottgigawatt/plundarr/tree/main/docker#readme).
