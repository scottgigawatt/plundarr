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

from maraudarr.text import aligned_yaml_lines, extract_service


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

    #
    # Inline-comment alignment behavior.
    #
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
