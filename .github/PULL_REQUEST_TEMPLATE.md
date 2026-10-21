# Pull Request Boarding Pass 🏴‍☠️

## What changed? ⚓

-

## Why? 🧭

-

## Test voyage 🧪

Replace `YOUR-PRESET` with the selected catalog preset ID, such as `boudoirr`. Use a disposable checkout/deployment on an isolated Docker test daemon for live tests and reset commands; keep interpolated output from `make config` and `make env` private because it may contain credentials.

- [ ] `make help`
- [ ] `make test`
- [ ] `make test-workflows` if workflow helpers changed
- [ ] `make docs` if public or developer documentation changed
- [ ] `make ship PRESET=YOUR-PRESET` if generation behavior changed
- [ ] `make config PRESET=YOUR-PRESET` if generated Compose changed
- [ ] `make env PRESET=YOUR-PRESET` if the generated `.env` shape changed
- [ ] `make build` if the Maraudarr image or build context changed
- [ ] `make test-image` if runtime dependencies or the container contract changed
- [ ] `make build-platforms` if image dependencies or build stages changed
- [ ] `make test-vpn PRESET=YOUR-PRESET` if validating an already-running Privateerr/Gluetun pair
- [ ] `make test-e2e PRESET=YOUR-PRESET` if VPN, Privateerr, Gluetun, or downloader behavior changed
- [ ] `make test-stack PRESET=YOUR-PRESET` if Compose healthchecks, service wiring, or full-stack behavior changed
- [ ] `make restore-test-config PRESET=YOUR-PRESET` used only after disposable live tests; no operator config was reset
- [ ] Any `make nuke PRESET=YOUR-PRESET` validation used only an isolated disposable preset/project
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
