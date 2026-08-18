# Jellyfin Service Chart 📽️

Adds the official Jellyfin container image with one writable `/data` media
root, persistent config and cache paths, a rootless host identity, and an
optional Homepage card. Jellyfin's own library configuration chooses the
`movies`, `tv`, or `scenes` directories beneath `/data`.
