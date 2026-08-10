# Plundarr Developer Chart Room 🏴‍☠️

Welcome aboard the developer documentation for **Plundarr** and its generator,
**Maraudarr**. These charts explain how the Python application turns a service
catalog into one comment-rich Docker Compose deployment without trampling
existing user configuration.

## Choose Yer Route 🧭

| Destination                                                   | Best for                                                  |
| :------------------------------------------------------------ | :-------------------------------------------------------- |
| [Maraudarr overview](development/maraudarr/index.md)          | Understanding responsibilities and source layout          |
| [Architecture](development/maraudarr/architecture.md)         | Following data from CLI input to generated files          |
| [Add a service](development/maraudarr/adding-a-service.md)    | Extending the selectable service catalog safely           |
| [Documentation style](development/maraudarr/documentation.md) | Writing useful public docstrings and private-helper notes |
| [Testing](development/maraudarr/testing.md)                   | Selecting the right validation voyage                     |
| [Python reference](development/maraudarr/reference/index.md)  | Looking up public classes and functions from source       |

!!! note

    Plundarr is the generated deployment. Maraudarr is the short-lived Python
    generator that selects, renders, validates, and writes that deployment.

## Documentation Boundaries 📚

This site owns code-adjacent developer documentation and the version-matched
Python reference. User deployment routes and broader fleet guidance remain in
[Plundarrpedia](https://scottgigawatt.github.io/plundarrpedia/), which links
back here rather than copying generated API pages.

The static HTML is generated during validation and deployment. Only the
Markdown sources, MkDocs configuration, and pinned documentation dependencies
belong in Git; the generated `site/` directory does not.
