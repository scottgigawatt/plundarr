# Service Configuration ⚓

Maraudarr creates one directory here for each selected service. Containers keep
their databases, settings, logs, and generated state in those directories as
defined by `docker-compose.yml` and `.env`.

Regenerating a stack may refresh project-owned README files, but it does not
replace application-owned configuration or databases.

## Back Up or Reset

Archive the complete directory before major changes:

```bash
make backup-config
```

`make clean-config` deliberately deletes this entire directory. The next
generation recreates only the selected service directories and safe seed files.

> [!CAUTION]
> Keep application databases, API keys, VPN files, logs, and other runtime
> state out of Git. The root `.gitignore` excludes generated config by default.
