# Gluetun configuration 🛡️

Gluetun keeps VPN state and the Privateerr-generated WireGuard files in this directory.

## Follow the Privateerr handoff

Privateerr writes `wireguard/wg0.conf` and `wireguard/privateerr.env` before Gluetun starts. The wrapper at [`scripts/gluetun-entrypoint-wrapper.sh`](scripts/gluetun-entrypoint-wrapper.sh) waits for that metadata, exports `PIA_WG_SERVER_NAME` as Gluetun's `SERVER_NAMES`, and then starts Gluetun's original entrypoint so PIA port forwarding can claim the right harbor.

When PIA assigns or removes a forwarded port, Gluetun calls [`scripts/qbittorrent-port-forwarding.sh`](scripts/qbittorrent-port-forwarding.sh) to update qBittorrent's listening port through its local Web API.

> [!IMPORTANT]
> PIA port forwarding needs `SERVER_NAMES` when Gluetun runs with `VPN_SERVICE_PROVIDER=custom`, `VPN_TYPE=wireguard`, and `VPN_PORT_FORWARDING=on`.

Treat `wireguard/` as sensitive generated state. Inspect the generated `dist/<preset>/docker-compose.yml` and `.env` files for the complete runtime contract.

## Automatic recovery 🛟

Paired Privateerr and Gluetun deployments enable recovery by default. The wrapper prepares internal health access and a temporary authenticated control API role using the shared key from `.env`. Privateerr refreshes stale connection settings through that API; Gluetun continues running and retains its shared network namespace. Neither API nor health ports are published to the host.

Regeneration upgrades the unchanged previous bundled wrapper. Customized or symlinked scripts remain untouched and need manual review before enabling recovery. Existing `auth/config.toml` files are also preserved; add the recovery role described in [Privateerr's recovery guide](https://github.com/scottgigawatt/privateerr/blob/main/docs/automatic-recovery.md), or set `PRIVATEERR_AUTO_RECOVER=false` in `.env` before recreating the stack.
