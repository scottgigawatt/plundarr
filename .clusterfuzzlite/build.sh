#!/bin/sh
#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# build.sh: Expose Maraudarr source and compile its ClusterFuzzLite targets.
#

set -eu

#
# Import Maraudarr directly from its checked-in source tree. Avoiding a local
# pip install keeps the fuzz build dependency-free and prevents Scorecard from
# treating the project itself as an unhashed package dependency.
#
export PYTHONPATH="${SRC}/plundarr/docker/src${PYTHONPATH:+:${PYTHONPATH}}"

#
# Package the Atheris harness as the executable expected by ClusterFuzzLite.
# The builder image provides both Atheris and compile_python_fuzzer.
#
compile_python_fuzzer \
    "${SRC}/plundarr/docker/tests/fuzz/maraudarr_text_fuzzer.py"
