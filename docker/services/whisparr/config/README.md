# Whisparr configuration 🔞

Whisparr stores its database and application settings here. Its import, movie, scene, recycle, and download mounts are configured separately in the generated preset's `.env` file.

Back up this hold before cleanup with `make backup`.

The temporary `/data` parent is not application storage. Persistent media lives in its mounted children; configure the application root as `/data`, the import folder format as `import`, and the recycling bin as `/data/recycle`.
