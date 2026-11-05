# Cruisarr service chart 🔞

Adds the private [Cruisarr discovery and request application](https://github.com/scottgigawatt/cruisarr) as a removable Boudoirr default. Use this chart reference to review image access, container settings, and generated configuration. Follow the [Cruisarr setup guide](../../../docs/project-guides/cruisarr.md) to launch the service and connect applications.

## Select the service

Both CLI generation and the interactive picker select Cruisarr initially for Boudoirr. Use `REMOVE_SERVICES=cruisarr` or clear its checkbox to omit it. Jellyfin is also removable. Other presets can add either service explicitly.

Whisparr and Jellyfin are recommended integrations rather than required local containers. Jellyfin provides owner setup and user authentication; Whisparr v3 fulfills approved requests. Either server can run in another project or on another host.

## Image access and updates

The chart defaults to `CRUISARR_IMAGE=ghcr.io/scottgigawatt/cruisarr` and `CRUISARR_TAG=latest`. The private package supports `linux/amd64` and `linux/arm64`; ARMv7 is not supported. Authenticate the deployment host to GitHub Container Registry (GHCR) with package-read access before pulling. Keep registry tokens out of the generated environment. See [authentication and image selection](../../../docs/project-guides/cruisarr.md#authenticate-and-select-the-image).

Cruisarr is excluded from Watchtower updates. Use an authenticated manual pull and recreation after backing up its data. Release checks default to disabled because the repository is private.

## Runtime and storage

The container runs as `DEFAULT_PUID:DEFAULT_PGID` with `DEFAULT_GROUP`. Ensure that this host identity can write the `/data` bind mount. The persistent database is `cruisarr.sqlite` under `/data`. Cruisarr connects to media services over the network and needs no media mounts, named volumes, or separate database containers.

Plundarr adds a read-only root filesystem, dropped capabilities, and `no-new-privileges`. The memory-backed `/tmp` filesystem allows up to 64 MiB of disposable scratch space. This limit is a Plundarr allowance, not an upstream memory-sizing recommendation.

The Node.js `/api/status` healthcheck follows [Cruisarr's Dockerfile](https://github.com/scottgigawatt/cruisarr/blob/main/Dockerfile) with shared Plundarr timing. It checks storage readiness without requiring completed owner setup. Health does not prove that sign-in or provider connections work. No `depends_on` entries are needed because integrations are configured after startup and can run externally.

## Generated configuration

Maraudarr generates both required secrets once and preserves existing assignments. Keep `CRUISARR_SECRET_KEY` with off-host backups and read `CRUISARR_SETUP_SECRET` locally for initial setup. Homepage receives a link card only when both services are selected.

The generated [application data README](config/README.md) describes local storage and backup boundaries. Use the [setup guide](../../../docs/project-guides/cruisarr.md) for connection URLs, browser access, and the complete backup and recovery procedures.
