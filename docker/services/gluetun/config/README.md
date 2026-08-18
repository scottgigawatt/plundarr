# 🛡️ Gluetun Configuration

Gluetun stores its VPN state here. Privateerr writes `wireguard/wg0.conf` and
`wireguard/privateerr.env`; the included entrypoint waits for those files before
starting Gluetun.

When PIA assigns a forwarded port, Gluetun updates qBittorrent through its local
web API. Keep qBittorrent's localhost authentication bypass enabled so this update
can succeed.

> [!TIP]
> PIA port forwarding requires `VPN_SERVICE_PROVIDER=custom`,
> `VPN_TYPE=wireguard`, and `VPN_PORT_FORWARDING=on`.
