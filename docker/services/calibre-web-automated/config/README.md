# Calibre-Web Automated configuration 📚

Calibre-Web Automated stores users, settings, migration state, logs, plugins, processed-book backups, and application databases beneath `config/`. Preserve the complete directory, including hidden files, when moving an existing deployment.

The `ingest/` directory is temporary incoming cargo. CWA removes files after processing them, so never point another application's active download directory here or place incomplete downloads inside it. Finish each download elsewhere and move the completed book into this directory.

The ebook library remains external by default at `CWA_LIBRARY_PATH` and mounts at `/calibre-library`. It must contain the Calibre `metadata.db` and managed book files. Back up both the application configuration and library before an image update or destructive cleanup.

Leave `CWA_NETWORK_SHARE_MODE=false` for local Synology volumes. Set it to `true` only when the application configuration or library uses NFS or SMB so CWA can use its network-share-safe database and watcher behavior.
