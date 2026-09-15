# Portainer data 🚢

Portainer stores its database, certificates, and configuration here. This directory is mounted at `/data` unless `PORTAINER_CONFIG_PATH` selects another host directory.

Maraudarr adds missing seed files and refreshes this README during regeneration; it preserves existing Portainer data. Back up this directory before intentionally upgrading Portainer. Do not commit the database or generated credentials.
