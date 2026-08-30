# Add a Maraudarr service 🧩

A selectable service is a complete, testable catalog unit. Keep each addition small enough to review as one service contract rather than scattering optional fragments through aggregate files.

## Create the required files

Create this structure:

```text
docker/services/example/
├── README.md
├── compose.yml
├── environment.env
└── config/
    └── README.md
```

Then add one explicit table to `docker/catalog/catalog.toml`:

```toml
# Describe the service's role immediately above its catalog table.
[services.example]
title = "Example"
description = "Explains what the service contributes to the stack."
category = "Category"
url = "https://example.com"
order = 999
requires = ["required-service"]
```

Write the service README for maintainers: state what the chart owns, name its unusual dependencies or integration points, and link to upstream documentation. Write the config README for operators: explain durable or sensitive state, first-launch actions, paths that must match another service, and what regeneration may replace. Skip empty boilerplate sections and keep pirate flavor to a light signoff or transition.

## Follow the Compose contract

- Reuse the narrowest shared container and environment anchors.
- Keep image repository and tag in `.env` variables.
- Preserve `${VARIABLES}` in generated output.
- Use the same internal download and media paths as connected services.
- Route downloader traffic through Gluetun with `network_mode` when required.
- Prefer a direct `CMD` healthcheck; use `CMD-SHELL` only for genuine shell expansion or compound logic.
- Add `depends_on` health conditions only for real startup requirements.
- Use two spaces before inline Compose comments and align logical groups.

## Handle environment values and secrets

Put service-owned defaults in `environment.env`. Never place real credentials in source. If a safe first run requires a generated secret, add that variable to `_generate_first_run_secrets` and test both fresh generation and preservation of an existing value.

Avoid duplicating credentials for integrations. For example, a Homepage widget should normally reuse the selected service's generated username, password, or API-key variable.

## Add conditional integrations

Update only integrations that the service actually consumes:

- Gluetun host-port insertion for VPN-shared services.
- Homepage Compose variables, environment groups, and service-card fragments.
- UI completion paths for generated config directories.
- Runtime health loops when the selected service participates in E2E tests.
- Root documentation for discoverability and generation commands.

Keep the default preset unchanged unless the service is intentionally becoming default cargo. An opt-in addition should leave the checked-in default Compose and example environment byte-identical after regeneration.

## Run the required validation

Add focused unit coverage for dependency resolution, conditional omission, rendered comments and variables, secret behavior, healthcheck style, and config seeding. Add a representative matrix voyage that selects the new service and passes `docker compose config --quiet`.

Before publishing, run:

```sh
make test
make build
make build-platforms
make docs
pre-commit run --all-files
git diff --check
```

Live E2E validation that requires private credentials is a separate deployment check. Report an unavailable external dependency honestly rather than treating it as source validation success or failure.
