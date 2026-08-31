# Calibre-Web Automated service chart 📚

Adds Calibre-Web Automated as a standalone ebook library or removable Plundarr default. The image keeps its initialization process, receives the shared PUID, PGID, and timezone values, and mounts separate application, ingest, and library directories.

The image currently publishes `linux/amd64` and `linux/arm64` variants. Maraudarr remains architecture-neutral, but this service does not extend CWA to `linux/arm/v7` hosts.

Watchtower does not update CWA automatically. Back up its databases and review upstream release notes before pulling and recreating the service because application upgrades may migrate persistent state.

Use the [Calibre-Web Automated project](https://github.com/crocodilestick/Calibre-Web-Automated) for application setup and the [Homepage Calibre-Web widget guide](https://gethomepage.dev/widgets/services/calibre-web/) for dashboard credential behavior.
