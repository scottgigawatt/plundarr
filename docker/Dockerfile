#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# Dockerfile: Build the published Maraudarr image used to generate Plundarr
#             Docker Compose stacks and their service configuration folders.
#

#
# Default Alpine image tag that can be overridden using build arguments.
#
ARG ALPINE_TAG=3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

#
# Use the specified version of the Alpine image.
#
FROM alpine:${ALPINE_TAG}

#
# Re-declare the Alpine tag after FROM so labels can record the base image.
#
ARG ALPINE_TAG=3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

#
# Default install locations, runtime identity, and image metadata. Every value
# can be overridden by Docker Compose, Make, or the publication workflow.
#
ARG MARAUDARR_BIN_HOME=/maraudarr
ARG MARAUDARR_UID=1000
ARG MARAUDARR_GID=1000
ARG IMAGE_CREATED=unknown
ARG IMAGE_REVISION=unknown
ARG IMAGE_VERSION=latest

#
# Set application locations and predictable Python runtime behavior.
#
ENV MARAUDARR_BIN_HOME=${MARAUDARR_BIN_HOME} \
    MARAUDARR_CATALOG_ROOT=${MARAUDARR_BIN_HOME} \
    MARAUDARR_OUTPUT=/output \
    PATH=${MARAUDARR_BIN_HOME}/venv/bin:${PATH} \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

#
# Add Open Container Initiative image labels. Container registries use these
# values to link the image to its source, documentation, license, and release.
#
LABEL org.opencontainers.image.title="Maraudarr" \
      org.opencontainers.image.description="Maraudarr generates polished, reusable Plundarr Docker Compose stacks from presets and selectable services." \
      org.opencontainers.image.url="https://github.com/scottgigawatt/plundarr" \
      org.opencontainers.image.documentation="https://github.com/scottgigawatt/plundarr/tree/main/docker#readme" \
      org.opencontainers.image.source="https://github.com/scottgigawatt/plundarr" \
      org.opencontainers.image.vendor="Scott Gigawatt" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.base.name="docker.io/library/alpine:${ALPINE_TAG}"

#
# Install only the Python runtime and Docker Compose parser required by
# Maraudarr, then create an isolated virtual environment for pinned packages.
#
RUN apk add --no-cache \
      docker-cli-compose \
      py3-pip \
      python3 && \
    python3 -m venv "${MARAUDARR_BIN_HOME}/venv"

#
# Copy dependency metadata first so dependency installation remains cacheable.
#
COPY requirements.txt /tmp/maraudarr/requirements.txt

#
# Install exact, hash-verified Python dependency versions.
#
RUN pip install \
      --disable-pip-version-check \
      --no-cache-dir \
      --require-hashes \
      --requirement /tmp/maraudarr/requirements.txt

#
# Copy Maraudarr source, service charts, config seeds, metadata, and license.
# The Docker build context is intentionally limited to this directory.
#
COPY LICENSE /LICENSE
COPY README.md pyproject.toml /tmp/maraudarr/
COPY src /tmp/maraudarr/src
COPY catalog ${MARAUDARR_BIN_HOME}/catalog
COPY config ${MARAUDARR_BIN_HOME}/config
COPY services ${MARAUDARR_BIN_HOME}/services
COPY templates ${MARAUDARR_BIN_HOME}/templates
COPY maraudarr-entrypoint.sh ${MARAUDARR_BIN_HOME}/maraudarr-entrypoint.sh

#
# Install Maraudarr without resolving dependencies a second time, then create
# the configurable unprivileged runtime account and secure the entrypoint.
#
RUN pip install \
      --disable-pip-version-check \
      --no-build-isolation \
      --no-deps \
      /tmp/maraudarr && \
    rm -rf /tmp/maraudarr && \
    addgroup -S -g "${MARAUDARR_GID}" maraudarr && \
    adduser -S -D -H -u "${MARAUDARR_UID}" -G maraudarr maraudarr && \
    chmod +x "${MARAUDARR_BIN_HOME}/maraudarr-entrypoint.sh"

#
# Write generated files only to the mounted repository directory.
#
WORKDIR /output
USER ${MARAUDARR_UID}:${MARAUDARR_GID}

#
# Run Maraudarr through the project-owned signal-safe entrypoint.
#
ENTRYPOINT ["/maraudarr/maraudarr-entrypoint.sh"]
CMD ["configure"]
