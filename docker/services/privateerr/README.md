# Privateerr service chart 🕵️

Generates PIA WireGuard configuration and metadata before Gluetun starts. The Compose chart, environment fragment, and generated config notes live together here so Maraudarr can treat Privateerr as one modular service.

## Choose a region 🧭

The generated `.env` includes `PIA_AUTOCONNECT=true`, `PIA_PREFERRED_REGION=ca`, and `PIA_PF=true`. Automatic selection ignores the preferred region. Set `PIA_AUTOCONNECT=false` to select Montreal, or change `PIA_PREFERRED_REGION` to another PIA region ID. Port-forwarding support is advertised by PIA; it is not a live API availability check.

Recreate the complete stack after editing `.env`; a plain restart does not reload its settings. Privateerr generates the configuration and metadata before Gluetun starts. See the [VPN region setup guide](../../../docs/project-guides/vpn.md) for deployment commands and Synology guidance.
