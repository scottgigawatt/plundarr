# Jellyfin configuration 🎞️

Jellyfin stores its database, metadata, plugins, and application logs beneath `config/`; its disposable transcode and image cache lives beneath `cache/`. Both directories are created here and remain configurable in the generated preset's `.env` file.

The official image writes application logs beneath `/config/log`, so the persistent `/config` mount already keeps them without a separate log volume. Jellyfin receives the high-level media directory as writable `/data`; create libraries from the folders beneath it, such as `/data/movies` and `/data/tv` or `/data/movies` and `/data/scenes` for a Boudoirr voyage.

Guard this cargo before running `make delete-config`; use `make backup` when ye want a dated archive first.

The `web/` directory contains operator-owned Web settings and locally served theme assets. Regeneration creates missing seeds and preserves existing JSON and CSS. Read [Web customization](web/README.md) before selecting an external configuration path or enabling the theme. These frontend files are separate from the server database and plugin settings.
