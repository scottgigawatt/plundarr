# Python Documentation Style 📚

Maraudarr documentation should explain contracts and intent without duplicating the implementation. Type annotations remain the source of truth for types; docstrings describe meaning, side effects, invariants, and failure behavior.

## Public APIs

Public modules, classes, methods, and functions use Google-style sections when they add useful information:

```python
def write_stack(
    catalog: Catalog,
    plan: StackPlan,
    output_dir: Path,
) -> tuple[Path, Path, Path]:
    """Generate and validate a complete Plundarr project.

    Args:
        catalog: Validated catalog providing templates and service sources.
        plan: Deterministically ordered service selection to generate.
        output_dir: Directory that receives the generated project.

    Returns:
        Paths to the Compose file, environment file, and config directory.

    Raises:
        RenderError: If Docker Compose rejects the staged project.
        OSError: If an output file cannot be written or replaced.
    """
```

Use `Args`, `Returns`, `Raises`, `Attributes`, or `Note` only when applicable. Do not add an empty section, restate a parameter name as its description, or repeat a type already expressed by the signature.

## Private Helpers

Private helpers are filtered out of the generated API reference, but they are not undocumented. Give every non-obvious helper a concise docstring that states its transformation or safety rule. Add inline comments at decision points where the reason cannot be inferred from the code.

Good private-helper documentation explains matters such as:

- Why a marker-based text edit is safe for the owned template shape.
- Why one environment variable remains generator-owned.
- Why config README files may refresh while application files may not.
- Why validation tolerates a missing Docker executable but rejects bad Compose.

Avoid comments that merely translate the following expression into English.

## Markdown Alerts

Write alerts once using GitHub's supported blockquote syntax:

> [!TIP]
>
> ```text
> > [!IMPORTANT]
> > Explain the required action here.
> ```

GitHub renders that syntax natively. MkDocs enables `pymdownx.quotes` with callout processing, which converts the same source into Material admonitions. The project stylesheet supplies Material treatments for GitHub's `important` and `caution` types. Do not duplicate alerts with MkDocs-only `!!!` syntax.

Put the first quoted prose line immediately below the alert marker without an empty `>` separator. Retain one empty quoted line when the alert begins with a fenced code block or list because Markdown requires it to delimit that block. Keep later empty quoted lines only where they intentionally separate paragraphs or blocks inside the alert. Write ordinary Markdown prose paragraphs on one physical source line and rely on visual editor wrapping.

> [!CAUTION]
> GitHub recognizes only `NOTE`, `TIP`, `IMPORTANT`, `WARNING`, and `CAUTION`. Other labels fall back to an ordinary blockquote instead of an alert.

## Generated Reference Boundary

The MkDocs configuration renders names that do not begin with `_`. This keeps the published reference focused on reusable interfaces while source links and the architecture guide preserve visibility into implementation details.

Run `make docs` after changing Python signatures or docstrings. Strict mode treats malformed cross-references, invalid navigation, and documentation warnings as build failures.
