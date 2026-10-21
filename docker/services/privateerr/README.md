# Privateerr service chart 🕵️

Generates PIA WireGuard configuration and metadata before Gluetun starts. The Compose chart, environment fragment, and generated config notes live together here so Maraudarr can treat Privateerr as one modular service.

## Choose a region 🧭

The generated `.env` includes `PIA_AUTOCONNECT=true`, `PIA_PREFERRED_REGION=ca`, and `PIA_PF=true`. Automatic selection ignores the preferred region. Set `PIA_AUTOCONNECT=false` to select Montreal, or change `PIA_PREFERRED_REGION` to another PIA region ID. Port-forwarding support is advertised by PIA; it is not a live API availability check.

Recreate the complete stack after editing `.env`; a plain restart does not reload its settings. Privateerr generates the configuration and metadata before Gluetun starts. See the [VPN region setup guide](../../../docs/project-guides/vpn.md) for deployment commands and Synology guidance.

## Automatic Gluetun recovery 🛟

When Gluetun is selected, Maraudarr enables `PRIVATEERR_AUTO_RECOVER=true` and generates a shared control API key in `.env`. Privateerr refreshes stale PIA settings after sustained tunnel failure without recreating Gluetun or dependent applications. The `_SECONDS` timing controls and recovery opt-out are available in the generated environment; regeneration preserves your values. Privateerr without Gluetun leaves recovery disabled.

The selected Privateerr image must support automatic recovery and Docker-applied IPv6 namespace settings. See the [VPN configuration guide](../../../docs/project-guides/vpn.md) for timings, wrapper requirements, and authentication.

The generated service runs without privileged mode and drops all Linux capabilities. Docker applies `PRIVATEERR_IPV6_DISABLED=1` before startup; Privateerr honors `PIA_DISABLE_IPV6=yes` without redundant sysctl writes. UID 0 remains required by the unmodified PIA scripts.
