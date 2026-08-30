# Watchtower Service Chart 🔭

Runs the maintained `nickfedor/watchtower:latest` image as either a persistent
updater or a one-shot update pass. The floating `latest` tag is intentional.

Watchtower can inspect eligible running and stopped containers visible through
the mounted Docker socket. Containers explicitly labeled
`com.centurylinklabs.watchtower.enable=false` remain excluded; Plundarr applies
that protection to Watchtower itself and the Privateerr/Gluetun VPN bootstrap
chain. Run only one persistent Watchtower daemon on a Docker host.

Generate and start the standalone persistent preset:

```sh
make ship PRESET=watchtower
make up PRESET=watchtower
```

Use the same generated project for one update pass without leaving a one-shot
container behind:

```sh
make watchtower-run-once PRESET=watchtower
```

Stop a persistent Watchtower before starting a one-shot pass. Stopped
containers are included in update checks by default but remain stopped after
an update unless `WATCHTOWER_REVIVE_STOPPED` is enabled in the generated `.env`.
