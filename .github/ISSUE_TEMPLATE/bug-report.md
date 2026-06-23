---
name: "Bug report for this here vessel 🏴‍☠️"
about: Share a problem so we can patch the hull and keep Plundarr sailing steady ⚓
title: "[BUG] A cursed leak in the hull"
labels: bug
assignees: scottgigawatt

---

**☠️ What went wrong**
Tell me what broke in Plundarr. Keep it short and clear.

**🪝 How to trigger the problem**
List the steps so I can reproduce it.
1.
2.
3.

**🌊 What you expected**
Tell me what should have happened instead.

**📜 Logs or output**
Share safe logs, error messages, or screenshots if you have them.

Useful commands:

```bash
make check-env
make config
make test-vpn
make test-e2e
make test-stack
make reset-service-configs
pre-commit run --all-files
```

**🧩 Your setup**
- Plundarr branch or commit:
- OS and version:
- Docker or Docker Compose version:
- Privateerr image tag:
- Gluetun image tag:

**🧭 Extra details**
Anything else that might help track down the bug.

**🛡️ Secrets check**
- [ ] No real PIA username or password.
- [ ] No live `wg0.conf`.
- [ ] No live `privateerr.env`.
- [ ] No private logs.
- [ ] No live Duplicati encryption key or Web UI password.
