# Tracearr Redis service chart 📨

Provides Tracearr's private Redis queue and cache with append-only persistence in a project-scoped named volume. No port is published to the host. Tracearr waits for Redis to pass its direct `redis-cli ping` healthcheck.

The image tag is configurable in `.env`. Watchtower updates are disabled for Redis so queue-storage upgrades remain under operator control. See the [monitoring guide](../../../docs/project-guides/monitoring.md) for lifecycle and backup guidance.
