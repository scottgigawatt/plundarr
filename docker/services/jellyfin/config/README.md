# 🎞️ Jellyfin Configuration

Jellyfin stores its database, metadata, plugins, and cache beneath this generated
service directory. The matching paths remain configurable in root `.env`.

Guard this cargo before running `make clean-config`; use `make backup-config`
when ye want a dated archive first.
