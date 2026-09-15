# Tracearr database service chart 🗄️

Provides the TimescaleDB HA image with PostgreSQL 18 and TimescaleDB Toolkit recommended by [Tracearr's installation guide](https://docs.tracearr.com/getting-started/installation). The tag is pinned in the environment fragment so database upgrades remain explicit.

The database is reachable only through the project network. Its generated password is shared with Tracearr through one `.env` variable. A project-scoped named volume owns PostgreSQL data; shared memory, file limits, and database settings follow the upstream deployment requirements. Watchtower updates are disabled.

Use Tracearr's built-in consistent backup and restore workflow. Raw live database files are not a portable backup. See the [monitoring guide](../../../docs/project-guides/monitoring.md).
