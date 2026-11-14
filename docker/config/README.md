# Application configuration

This directory contains persistent configuration for your selected services. Read each service subdirectory's README for its first-run settings and storage boundaries. The deployment's private `.env` lives one directory above this one.

Maraudarr adds missing seeds and preserves application state during generation. External libraries/configuration and named Docker volumes are separate storage locations. Keep a complete recovery set covering all of them. `make down` and `make remove-stack` preserve this directory and saved VPN settings.

## Back up or reset the hold 🧽

Before creating a file-copy archive, make application-consistent backup exports and stop affected services cleanly so databases, journal files, and other configuration are no longer changing. Copying a database that is still being written is not an application-consistent backup. Stopping services interrupts their applications and may interrupt VPN/download activity; plan the maintenance window first.

The host config archive does not include the deployment's `.env`, external Kometa checkout, or named-volume databases. Export named-volume application data separately and retain matching encryption keys, private settings, and external state with the recovery set. Keep affected services stopped while the archive is created:

From the generated project directory, use a unique destination outside `config/` for the archive. Replace `BACKUP_FILE` with an absolute filename in your backup storage:

```sh
tar -czf BACKUP_FILE config
```

From a repository checkout, `make backup PRESET=YOUR-PRESET` creates a timestamped config archive. Replace `YOUR-PRESET` with the selected preset ID.

Verify the archive and a recoverable off-host copy before resetting anything. If this was only a backup, restart the services deliberately after verification. For a reset or restore, leave affected services stopped until the replacement state and permissions are ready.

> [!CAUTION]
> `make delete-config` irreversibly deletes the selected host config tree and any backups stored inside it. Stop affected services and verify a recoverable backup before proceeding. Named-volume data requires separate management.

Use `make delete-config PRESET=YOUR-PRESET` only from a checkout after that review. Regenerating the complete service selection recreates missing seeds; it does not restore databases, secrets, external state, or operator edits.

> [!CAUTION]
> Do not commit API keys, passwords, VPN credentials, generated WireGuard configuration, or other private application state.
