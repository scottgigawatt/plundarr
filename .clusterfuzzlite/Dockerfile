#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# Dockerfile: Build Maraudarr's Python fuzz targets with ClusterFuzzLite.
#

#
# Stage 1 of 1: Build Maraudarr's Python fuzz targets with the official
# ClusterFuzzLite builder. The digest keeps the toolchain deterministic while
# Renovate tracks future updates.
#
FROM gcr.io/oss-fuzz-base/base-builder-python:v1@sha256:d74383a516f17ae3300aee7160277adf0702a22ca400d2dc54cd79f4b4c86b70

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
