# Pull Request Boarding Pass 🏴‍☠️

## What changed? ⚓

-

## Why? 🧭

-

## Test voyage 🧪

- [ ] `make check-env`
- [ ] `make help`
- [ ] `make config`
- [ ] `make env` if `.env` formatting changed
- [ ] `make test-vpn` if validating an already-running Privateerr/Gluetun pair
- [ ] `make test-e2e` if VPN, Privateerr, Gluetun, or qBittorrent behavior changed
- [ ] `make test-stack` if Compose healthchecks, service wiring, or full-stack behavior changed
- [ ] `make reset-config` restored example generated config
- [ ] `pre-commit run --all-files`

## Secrets check 🛡️

- [ ] No real PIA credentials
- [ ] No live `wg0.conf`
- [ ] No live `privateerr.env`
- [ ] No private logs
- [ ] No live Duplicati encryption key or Web UI password

## Captain's notes 📜

-
