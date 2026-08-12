#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# Dockerfile: Build the published Maraudarr image used to generate Plundarr
#             Docker Compose stacks and their service configuration folders.
#

#
# Default Alpine, Docker CLI, and Compose image tags that build arguments can override.
#
ARG ALPINE_TAG=3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b
ARG DOCKER_CLI_TAG=29.7.2-cli-alpine3.24@sha256:000bb62ff495f986c9f5578eb67cc2cb98b91138eda81d7762d5371eb8a497fe
ARG DOCKER_COMPOSE_TAG=v5.4.0@sha256:b03e46987ca4ebb41ca31b765ad7ba957388003f1ef1255fd68333a7b838d632
ARG MARAUDARR_BIN_HOME=/maraudarr

#
# Source current, multi-architecture Docker and Compose binaries separately so
# their Go dependencies are not limited by Alpine's stable package versions.
#
FROM docker:${DOCKER_CLI_TAG} AS docker-cli
FROM docker/compose-bin:${DOCKER_COMPOSE_TAG} AS docker-compose

#
# Build the isolated Python environment separately so package-management tools
# and their transitive dependencies never enter the published runtime image.
#
FROM alpine:${ALPINE_TAG} AS build

ARG MARAUDARR_BIN_HOME

ENV PATH=${MARAUDARR_BIN_HOME}/venv/bin:${PATH}

RUN apk add --no-cache \
      py3-pip \
      python3 && \
    python3 -m venv "${MARAUDARR_BIN_HOME}/venv"

COPY requirements.txt /tmp/maraudarr/requirements.txt

RUN pip install \
      --disable-pip-version-check \
      --no-cache-dir \
      --require-hashes \
      --requirement /tmp/maraudarr/requirements.txt

COPY src /tmp/maraudarr/src

RUN site_packages="$(python3 -c 'import site; print(site.getsitepackages()[0])')" && \
    mkdir -p "${site_packages}/maraudarr" && \
    cp -a /tmp/maraudarr/src/maraudarr/. "${site_packages}/maraudarr/" && \
    printf '%s\n' \
      '#!/bin/sh' \
      'exec python3 -m maraudarr.cli "$@"' \
      > "${MARAUDARR_BIN_HOME}/venv/bin/maraudarr" && \
    chmod +x "${MARAUDARR_BIN_HOME}/venv/bin/maraudarr" && \
    pip uninstall --yes setuptools pip && \
    rm -rf /tmp/maraudarr

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
# Install only the Python runtime required by Maraudarr. Python package-
# management tools remain in the build stage.
#
RUN apk add --no-cache python3

#
# Copy the current Docker CLI and Compose plugin from their official images.
#
COPY --from=docker-cli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker-compose /docker-compose /usr/local/libexec/docker/cli-plugins/docker-compose

#
# Copy the installed application and exact, hash-verified dependencies from
# the disposable build stage.
#
COPY --from=build ${MARAUDARR_BIN_HOME}/venv ${MARAUDARR_BIN_HOME}/venv

#
# Copy Maraudarr source, service charts, config seeds, metadata, and license.
# The Docker build context is intentionally limited to this directory.
#
COPY LICENSE /LICENSE
COPY catalog ${MARAUDARR_BIN_HOME}/catalog
COPY config ${MARAUDARR_BIN_HOME}/config
COPY services ${MARAUDARR_BIN_HOME}/services
COPY templates ${MARAUDARR_BIN_HOME}/templates
COPY maraudarr-entrypoint.sh ${MARAUDARR_BIN_HOME}/maraudarr-entrypoint.sh

#
# Create the configurable unprivileged runtime account and secure the
# project-owned entrypoint.
#
RUN addgroup -S -g "${MARAUDARR_GID}" maraudarr && \
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
