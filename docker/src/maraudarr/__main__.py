#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# __main__.py: Run Maraudarr with python -m maraudarr.
#

"""Run Maraudarr as a Python module."""

from maraudarr.cli import main


if __name__ == "__main__":
    raise SystemExit(main())
