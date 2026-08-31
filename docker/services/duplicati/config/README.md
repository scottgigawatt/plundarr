# Duplicati configuration 🔄

Duplicati stores backup definitions, schedules, logs, and its local database in this directory. The backup source and destination mounts remain separate and are selected through the generated preset's `.env` file.

Before first launch, set `DUPLICATI_SETTINGS_ENCRYPTION_KEY` and `DUPLICATI_WEBSERVICE_PASSWORD` in `.env`. A missing encryption key prevents a new configuration from initializing, while losing an existing key can make stored settings unreadable.

> [!IMPORTANT]
> Preserve the encryption key with the backup metadata, but never commit it to the repository.
