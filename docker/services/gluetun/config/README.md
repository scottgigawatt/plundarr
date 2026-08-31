# Gluetun configuration 🛡️

Gluetun keeps VPN state and the Privateerr-generated WireGuard files in this directory.

## Follow the Privateerr handoff

Privateerr writes `wireguard/wg0.conf` and `wireguard/privateerr.env` before Gluetun starts. The wrapper at [`scripts/gluetun-entrypoint-wrapper.sh`](scripts/gluetun-entrypoint-wrapper.sh) waits for that metadata, exports `PIA_WG_SERVER_NAME` as Gluetun's `SERVER_NAMES`, and then starts Gluetun's original entrypoint so PIA port forwarding can claim the right harbor.

When PIA assigns or removes a forwarded port, Gluetun calls [`scripts/qbittorrent-port-forwarding.sh`](scripts/qbittorrent-port-forwarding.sh) to update qBittorrent's listening port through its local Web API.

> [!IMPORTANT]
> PIA port forwarding needs `SERVER_NAMES` when Gluetun runs with `VPN_SERVICE_PROVIDER=custom`, `VPN_TYPE=wireguard`, and `VPN_PORT_FORWARDING=on`.

Treat `wireguard/` as sensitive generated state. Inspect the generated `dist/<preset>/docker-compose.yml` and `.env` files for the complete runtime contract.
