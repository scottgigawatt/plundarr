# Stash application state

Maraudarr creates the `config`, `metadata`, `cache`, `blobs`, and `generated` directories here when Stash is selected. Their default host paths are relative to the generated project. The `config` child holds `config.yml`, the SQLite database, plugins, and scrapers. Regeneration refreshes this README and preserves application files; removing Stash from a selection also preserves its state.

## Before launch

Confirm that `DEFAULT_PUID`, `DEFAULT_PGID`, and `DEFAULT_GROUP` allow writing all five state directories and reading `STASH_DATA_PATH`. The media mount is read-only. Set a Stash username and password during first-run setup, then scan only the intended video library roots. StashDB and application API keys are separate credentials; enter them in the owning applications and keep them out of logs and source control.

## Backups and recovery

Create a database backup through Stash’s Backup task, then stop Stash before archiving its configuration, database backup, metadata exports, and image storage. Include durable storage paths moved outside this directory. Restore the Stash-created database backup into fresh storage without stale database journal files. Previews and cache can be regenerated, but the default host archive includes them and may be large. Keep the original media and the deployment's `.env` in separate backups.

`make backup PRESET=YOUR-PRESET` archives the selected project's `config/` tree, excluding `.env` and external bind sources. Stopping Stash does not make other applications' databases consistent. Verify the archive and retain an off-host copy before treating it as recoverable.

`make down` and `make nuke` preserve these bind-mounted files. `make delete-config` is destructive and deletes Stash state stored beneath the selected config tree. Do not use it to remove the service. Follow the [Stash backup and recovery procedure](https://github.com/scottgigawatt/plundarr/blob/main/docs/project-guides/stash.md#back-up-and-recover) for a complete recovery set and restore checks.
