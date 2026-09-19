# Homepage service chart 🗺️

Builds a dashboard from selected service cards. The `config/fragments/` hold contains optional cards, while Maraudarr writes the final `services.yaml`.

Native password login is enabled by default. Maraudarr generates and preserves the password and session secret in `.env`; configure the browser URL and allowed host before launch. See [Homepage password login](config/README.md#configure-password-login) for HTTPS reverse-proxy setup and existing-deployment guidance.
