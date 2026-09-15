# Tracearr backup exports 🔎

Tracearr stores its database and backup workspace in project-scoped Docker volumes, not this directory. This host directory can hold exported backups for your usual backup tooling.

Create a backup through Tracearr's web interface or its backup CLI, then export `/data/backup/` from the `tracearr` service into this directory. The repository's `make backup` command archives host config files only; it does not dump Tracearr's database. Keep a separate copy of exports and the generated `.env`.

Regeneration preserves exports. `make nuke` removes the database and backup volumes, while `make delete-config` removes this host directory and its exports. Export and verify a backup before destructive cleanup.

See the [monitoring guide](https://github.com/scottgigawatt/plundarr/blob/main/docs/project-guides/monitoring.md) for complete commands and supported setup.
