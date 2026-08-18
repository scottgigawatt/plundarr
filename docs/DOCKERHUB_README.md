# Maraudarr 🏴‍☠️⚒️

Maraudarr is the short-lived generator image for
[Plundarr](https://github.com/scottgigawatt/plundarr). It turns presets and
selectable service charts into one commented Docker Compose file, one matching
environment file, and the selected service config directories.

> [!IMPORTANT]
> Plundarr is the generated media stack. Maraudarr creates that stack and exits;
> it is not a long-running media service.

## Quick Voyage

The repository Makefile supplies the hardened Docker invocation:

```bash
git clone https://github.com/scottgigawatt/plundarr.git
cd plundarr
make configure
```

Generated cargo lands in the repository root:

```text
docker-compose.yml
example.env
.env
config/
```

Use `make ship` for the default Plundarr preset, or choose a preset directly:

```bash
make ship PRESET=jellyfin
make ship PRESET=plex
make ship PRESET=boudoirr ADD_SERVICES=jellyfin
```

Review the generated `.env`, then start the stack with `make up`. The complete
beginner and Synology instructions live in the
[Plundarr README](https://github.com/scottgigawatt/plundarr#readme).

## Image Details

- Registries: `ghcr.io/scottgigawatt/maraudarr` and `scottgigawatt/maraudarr`
- Platforms: `linux/amd64`, `linux/arm64`, and `linux/arm/v7`
- Stable tag: `latest`
- Main branch tag: `edge`
- Security: non-root, read-only, no-network generation with dropped capabilities
- Supply chain: Trivy scanning, SBOM, provenance, and OCI metadata

Full commands, tag policy, architecture, and maintenance notes live in the
[Maraudarr README](https://github.com/scottgigawatt/plundarr/tree/main/docker#readme).
