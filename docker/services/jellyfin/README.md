# Jellyfin service chart 📽️

Adds the official Jellyfin container image with one writable `/data` media root, persistent config and cache paths, a rootless host identity, and an optional Homepage card. Jellyfin's own library configuration chooses the `movies`, `tv`, or `scenes` directories beneath `/data`.

Jellyfin is selected by default in Boudoirr alongside Velvarr and remains removable. Use `REMOVE_SERVICES=jellyfin` or clear its checkbox when an existing server provides playback and Velvarr login. The Boudoirr host web port defaults to `18096`; the internal port stays `8096`, with movies and scenes beneath `/data`. The Homepage widget connects to the internal `8096` port independently of the published host-port offset. The standalone Jellyfin preset keeps Jellyfin as its core service.
