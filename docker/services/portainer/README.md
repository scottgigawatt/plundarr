# Portainer service chart 🚢

Runs Portainer Community Edition using the official `lts` image channel. The standalone `portainer` preset contains only this service; add it explicitly to another preset when needed.

Portainer manages the local Docker host through its Docker socket. Its database and configuration live at `PORTAINER_CONFIG_PATH`, defaulting to `./config/portainer`. Portainer is eligible for automatic updates on its configured image tag when Watchtower monitors the host; the default tag is `lts`.

See the [Portainer deployment guide](../../../docs/project-guides/portainer.md) for startup, configurable ports, and initial setup.
