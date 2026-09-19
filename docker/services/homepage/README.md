# Homepage service chart 🗺️

Builds a dashboard from selected service cards. The `config/fragments/` hold contains optional cards, while Maraudarr writes the final `services.yaml`.

Widget passwords use literal YAML scalars so punctuation remains part of the credential. Existing generated configuration is preserved: apply the same format to `password` fields in an existing `config/homepage/services.yaml` when updating.
