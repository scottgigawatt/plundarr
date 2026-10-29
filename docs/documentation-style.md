# Documentation style ✍️

Write documentation that helps the intended reader complete a task. Apply GitHub's writing and Markdown guidance together with ISO 24495-1:2023. Keep a little pirate character around clear operational instructions.

## Start with the reader

Every page needs an identifiable audience and purpose. Review it against four required outcomes:

| Outcome | Review question |
| --- | --- |
| Relevant | Does the reader need this information for the task or a useful reference? |
| Findable | Can the reader locate the page and the next action from its navigation and headings? |
| Understandable | Are terms, sentences, examples, and visual structure clear to that reader? |
| Usable | Can the reader act with the supplied prerequisites and recognize success or recover from failure? |

Choose a useful shape: a short concept explanation, a quickstart, a numbered how-to, a lookup reference, or symptom-based troubleshooting. Put prerequisites and required values before steps; optional detail follows the main path.

## Keep one explanation per topic

Plundarr owns generator and service contracts. Privateerr owns its file/API/recovery implementation, Kometa-config owns collection and configuration behavior, and Plundarrpedia owns integrated platform walkthroughs. Link to precise authoritative detail while retaining enough context for a usable local quickstart.

Remove repeated introductions, exhaustive command inventories already covered by `make help`, obsolete history, speculative advice, and implementation narration that does not help the intended reader. Keep currently needed migration/compatibility instructions, security findings, backup coverage, data-loss warnings, licenses, and attribution. Moving text elsewhere is not a reduction in total content.

## Write and format plainly

- Use active voice, direct verbs, familiar words, and one main idea per sentence or paragraph. Explain unfamiliar abbreviations.
- Use exact command, file, service, and UI names. Pirate humor must not carry operational meaning.
- Put the project H1 and purpose before existing badges/community links; preserve their distinct project identity and complete blocks.
- Use searchable sentence-case headings in order. Emoji are decoration after useful words.
- Use numbered lists for procedures, bullets for choices, and tables for genuine comparisons.
- Keep ordinary paragraphs on one physical source line and wrap visually in the editor.
- Use descriptive relative links for repository content and specific upstream links for external detail.
- Keep established community filenames; name ordinary articles with lowercase kebab-case. Update inbound links, anchors, navigation, and route compatibility when consolidating pages.

Commands belong in labelled `sh` fences without prompts or explanatory comments. Use `bash` only for Bash-specific syntax, `console` for transcripts, and `text` for output. Explain placeholders outside fences and use safe example values. Put permissions, service interruptions, destructive risks, and backup prerequisites before the affected command.

## Use Markdown features deliberately

Shared pages use GitHub-flavored Markdown. Material-only tabs and attributes belong only in site-specific pages supported by `mkdocs.yml`. Use native GitHub alerts; `pymdownx.quotes` renders them on the site:

- `NOTE`: context a reader must notice.
- `TIP`: a particularly useful shortcut.
- `IMPORTANT`: a requirement for success.
- `WARNING`: an immediate concern.
- `CAUTION`: a destructive or otherwise risky outcome.

Most pages need no more than one or two alerts. Keep routine commands outside them and avoid adjacent alerts. Put quoted prose directly after the marker; an opening list or fence needs one empty quoted line. Never hide prerequisites, risks, or primary steps in `<details>`. Footnotes are for tangential context. Diagrams need equivalent adjacent prose; informative images need meaningful alt text.

## Review the reader's route

1. Check commands, paths, defaults, supported versions, and backup boundaries against source and the supported release. Label unreleased behavior.
2. Start from the relevant entry page and follow a representative task without assuming undocumented knowledge. Check the expected result and recovery path.
3. Run `pre-commit run --all-files`, spelling checks using the repository vocabulary, `make docs`, and `git diff --check`.
4. Inspect changed GitHub and Material pages, links/anchors, images, alerts, tables, diagrams, and narrow-screen layouts.
5. Report actual checks, remaining usability assumptions, and removed/merged content. Automated checks do not prove reader usability or certified ISO conformity.

## Source guidance

- [GitHub Docs writing best practices](https://docs.github.com/en/contributing/writing-for-github-docs/best-practices-for-github-docs)
- [GitHub Docs style guide](https://docs.github.com/en/contributing/style-guide-and-content-model/style-guide)
- [GitHub Markdown syntax](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax)
- [ISO 24495-1:2023: Plain language principles and guidelines](https://www.iso.org/standard/78907.html)
