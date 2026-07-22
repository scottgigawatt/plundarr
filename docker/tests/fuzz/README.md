<!--
  Copyright 2025-2026 Scott Gigawatt

  Licensed under the Apache License, Version 2.0.

  README.md: Explain Maraudarr's coverage-guided fuzzing harnesses.
  -->

# Maraudarr Fuzz Locker 🐒

These Atheris harnesses feed unexpected text into Maraudarr's parsers while
ClusterFuzzLite watches the paths exercised by each input. A reproducible crash
fails the pull-request check and preserves the offending input for inspection.

## Text Parser Harness

`maraudarr_text_fuzzer.py` exercises the comment-preserving helpers that split
Compose services, locate shared template sections, preserve environment groups,
and remove optional YAML fragments. Expected `TemplateError` exceptions are
treated as ordinary rejected input; every other exception remains a crash.

The harness deliberately imports only `maraudarr.text`. This keeps fuzz-only
dependencies out of the published Maraudarr image and makes each run fast enough
for pull-request validation.

## Build And Execution

ClusterFuzzLite reads `.clusterfuzzlite/` from the repository root, packages the
harness with Atheris, and fuzzes relevant pull requests for two minutes. The
workflow uses read-only permissions and immutable action and image references.
