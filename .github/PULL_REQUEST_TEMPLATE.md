# Pull Request Boarding Pass 🏴‍☠️

## What changed? ⚓

-

## Why? 🧭

-

## Test voyage 🧪

- [ ] `make help`
- [ ] `make test`
- [ ] `make test-workflows` if workflow helpers changed
- [ ] `make docs` if public or developer documentation changed
- [ ] `make ship PRESET=<preset>` if generation behavior changed
- [ ] `make config PRESET=<preset>` if generated Compose changed
- [ ] `make env PRESET=<preset>` if the generated `.env` shape changed
- [ ] `make build` if the Maraudarr image or build context changed
- [ ] `make test-image` if runtime dependencies or the container contract changed
- [ ] `make build-platforms` if image dependencies or build stages changed
- [ ] `make test-vpn` if validating an already-running Privateerr/Gluetun pair
- [ ] `make test-e2e` if VPN, Privateerr, Gluetun, or downloader behavior changed
- [ ] `make test-stack` if Compose healthchecks, service wiring, or full-stack behavior changed
- [ ] `make restore-test-config PRESET=<preset>` restored example generated config
- [ ] `pre-commit run --all-files`

## Secrets check 🛡️

- [ ] No real PIA credentials
- [ ] No live `wg0.conf`
- [ ] No live `privateerr.env`
- [ ] No private logs
- [ ] No live Duplicati encryption key or Web UI password
- [ ] No generated `dist/<preset>/.env` or application state

## Captain's notes 📜

-
