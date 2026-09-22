<!--
  Copyright 2025-2026 Scott Gigawatt

  Licensed under the Apache License, Version 2.0.

  README.md: Describe Maraudarr's unit, integration, and fuzz testing layout.
  -->

# Maraudarr test hold 🧪

Unit tests here cover catalog resolution, comment-preserving rendering, environment-value preservation, generated secrets, Homepage cards, and config directory generation.

The repository-level matrix in `test/generator/test-maraudarr-matrix.sh` complements these tests with real `docker compose config` validation across representative presets and service combinations.

Coverage-guided harnesses live in `fuzz/`. ClusterFuzzLite packages them with Atheris and exercises relevant parser changes during pull-request validation.

The VPN recovery cases cover paired-service defaults, generated API keys, preserved operator settings, forwarding hooks, and safe wrapper upgrades. `fixtures/gluetun-legacy/gluetun-entrypoint-wrapper.sh` is the exact pre-recovery wrapper from commit `5a5dc2f`; retain its original bytes so migration checks exercise the real previous deployment file.
