#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# maraudarr_text_fuzzer.py: Fuzz Maraudarr's comment-preserving text helpers.
#

"""Exercise Maraudarr's raw-text parsers with coverage-guided input."""

from __future__ import annotations

import sys
from collections.abc import Callable

import atheris


#
# Instrument project imports so Atheris can guide new inputs toward previously
# unexplored branches in Maraudarr rather than only observing the harness.
#
with atheris.instrument_imports():
    from maraudarr.text import (
        TemplateError,
        extract_env_preamble,
        extract_env_sections,
        extract_footer,
        extract_foundation,
        extract_service,
        remove_comment_group,
        strip_yaml_key,
    )


#
# Bound decoded strings so malformed inputs cannot turn one fuzzing iteration
# into an unhelpful memory-exhaustion test.
#
MAX_SOURCE_CHARACTERS = 65_536
MAX_NAME_CHARACTERS = 128


def _exercise_template_parser(
    parser: Callable[..., str],
    *arguments: str,
) -> None:
    """Accept documented template rejections and verify successful output."""

    try:
        rendered = parser(*arguments)
    except TemplateError:
        return

    # Every successful extraction normalizes its result to one trailing newline.
    if not rendered.endswith("\n"):
        raise AssertionError("A successful template extraction lost its newline.")


def fuzz_one_input(data: bytes) -> None:
    """Pass one coverage-guided byte sequence through every text boundary."""

    provider = atheris.FuzzedDataProvider(data)
    source = provider.ConsumeUnicodeNoSurrogates(MAX_SOURCE_CHARACTERS)
    name = provider.ConsumeUnicodeNoSurrogates(MAX_NAME_CHARACTERS)

    # These extractors intentionally reject sources missing their required
    # marker. Unexpected exception types remain visible to the fuzzing engine.
    _exercise_template_parser(extract_service, source, name)
    _exercise_template_parser(extract_foundation, source)
    _exercise_template_parser(extract_footer, source)
    _exercise_template_parser(extract_env_preamble, source)

    # These helpers accept arbitrary text and therefore must never need an
    # expected-exception allowlist.
    sections = extract_env_sections(source)
    strip_yaml_key(source, name)
    remove_comment_group(source, name)

    # Environment sections are normalized individually just like extractions.
    if any(not section.endswith("\n") for section in sections.values()):
        raise AssertionError("An environment section lost its trailing newline.")


def main() -> None:
    """Register the Maraudarr target and hand control to Atheris."""

    atheris.Setup(sys.argv, fuzz_one_input)
    atheris.Fuzz()


if __name__ == "__main__":
    main()
