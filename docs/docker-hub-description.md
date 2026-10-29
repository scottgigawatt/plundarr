# Maraudarr 🏴‍☠️⚒️

Maraudarr is the short-lived Docker Compose project generator for [Plundarr](https://github.com/scottgigawatt/plundarr). It turns selected presets/services into a complete commented Compose file, matching environment files, and configuration seeds, then exits. It does not run the media services.

## Generate and launch

Follow the [repository quickstart](https://github.com/scottgigawatt/plundarr#generate-the-default-stack-) for prerequisites and one complete setup path. Make supplies the non-root, read-only, networkless generation invocation; configure credentials, host paths, and ports before starting the generated deployment.

`MARAUDARR_IMAGE` selects the packaged catalog. Its default is the stable GHCR image; [generator revision selection](https://github.com/scottgigawatt/plundarr/blob/main/docs/development/maraudarr/index.md#choose-the-generator-revision) explains source builds and version-matched documentation. Use `make configure` for interactive selection or `make ship PRESET=YOUR-PRESET` for a named preset.

## Image channels and platforms

- Registries: `ghcr.io/scottgigawatt/maraudarr` and `docker.io/scottgigawatt/maraudarr`.
- Platforms: `linux/amd64`, `linux/arm64`, and `linux/arm/v7`; third-party services may support fewer.
- `latest`: stable release; `edge`: successful `main` build; `sha-...`: source revision.
- Stable releases publish exact, minor, and major aliases; major zero has no `0` alias. Prereleases publish exact and revision tags only.
- Builds include OCI metadata, an SBOM, provenance, and vulnerability scanning.

See the [Maraudarr README](https://github.com/scottgigawatt/plundarr/tree/main/docker#readme) for runtime guardrails and the [setup guide](https://github.com/scottgigawatt/plundarr/blob/main/docs/setup.md) for deployment. Keep generated `.env`, VPN files, and application state private.
