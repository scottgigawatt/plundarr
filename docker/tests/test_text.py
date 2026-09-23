#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_text.py: Test comment-preserving source extraction and alignment helpers.
#

"""Exercise raw source extraction and inline comment formatting."""

from __future__ import annotations

import unittest

from maraudarr.text import (
    align_env_comments,
    aligned_yaml_lines,
    extract_service,
    prune_unused_anchors,
)


class TextTests(unittest.TestCase):
    """Verify comment-preserving text operations."""

    #
    # Service-block extraction behavior.
    #
    def test_extract_service_keeps_intro_and_excludes_neighbor(self) -> None:
        """Extract one service with its comments but not its neighbor."""

        # Model adjacent service blocks so the boundary behavior is explicit.
        source = """services:
  #
  # First service
  #
  first:
    image: first:latest  # First image

  #
  # Second service
  #
  second:
    image: second:latest  # Second image
"""

        first = extract_service(source, "first")

        self.assertIn("# First service", first)
        self.assertIn("first:latest  # First image", first)
        self.assertNotIn("Second service", first)

    def test_anchor_pruning_keeps_transitive_dependencies_and_comments(self) -> None:
        """Keep indirect defaults while discarding unused chains and prose aliases."""

        # Model a selected anchor chain beside an unused chain that should disappear as a group.
        foundation = """# Base settings
x-base: &base
  restart: unless-stopped  # Preserve this comment

# Intermediate settings
x-middle: &middle
  <<: *base

# Selected settings
x-selected: &selected
  <<: *middle
  user: ${DEFAULT_PUID}

# Unused settings
x-unused: &unused
  <<: *orphan

# Unused dependency
x-orphan: &orphan
  restart: always

# Services heading
services:
"""

        # Aliases inside comments and quoted commands must not keep unused anchors alive.
        content = """  example:
    <<: *selected
    # labels: *unused
    command: "echo *orphan"
"""
        result = prune_unused_anchors(foundation, content)
        self.assertEqual(
            result,
            foundation[: foundation.index("# Unused settings")] + "# Services heading\nservices:\n",
        )

        # A second pass must be stable, and an anchor-free service needs no shared definitions.
        self.assertEqual(prune_unused_anchors(result, content), result)
        self.assertEqual(
            prune_unused_anchors(foundation, "  example:\n    image: example\n"),
            "# Services heading\nservices:\n",
        )

    #
    # Inline-comment alignment behavior.
    #
    def test_environment_comments_align_without_changing_values(self) -> None:
        """Align whole groups across uncommented values while keeping literal hashes."""

        # Quoted hashes belong to values; only the trailing comments may move.
        source = (
            'SHORT="value # literal"   # First comment\n'
            'NO_COMMENT="keep # this"\n'
            "LONGER_KEY='value # literal'  # Second comment\n"
            "\n# Separate group\n"
            "X=one      # Third comment\n"
            "YY=two  # Fourth comment\n"
        )
        expected = (
            'SHORT="value # literal"       # First comment\n'
            'NO_COMMENT="keep # this"\n'
            "LONGER_KEY='value # literal'  # Second comment\n"
            "\n# Separate group\n"
            "X=one   # Third comment\n"
            "YY=two  # Fourth comment\n"
        )
        self.assertEqual(align_env_comments(source), expected)
        self.assertEqual(align_env_comments(expected), expected)

        # An escaped quote must not make a literal hash look like the start of a comment.
        escaped = r'KEY="value \" # literal"  # Real comment' + "\n"
        self.assertEqual(align_env_comments(escaped), escaped)

    def test_grouped_comments_are_aligned(self) -> None:
        """Align grouped inline comments after differently sized values."""

        rendered = aligned_yaml_lines(
            [("ONE: 1", "First"), ("A_LONGER_NAME: 2", "Second")],
            indent=2,
        ).splitlines()

        self.assertEqual(rendered[0].index("#"), rendered[1].index("#"))
        self.assertIn("  #", rendered[0])


if __name__ == "__main__":
    unittest.main()
