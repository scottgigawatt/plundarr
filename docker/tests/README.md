# Maraudarr Test Hold 🧪

Unit tests here cover catalog resolution, comment-preserving rendering,
environment-value preservation, generated secrets, Homepage cards, and config
directory generation.

The repository-level matrix in `test/test-maraudarr-matrix.sh` complements
these tests with real `docker compose config` validation across representative
presets and service combinations.
