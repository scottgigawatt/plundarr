# Whisparr Alt configuration 🔞

This directory holds the second Whisparr instance's database, API key, and settings independently of the primary instance. Movies, scenes, shared import staging, recycling, and downloads use separate mounts configured in `.env`.

Export backups through Whisparr and store copies outside this directory. Stop this instance before copying the whole directory for a filesystem backup.

The temporary `/data` parent is not application storage. Persistent media lives in its mounted children; configure the application root as `/data`, the import folder format as `import`, and the recycling bin as `/data/recycle`.
