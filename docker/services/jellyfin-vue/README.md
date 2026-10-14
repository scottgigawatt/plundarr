# Jellyfin Vue service chart 🎞️

Adds the official [Jellyfin Vue](https://jellyfin.org/docs/general/clients/jellyfin-vue/) browser client as an opt-in service. Upstream supports only its experimental `unstable` image channel. The image currently publishes `linux/amd64` and `linux/arm64`; it does not publish `linux/arm/v7`.

Select `jellyfin-vue` in Maraudarr or use `ADD_SERVICES=jellyfin-vue`. Boudoirr already includes removable Jellyfin playback; the standalone Jellyfin preset keeps its server as core. Vue recommends Jellyfin without forcing a local server, allowing an existing external server. There is no startup dependency: nginx serves the frontend while the browser connects directly to the selected server.

The base web port is `8082`, offset to `18082` in Boudoirr and `28082` in the standalone Jellyfin preset. Set `JELLYFIN_VUE_DEFAULT_SERVERS` to comma-separated URLs reachable from client devices, or leave it empty for manual selection. Docker service names and loopback addresses normally cannot identify the server from a remote browser. Keep server selection enabled until the default URL works. An HTTPS frontend needs an HTTPS server URL to avoid mixed-content blocking.

The upstream image runs as its own `nginx` user and writes `/usr/share/nginx/html/config.json` during startup. Reuse only the default container anchor, retain that identity, and keep the image filesystem writable. Vue needs no media mounts, API keys, Docker socket, config seeds, or persistent application volumes. Its healthcheck tests static asset delivery rather than Jellyfin connectivity.

Jellyfin Web's `config.json`, menu links, and Branding CSS do not configure Vue. Vue uses [its own environment-based configuration](https://github.com/jellyfin/jellyfin-vue/wiki/Configuration). Homepage receives a separate click target only when both services are selected. Existing Watchtower policy controls eligible image updates; adding Vue does not add an updater.
