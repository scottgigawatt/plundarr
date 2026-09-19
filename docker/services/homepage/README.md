# Homepage service chart 🗺️

Builds a dashboard from selected service cards. The `config/fragments/` hold contains optional cards, while Maraudarr writes the final `services.yaml`.

Widget passwords use literal YAML scalars so punctuation remains part of the credential. Regenerate the deployment to refresh `config/homepage/services.yaml`, or apply the same format to its existing `password` fields. Other existing configuration, including `settings.yaml`, is preserved; update its background explicitly when changing an existing deployment.
