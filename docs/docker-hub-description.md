# Maraudarr 🏴‍☠️⚒️

Maraudarr generates a [Plundarr](https://github.com/scottgigawatt/plundarr) media stack from your selected preset and services, then exits. You receive one commented Docker Compose file, an editable `.env`, and initial application configuration.

## Generate your stack

Follow the [interactive quickstart](https://scottgigawatt.github.io/plundarr/setup/#generate-a-deployment) to run the published image with Docker. Git, Make, and local builds are optional. Review credentials, host paths, ownership, ports, and application prerequisites before starting the generated project.

## Images and platforms

Images are available as `ghcr.io/scottgigawatt/maraudarr` and `docker.io/scottgigawatt/maraudarr`. Use `latest` for stable, `edge` for the newest successful main build, or an exact version/digest. Supported platforms are amd64, arm64, and arm/v7; selected application images may support fewer platforms. Builds include OCI metadata, SBOMs, provenance, and vulnerability scanning.

Use [setup](https://scottgigawatt.github.io/plundarr/setup/) for first login and [maintenance](https://scottgigawatt.github.io/plundarr/maintain/) for updates and backups. [Developer documentation](https://scottgigawatt.github.io/plundarr/development/maraudarr/) covers local builds and extensions.
