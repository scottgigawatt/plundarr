# Jellyfin configuration 🎞️

Jellyfin stores its database, metadata, plugins, and application logs beneath `config/`; its disposable transcode and image cache lives beneath `cache/`. Both directories are created here and remain configurable in the generated preset's `.env` file.

The official image writes application logs beneath `/config/log`, covered by the persistent `/config` mount. Jellyfin receives the high-level media directory as writable `/data`; configure libraries using their actual folders. Boudoirr's main Whisparr libraries are `/data/movies/main` and `/data/scenes/main`; an optional Alt instance uses `/data/movies/alt` and `/data/scenes/alt`. Keep import and recycle directories outside library selections.

Back up application-consistent state before destructive `make delete-config` cleanup. From the repository root, select the intended preset explicitly with `make backup PRESET=jellyfin` (or `PRESET=boudoirr`). Follow the [shared backup procedure](https://github.com/scottgigawatt/plundarr/blob/main/docker/config/README.md#back-up-or-reset-the-hold-) for stopped writers, external state, database exports, and recovery coverage.

The `web/` directory contains operator-owned Web settings and locally served theme assets. Regeneration creates missing seeds and preserves existing JSON and CSS. Read [Web customization](web/README.md) before selecting an external configuration path or enabling the theme. These frontend files are separate from the server database and plugin settings.
