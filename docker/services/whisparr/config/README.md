# Whisparr configuration 🔞

Whisparr stores its database and application settings here. Its import, movie, scene, recycle, and download mounts are configured separately in the generated preset's `.env` file.

Fresh Whisparr v3 instances use **TMDB** for movie metadata and collections. Confirm **Settings → General → Movie metadata source** is **TMDB** before importing movies. Scenes use StashDB. Use the optional Whisparr Alt instance with **TPDB** for movies TMDB cannot match. Regeneration preserves existing paths, databases, and provider settings; it does not convert records or move files.

Back up this hold before cleanup with `make backup`.

The temporary `/data` parent is not application storage. Persistent media lives in its mounted children; configure the application root as `/data`, the import folder format as `import`, and the recycling bin as `/data/recycle`.
