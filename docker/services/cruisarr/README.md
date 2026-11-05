# Cruisarr service chart 🔞

Adds the private [Cruisarr discovery and request application](https://github.com/scottgigawatt/cruisarr) as a removable Boudoirr default. Use this chart reference to review image access, container settings, and generated configuration. Follow the [Cruisarr setup guide](../../../docs/project-guides/cruisarr.md) to launch the service and connect applications.

## Select the service

Both CLI generation and the interactive picker select Cruisarr initially for Boudoirr. Use `REMOVE_SERVICES=cruisarr` or clear its checkbox to omit it. Jellyfin is also removable. Other presets can add either service explicitly.

Whisparr and Jellyfin are recommended integrations rather than required local containers. Jellyfin provides owner setup and user authentication; Whisparr v3 fulfills approved requests. Either server can run in another project or on another host.

## Image access and updates

The chart defaults to `CRUISARR_IMAGE=ghcr.io/scottgigawatt/cruisarr` and `CRUISARR_TAG=latest`. The private package supports `linux/amd64` and `linux/arm64`; ARMv7 is not supported. Authenticate the deployment host to GitHub Container Registry (GHCR) with package-read access before pulling. Keep registry tokens out of the generated environment. See [authentication and image selection](../../../docs/project-guides/cruisarr.md#authenticate-and-select-the-image).

Cruisarr is excluded from Watchtower updates. Use an authenticated manual pull and recreation after backing up its data. Release checks default to disabled because the repository is private.

## Runtime and storage

The published image defaults to non-root numeric UID/GID `10001:10001`, application code under `/app`, and data under `/data`. Plundarr overrides the runtime identity with `DEFAULT_PUID:DEFAULT_PGID` through Compose `user:` and adds `DEFAULT_GROUP`. Image build arguments such as `CRUISARR_UID` and `CRUISARR_GID` select the image account; setting them as runtime environment variables does not remap the running process.

Prepare the host data directory so the configured runtime identity can write it before launch. Cruisarr does not automatically change existing bind-mount ownership. Application code remains root-owned and readable by the non-root process. The persistent database is `cruisarr.sqlite` under `/data`; no media mounts, named volumes, or separate database containers are required.

Plundarr adds a read-only root filesystem, dropped capabilities, and `no-new-privileges`. The memory-backed `/tmp` filesystem allows up to 64 MiB of disposable scratch space. This limit is a Plundarr allowance, not an upstream memory-sizing recommendation.

The chart checks `/api/status` at the fixed internal port `6699`, using shared Plundarr timing. The current [Cruisarr source Dockerfile](https://github.com/scottgigawatt/cruisarr/blob/main/docker/Dockerfile) builds its image probe from `PORT`; the standard listener remains `6699`. `CRUISARR_WEBUI_PORT` changes only the host port. A custom image build with a different internal listener or data directory requires matching chart ports, probe, and mount targets.

The probe checks storage readiness without requiring completed owner setup. Health does not prove that sign-in or provider connections work. No `depends_on` entries are needed because integrations are configured after startup and can run externally.

## Generated configuration

Maraudarr generates both required secrets once and preserves existing assignments. Keep `CRUISARR_SECRET_KEY` with off-host backups and read `CRUISARR_SETUP_SECRET` locally for initial setup. Homepage receives a link card only when both services are selected.

The generated [application data README](config/README.md) describes local storage and backup boundaries. Use the [setup guide](../../../docs/project-guides/cruisarr.md) for connection URLs, browser access, and the complete backup and recovery procedures.
