#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# Dockerfile: Build the published Maraudarr image used to generate Plundarr
#             Docker Compose stacks and their service configuration folders.
#

#
# Default build images, Compose source, and the Maraudarr installation root.
# Build arguments can override each value.
#
ARG ALPINE_TAG=3.24@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6
ARG GO_TAG=1.26.9-alpine3.24@sha256:cdfd4fe2da6b225d8b40c6b7a105736e548e83ff56d5d8f9394446eeb5eb84e0
ARG DOCKER_COMPOSE_VERSION=v5.6.0
ARG GO_X_NET_VERSION=v0.60.0
ARG MARAUDARR_BIN_HOME=/maraudarr

#
# Require patched compression and XML libraries; keep Expat's edge exception scoped.
#
ARG ZLIB_APK_MIN_VERSION=1.3.2-r1
ARG LIBEXPAT_APK_MIN_VERSION=2.9.0-r0
ARG EDGE_APK_REPOSITORY=https://dl-cdn.alpinelinux.org/alpine/edge/main

#
# Stage 1 of 3: Compile verified upstream Compose source with patched Go libraries.
# Keep the compiler and downloaded source out of the published runtime.
#
FROM --platform=$BUILDPLATFORM golang:${GO_TAG} AS docker-compose

# Pin the upstream release and security update while disabling toolchain downloads.
ARG DOCKER_COMPOSE_VERSION
ARG GO_X_NET_VERSION
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ENV CGO_ENABLED=0 \
    GOTOOLCHAIN=local \
    GOPROXY=https://proxy.golang.org \
    GOSUMDB=sum.golang.org
WORKDIR /src

# Authenticate source and dependencies, raising the network library only below its fixed minimum.
RUN go mod download "github.com/docker/compose/v5@${DOCKER_COMPOSE_VERSION}" && \
    cp -a "$(go env GOMODCACHE)/github.com/docker/compose/v5@${DOCKER_COMPOSE_VERSION}/." /src/ && \
    chmod -R u+w /src && \
    current_net_version="$(go list -m -f '{{.Version}}' golang.org/x/net)" && \
    newest_net_version="$(printf '%s\n' "${current_net_version}" "${GO_X_NET_VERSION}" | sort -V | tail -n 1)" && \
    if [ "${current_net_version}" != "${newest_net_version}" ]; then \
        go get "golang.org/x/net@${GO_X_NET_VERSION}"; \
    fi && \
    go mod verify

# Match upstream build flags and cross-compile a static binary for each target platform.
RUN if [ "${TARGETARCH}" = arm ]; then export GOARM="${TARGETVARIANT#v}"; fi && \
    GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
    go build -mod=readonly -trimpath -tags=e2e \
        -ldflags "-w -X github.com/docker/compose/v5/internal.Version=${DOCKER_COMPOSE_VERSION}" \
        -o /docker-compose ./cmd

#
# Stage 2 of 3: Build the isolated Python environment separately so package-
# management tools and their transitive dependencies never enter the published
# runtime image.
#
FROM alpine:${ALPINE_TAG} AS build

#
# Re-declare the Maraudarr installation root inside the build stage.
#
ARG MARAUDARR_BIN_HOME
ARG ZLIB_APK_MIN_VERSION
ARG LIBEXPAT_APK_MIN_VERSION
ARG EDGE_APK_REPOSITORY

#
# Put the isolated environment first so every Python command uses it.
#
ENV PATH=${MARAUDARR_BIN_HOME}/venv/bin:${PATH}

#
# Install Python with patched compression and XML libraries before creating the environment.
# Keep the tagged repository available for later APK operations.
#
RUN apk add --no-cache \
        py3-pip \
        python3 \
        "zlib>=${ZLIB_APK_MIN_VERSION}" && \
    printf '%s\n' "@edge ${EDGE_APK_REPOSITORY}" >> /etc/apk/repositories && \
    apk add --no-cache "libexpat@edge>=${LIBEXPAT_APK_MIN_VERSION}" && \
    python3 -m venv "${MARAUDARR_BIN_HOME}/venv"

#
# Copy the exact, hash-verified runtime dependencies into the build stage.
#
COPY requirements.txt /tmp/maraudarr/requirements.txt

#
# Install only exact, hash-verified runtime dependencies.
#
RUN pip install \
        --disable-pip-version-check \
        --no-cache-dir \
        --require-hashes \
        --requirement /tmp/maraudarr/requirements.txt

#
# Copy the Maraudarr source package into the build stage.
#
COPY src /tmp/maraudarr/src

#
# Install the source package, create its command shim, and remove build tools.
#
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
# Stage 3 of 3: Assemble the minimal unprivileged runtime image from the
# specified Alpine release.
#
FROM alpine:${ALPINE_TAG}

#
# Re-declare the Alpine tag after FROM so labels can record the base image.
#
ARG ALPINE_TAG=3.24@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6

#
# Default install locations, runtime identity, and image metadata. Every value
# can be overridden by Docker Compose, Make, or the publication workflow.
#
ARG MARAUDARR_BIN_HOME=/maraudarr
ARG MARAUDARR_UID=1000
ARG MARAUDARR_GID=1000
ARG MARAUDARR_GROUP=maraudarr
ARG IMAGE_CREATED=unknown
ARG IMAGE_REVISION=unknown
ARG IMAGE_VERSION=latest
ARG ZLIB_APK_MIN_VERSION
ARG LIBEXPAT_APK_MIN_VERSION
ARG EDGE_APK_REPOSITORY

#
# Set application locations and predictable Python runtime behavior.
#
ENV MARAUDARR_BIN_HOME=${MARAUDARR_BIN_HOME} \
    MARAUDARR_CATALOG_ROOT=${MARAUDARR_BIN_HOME} \
    MARAUDARR_OUTPUT_ROOT=/output/dist \
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
# Upgrade OpenSSL and install the fixed Python compression and XML runtime libraries.
# Keep the Expat edge exception scoped until Alpine stable carries version 2.9.0.
# Retain its package tag so APK can resolve the installed world during maintenance.
# Python package-management tools remain in the build stage.
#
RUN apk upgrade --no-cache libcrypto3 libssl3 && \
    apk add --no-cache \
        python3 \
        "zlib>=${ZLIB_APK_MIN_VERSION}" && \
    printf '%s\n' "@edge ${EDGE_APK_REPOSITORY}" >> /etc/apk/repositories && \
    apk add --no-cache "libexpat@edge>=${LIBEXPAT_APK_MIN_VERSION}"

#
# Copy the patched standalone Compose binary and upstream license.
#
COPY --from=docker-compose /docker-compose /usr/local/bin/docker-compose
COPY --from=docker-compose /src/LICENSE /usr/share/licenses/docker-compose/LICENSE
COPY --from=docker-compose /src/NOTICE /usr/share/licenses/docker-compose/NOTICE

#
# Copy the installed application and exact, hash-verified dependencies from
# the disposable build stage.
#
COPY --from=build ${MARAUDARR_BIN_HOME}/venv ${MARAUDARR_BIN_HOME}/venv

#
# Copy the Maraudarr source package and its configuration templates into the
# runtime image so the entrypoint can generate a Plundarr stack and its service
# configuration folder.
#
COPY LICENSE                 /LICENSE
COPY catalog                 ${MARAUDARR_BIN_HOME}/catalog
COPY config                  ${MARAUDARR_BIN_HOME}/config
COPY services                ${MARAUDARR_BIN_HOME}/services
COPY templates               ${MARAUDARR_BIN_HOME}/templates
COPY maraudarr-entrypoint.sh ${MARAUDARR_BIN_HOME}/maraudarr-entrypoint.sh

#
# Create the configurable unprivileged runtime account and secure the
# project-owned entrypoint.
#
RUN addgroup -S -g "${MARAUDARR_GID}" "${MARAUDARR_GROUP}" && \
    adduser -S -D -H -u "${MARAUDARR_UID}" -G "${MARAUDARR_GROUP}" maraudarr && \
    chmod +x "${MARAUDARR_BIN_HOME}/maraudarr-entrypoint.sh"

#
# Write generated files only to the mounted repository directory.
#
WORKDIR /output

#
# Use the unprivileged runtime account to generate Plundarr stacks.
#
USER ${MARAUDARR_UID}:${MARAUDARR_GID}

#
# Run Maraudarr through the project-owned signal-safe entrypoint.
#
ENTRYPOINT ["/maraudarr/maraudarr-entrypoint.sh"]

#
# Open Maraudarr's configurator when no command is supplied.
#
CMD ["configure"]
