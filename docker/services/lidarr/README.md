# Lidarr service chart 🎵

Automates a music library and shares download storage with selected clients. Its catalog dependency adds Prowlarr and the indexing chain. Fresh environments default `HOST_MUSIC_PATH` to `/volume1/music/Music/Media/Music`; operators can replace it with their host library path.

The [LinuxServer Lidarr image](https://docs.linuxserver.io/images/docker-lidarr/) supports `linux/amd64` and `linux/arm64`. It does not publish a `linux/arm/v7` image, so 32-bit ARM hosts cannot run stacks that select Lidarr.
