# Whisparr Alt configuration 🔞

This directory holds the second Whisparr instance's database, API key, and settings independently of the primary instance. Shared import staging, movies, scenes, recycling, and downloads use separate mounts configured in `.env`.

Choose **TMDB** or **TPDB** under **Settings → General → Movie metadata source** before importing movies. Fresh Whisparr v3 instances default to TMDB; scenes use StashDB. To use both movie providers, provision a second instance and choose a different provider in each. Either instance can use either provider. Host directory names do not select it. Regeneration preserves existing paths, databases, and provider settings; it does not convert records or move files.

Export backups through Whisparr and store copies outside this directory. Stop this instance before copying the whole directory for a filesystem backup.

The temporary `/data` parent is not application storage. Persistent media lives in its mounted children; configure the application root as `/data`, the import folder format as `import`, and the recycling bin as `/data/recycle`.
