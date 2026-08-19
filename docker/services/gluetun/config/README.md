# 🛡️ Gluetun Configuration ⚓️

Greetings, pirate crew! This be the treasure trove holdin' the configuration files fer the **Gluetun** service. These precious files will be mounted into the Gluetun container as the service config directory, keepin' yer voyages secure.

## Purpose 🌊

Gluetun be yer steadfast mate, providin' secure PIA WireGuard VPN connections and port forwarding to ensure yer online activities be safe from pryin' eyes and treacherous waters.

Privateerr writes `wireguard/wg0.conf` and `wireguard/privateerr.env` before Gluetun starts. The wrapper at [`scripts/gluetun-entrypoint-wrapper.sh`](scripts/gluetun-entrypoint-wrapper.sh) waits for that metadata, exports `PIA_WG_SERVER_NAME` as Gluetun's `SERVER_NAMES`, and then starts Gluetun's original entrypoint so PIA port forwarding can claim the right harbor.

When PIA assigns or removes a forwarded port, Gluetun calls [`scripts/qbittorrent-port-forwarding.sh`](scripts/qbittorrent-port-forwarding.sh) to update qBittorrent's listening port through its local Web API.

> [!TIP]
> PIA port forwarding needs `SERVER_NAMES` when Gluetun runs with `VPN_SERVICE_PROVIDER=custom`, `VPN_TYPE=wireguard`, and `VPN_PORT_FORWARDING=on`.

Fer more information, cast yer eye on the generated
`dist/<preset>/docker-compose.yml` and `.env` files.

Smooth sailin' with secure VPN connections, mateys! 🌊🏴‍☠️
