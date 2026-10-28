<!--
  Copyright 2025-2026 Scott Gigawatt

  Licensed under the Apache License, Version 2.0.

  README.md: Describe Maraudarr's unit, integration, and fuzz testing layout.
  -->

# Maraudarr test hold 🧪

Unit tests here cover catalog resolution, comment-preserving rendering, environment-value preservation, generated secrets, Homepage cards, and config directory generation.

The repository-level matrix in `test/generator/test-maraudarr-matrix.sh` complements these tests with real `docker compose config` validation across representative presets and service combinations.

Coverage-guided harnesses live in `fuzz/`. ClusterFuzzLite packages them with Atheris and exercises relevant parser changes during pull-request validation.

The VPN recovery cases cover paired-service defaults, generated API keys, preserved operator settings, forwarding hooks, consistent qBittorrent Web UI ports, and the image-owned script handoff. Maraudarr seeds no Gluetun scripts and preserves existing runtime files; Privateerr installs its packaged scripts before reporting startup readiness.
