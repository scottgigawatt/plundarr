# Gluetun service chart 🛡️

Runs the VPN tunnel used by selected download clients. Maraudarr adds only the ports and qBittorrent forwarding hooks required by the selected cargo.

With Privateerr recovery enabled, the wrapper prepares a private control API role, exposes the health listener to the shared Docker network, and disables competing health-triggered VPN restarts. API and health ports remain unpublished. Gluetun continues to own the VPN tunnel, firewall, and port forwarding. Set `PRIVATEERR_AUTO_RECOVER=false` in the generated `.env` to use the normal Gluetun restart policy.

Privateerr installs the startup wrapper and qBittorrent forwarding hook in the shared `/gluetun/scripts` directory before becoming healthy. Gluetun consumes them through its existing configuration mount; Maraudarr does not supply separate script files. The two packaged script paths belong to Privateerr.
