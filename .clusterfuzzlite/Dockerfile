#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# Dockerfile: Build Maraudarr's Python fuzz targets with ClusterFuzzLite.
#

#
# Use the official Python builder expected by ClusterFuzzLite. The digest keeps
# the fuzzing toolchain deterministic while Renovate tracks future updates.
#
FROM gcr.io/oss-fuzz-base/base-builder-python:v1@sha256:6b2b3a7e4a2da50de47f94925cffbe34747e1aae4f33d7f07ba6c681dd648b23

#
# Keep the complete checkout together so Maraudarr's self-contained Docker
# build context and its test harnesses retain their normal repository paths.
#
COPY . ${SRC}/plundarr
WORKDIR ${SRC}/plundarr

#
# ClusterFuzzLite invokes this script from the conventional OSS-Fuzz source
# root, independently of the project working directory above.
#
COPY .clusterfuzzlite/build.sh ${SRC}/build.sh
