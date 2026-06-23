# ⚓ qBittorrent Configuration 🏴‍☠️

Avast, me hearties! This be the treasure trove holdin' the configuration files fer the **qBittorrent** service. These files will be mounted into the qBittorrent container as the service config directory, guidin' yer downloads to port.

## Purpose 🌊

qBittorrent be yer steadfast mate, helpin' ye manage and organize yer downloads with ease, plunderin' the digital depths for all yer desired treasures.

## Port Forwarding 🧭

Gluetun updates qBittorrent's listening port when PIA assigns a forwarded port. For that local API call to work, enable qBittorrent's Web UI setting to bypass authentication for clients on localhost.

When the port-forwarding script runs, it sets qBittorrent to:

- Listen on Gluetun's forwarded port.
- Bind to Gluetun's VPN interface.
- Disable random ports.
- Disable UPnP port mapping.

Fer more details, set yer spyglass on the [docker-compose.yml](../../docker-compose.yml) file in the root of the repository.

May yer sails be full and yer seas calm as ye plunder the digital depths! ⚔️🌊
