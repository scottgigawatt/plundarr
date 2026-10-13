# Whisparr configuration 🔞

Whisparr stores its database and application settings here. Its import, movie, scene, recycle, and download mounts are configured separately in the generated preset's `.env` file.

Choose **TMDB** or **TPDB** under **Settings → General → Movie metadata source** before importing movies. Fresh Whisparr v3 instances default to TMDB; scenes use StashDB. To use both movie providers, provision a second instance and choose a different provider in each. Either instance can use either provider. Host directory names do not select it. Regeneration preserves existing paths, databases, and provider settings; it does not convert records or move files.

Back up this hold before cleanup with `make backup`.

The temporary `/data` parent is not application storage. Persistent media lives in its mounted children; configure the application root as `/data`, the import folder format as `import`, and the recycling bin as `/data/recycle`.
