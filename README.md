# Plundarr 🏴‍☠️

Plundarr helps you run a media stack with one Docker Compose file, using Docker Compose or Synology Container Manager. Run Maraudarr, the published generator image, to choose your services and create the stack files, settings, and configuration directories. Then start the generated stack on your Docker host.

<!-- markdownlint-disable-next-line MD033 MD041 -->
<hr />

<!-- markdownlint-disable MD033 -->
<p align="center">
  <em>🏴‍☠️ Enjoyin' the spoils? Drop us a ⭐ an' let the whole crew know this chart helped.</em>
</p>

<p align="center">
  <a href="https://github.com/scottgigawatt/plundarr/stargazers"><img src="https://img.shields.io/github/stars/scottgigawatt/plundarr?style=social&amp;label=Treasure%20Hunters" alt="GitHub stars: Treasure Hunters" /></a>
  <a href="https://github.com/scottgigawatt/plundarr/forks"><img src="https://img.shields.io/github/forks/scottgigawatt/plundarr?style=social&amp;label=Mutinous%20Forks" alt="GitHub forks: Mutinous Forks" /></a>
  <a href="https://github.com/scottgigawatt/plundarr/watchers"><img src="https://img.shields.io/github/watchers/scottgigawatt/plundarr?style=social&amp;label=Crow%27s%20Nest%20Lookouts" alt="GitHub watchers: Crow's Nest Lookouts" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Containers-Ahoy%21-2496ED?logo=docker&amp;logoColor=white" alt="Containers: Ahoy!" />
  <img src="https://img.shields.io/badge/Cloaked-by%20PIA%20%26%20WireGuard-2EA44F?logo=wireguard&amp;logoColor=white" alt="Cloaked by PIA and WireGuard" />
  <a href="./LICENSE"><img src="https://img.shields.io/github/license/scottgigawatt/plundarr?label=Legal%20Scroll&amp;color=8250DF" alt="Legal Scroll: Apache 2.0 license" /></a>
</p>

<p align="center">
  <a href="https://github.com/scottgigawatt/plundarr/commits/main"><img src="https://img.shields.io/github/last-commit/scottgigawatt/plundarr?label=Last%20Plunder&amp;logo=git&amp;color=D97706" alt="Date of the last commit to main" /></a>
  <img src="https://img.shields.io/badge/Sea--Tested-Synology%20%7C%20macOS-0891B2" alt="Sea-tested on Synology and macOS" />
  <img src="https://img.shields.io/badge/Rum%20Supply-Full-C2410C" alt="Rum supply: Full" />
</p>

<p align="center">
  <a href="https://github.com/scottgigawatt/plundarr/actions/workflows/build-and-push.yml"><img src="https://img.shields.io/github/actions/workflow/status/scottgigawatt/plundarr/build-and-push.yml?branch=main&amp;label=Maraudarr%20build&amp;logo=githubactions&amp;logoColor=white" alt="Maraudarr build status on main" /></a>
  <a href="https://hub.docker.com/r/scottgigawatt/maraudarr"><img src="https://img.shields.io/docker/pulls/scottgigawatt/maraudarr?label=Maraudarr%20pulls&amp;logo=docker&amp;logoColor=white&amp;color=FF69B4" alt="Maraudarr image pulls on Docker Hub" /></a>
  <a href="https://github.com/scottgigawatt/plundarr/pkgs/container/maraudarr"><img src="https://img.shields.io/badge/Fleet-amd64%20%7C%20arm64%20%7C%20arm%2Fv7-6D28D9?logo=docker&amp;logoColor=white" alt="Maraudarr images for amd64, arm64, and arm/v7" /></a>
  <a href="https://github.com/scottgigawatt/plundarr/actions/workflows/build-and-push.yml"><img src="https://img.shields.io/badge/Bilge%20Check-Trivy-BE185D?logo=aqua&amp;logoColor=white" alt="Container images scanned with Trivy" /></a>
  <a href="https://www.bestpractices.dev/projects/14767"><img src="https://www.bestpractices.dev/projects/14767/badge" alt="OpenSSF Best Practices status" /></a>
</p>

<p align="center">─── ⛧ ───</p>

<p align="center">
  <em>☠️ Compose in dependency hell? Bribe the ferryman and enter</em>
  <a href="https://discord.gg/BpEGzWwGYf"><img src="https://img.shields.io/discord/1403601106315116626?label=%F0%9F%94%A5HADES%F0%9F%94%A5&logo=discord&logoColor=white&color=5865F2" alt="HADES Discord community" align="absmiddle" /></a>
</p>
<!-- markdownlint-enable MD033 -->

<!-- markdownlint-disable-next-line MD033 -->
<hr />

## Generate the default stack ⚡

You need Docker with Compose, a terminal on your Docker host, writable storage, and an active Private Internet Access (PIA) subscription. The default stack requires an amd64 or arm64 host. You do not need Git, Make, or a local image build.

![Maraudarr's interactive setup selects the default Plundarr services and generates the stack files](docs/assets/maraudarr-demo.gif)

🔎 [View the full-size demo](docs/assets/maraudarr-demo.gif).

Create a directory you own, then open the interactive setup using the published image:

```sh
mkdir -p plundarr
cd plundarr
docker run --rm -it --pull always \
  --user "$(id -u):$(id -g)" \
  --read-only --network none \
  --cap-drop ALL --security-opt no-new-privileges:true \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  --volume "$PWD:/output:rw" \
  ghcr.io/scottgigawatt/maraudarr:latest configure
```

Choose **Plundarr**. Use the arrow keys to move, Space to toggle optional services, and Enter to continue. Keep the defaults for the standard stack. Maraudarr creates `dist/plundarr/docker-compose.yml`, `.env`, `example.env`, and `config/`, then exits.

Open `dist/plundarr/.env` in a text editor. Set PIA credentials, host storage paths, user/group IDs, timezone, and Homepage's browser address. The [setup guide](https://scottgigawatt.github.io/plundarr/setup/#review-the-settings) identifies the required settings and storage preparation before launch. Generated passwords and keys are ready to use; keep them private.

After completing that review, run from the same directory:

```sh
cd dist/plundarr
docker compose config --quiet
docker compose up --detach --pull always
docker compose ps
```

Open Homepage at your Docker host's port `3000` and sign in with `HOMEPAGE_AUTH_PASSWORD` from `.env`. The [first-login steps](https://scottgigawatt.github.io/plundarr/setup/#open-your-applications) cover qBittorrent and the other primary interfaces. Change the port in the address if you customized it.

The Privateerr container generates the PIA WireGuard configuration file; Gluetun runs the VPN connection; qBittorrent downloads through Gluetun. Applications still need their own setup after their containers start. Continue with [connecting your applications in Plundarrpedia](https://scottgigawatt.github.io/plundarrpedia/projects/plundarr/connect-applications/).

<!-- markdownlint-disable-next-line MD033 -->
<a id="customize-a-deployment-"></a>

## Choose a preset 🗺️

The interactive setup offers these starting points. Standalone media-server and utility presets do not require PIA.

<!-- GitHub preserves nowrap cells; samp keeps literal preset IDs monospaced without code's wrapping rules. -->
<!-- markdownlint-disable MD033 -->
<table>
  <thead>
    <tr>
      <th scope="col" align="left" nowrap>🗺️ Preset</th>
      <th scope="col" align="left" nowrap>🎯 Purpose</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td nowrap valign="top">🏴‍☠️ <samp>plundarr</samp></td>
      <td valign="top">Movies, television, and ebooks with VPN-protected torrent downloads</td>
    </tr>
    <tr>
      <td nowrap valign="top">🔞 <samp>boudoirr</samp></td>
      <td valign="top">Whisparr automation with Cruisarr requests, Jellyfin playback, and Stash cataloging</td>
    </tr>
    <tr>
      <td nowrap valign="top">🎞️ <samp>jellyfin</samp></td>
      <td valign="top">Jellyfin media server</td>
    </tr>
    <tr>
      <td nowrap valign="top">📺 <samp>plex</samp></td>
      <td valign="top">Plex Media Server</td>
    </tr>
    <tr>
      <td nowrap valign="top">📚 <samp>calibre-web-automated</samp></td>
      <td valign="top">Ebook library and imports</td>
    </tr>
    <tr>
      <td nowrap valign="top">🎭 <samp>duplex</samp></td>
      <td valign="top">Plex artwork, metadata, theme songs, and maintenance</td>
    </tr>
    <tr>
      <td nowrap valign="top">🔭 <samp>watchtower</samp></td>
      <td valign="top">Container image updates</td>
    </tr>
    <tr>
      <td nowrap valign="top">🚢 <samp>portainer</samp></td>
      <td valign="top">Docker management interface</td>
    </tr>
    <tr>
      <td nowrap valign="top">🧩 <samp>custom</samp></td>
      <td valign="top">Individually selected services</td>
    </tr>
  </tbody>
</table>
<!-- markdownlint-enable MD033 -->

✨ [**Browse the complete preset examples**](examples/presets/README.md) ✨ and inspect each preset’s Compose file and example settings before generating your stack.

Use [customization](https://scottgigawatt.github.io/plundarr/customize/) for service choices, networks, and optional integrations.

## Use the Make helpers

For generation and maintenance shortcuts, clone the repository into a separate directory and run commands from its root:

```sh
git clone https://github.com/scottgigawatt/plundarr.git
cd plundarr
make configure
```

Make uses the published Maraudarr image. Review `dist/plundarr/.env` and prepare storage before `make up`; `make ps` shows status. Use `make help` for available operations. [Local image builds](https://scottgigawatt.github.io/plundarr/development/maraudarr/#choose-the-generator-revision) are available for development.

<!-- markdownlint-disable-next-line MD033 -->
<a id="inspect-and-maintain-the-stack-"></a>
<!-- markdownlint-disable-next-line MD033 -->
<a id="read-more-and-get-help-"></a>

## Maintain the stack and get help

[Maintenance](https://scottgigawatt.github.io/plundarr/maintain/) covers updates, regeneration, backups, and stopping the stack. `make down` preserves images and data. `make clean-artifacts` removes disposable developer files.

> [!CAUTION]
> `make remove-stack` removes the selected stack's Docker resources, the Maraudarr project, and scoped build cache while preserving configuration, application volumes, and backups. `make delete-config` deletes the selected host config tree. Review the selected preset and verify backups before destructive cleanup.

- [Set up Docker or Synology](https://scottgigawatt.github.io/plundarr/setup/): required settings, first login, and troubleshooting.
- [Plundarrpedia](https://scottgigawatt.github.io/plundarrpedia/): connect applications and follow integrated platform guides.
- [Service guides](https://scottgigawatt.github.io/plundarr/project-guides/): VPN, Jellyfin, Stash, Cruisarr, monitoring, and other integrations.
- [Developer documentation](https://scottgigawatt.github.io/plundarr/development/maraudarr/): build, extend, and test Maraudarr.
- [Support](https://scottgigawatt.github.io/plundarr/SUPPORT/), [security](https://scottgigawatt.github.io/plundarr/SECURITY/), [contributing](https://scottgigawatt.github.io/plundarr/CONTRIBUTING/), and [Code of Conduct](https://scottgigawatt.github.io/plundarr/CODE_OF_CONDUCT/).

## Compatibility and licensing ⚖️

Maraudarr supports `linux/amd64`, `linux/arm64`, and `linux/arm/v7`; selected services may support fewer platforms. Plundarr is tested with Synology Container Manager and Docker Desktop on macOS. It uses the [Apache License 2.0](LICENSE) and the published Privateerr image; PIA's manual-connection scripts remain owned by their upstream project.
