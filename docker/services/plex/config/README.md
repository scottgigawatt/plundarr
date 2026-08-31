# Plex configuration 🎬

Plex stores its server database and transcode workspace beneath this generated service directory by default. Media libraries remain mounted separately and read-only.

Set an optional `PLEX_CLAIM` value in the generated preset's `.env` during first-time setup, then clear it after the server is claimed.
