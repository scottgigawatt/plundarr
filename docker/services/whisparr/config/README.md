# 🔞 Whisparr Configuration

Whisparr stores its database and application settings here. It sees the
high-level `WHISPARR_DATA_PATH` as `/data` and the shared download tree as
`/downloads`. In Boudoirr, use `/data/scenes` as its root folder.

Connect qBittorrent or SABnzbd through `gluetun` and use a `whisparr` category
that downloads to the `movies` folder described in the selected client's
generated README.

Back up this hold before cleanup with `make backup-config`.
