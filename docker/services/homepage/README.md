# Homepage service chart 🗺️

Builds a dashboard from the selected services. Maraudarr assembles their cards into `config/homepage/services.yaml` and refreshes that file during regeneration. Widget passwords use literal YAML scalars to preserve punctuation.

Existing `settings.yaml` is preserved. Fresh deployments use `/images/backgrounds/canyon-waterfall.gif`; change `background` in an existing file to select it there.
