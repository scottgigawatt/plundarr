#!/bin/sh
#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# build.sh: Install Maraudarr and compile its ClusterFuzzLite targets.
#

set -eu

#
# Install only Maraudarr itself. Its interactive dependencies are unnecessary
# because the fuzz target imports the dependency-free text helper module.
#
python3 -m pip install --no-deps "${SRC}/plundarr/docker"

#
# Package the Atheris harness as the executable expected by ClusterFuzzLite.
# The builder image provides both Atheris and compile_python_fuzzer.
#
compile_python_fuzzer \
    "${SRC}/plundarr/docker/tests/fuzz/maraudarr_text_fuzzer.py"
