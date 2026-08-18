# 🎞️ Jellyfin Configuration

Jellyfin stores its database, metadata, plugins, and application logs beneath
`config/`; its disposable transcode and image cache lives beneath `cache/`.
Both directories are created here and remain configurable in the generated
preset's `.env` file.

The official image writes application logs beneath `/config/log`, so the
persistent `/config` mount already keeps them without a separate log volume.
Jellyfin receives the high-level media directory as writable `/data`; create
libraries from the folders beneath it, such as `/data/movies` and `/data/tv` or
`/data/movies` and `/data/scenes` for a Boudoirr voyage.

Guard this cargo before running `make clean-config`; use `make backup-config`
when ye want a dated archive first.
