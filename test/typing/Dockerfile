#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# Dockerfile: Isolate strict Python tooling from the published Maraudarr image.
#

#
# Use the same Alpine release as Maraudarr so strict checks see its Python runtime.
#
ARG ALPINE_TAG=3.24@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a

#
# Stage 1 of 1: Provide the real runtime imports and the pinned development checker.
#
FROM alpine:${ALPINE_TAG}

#
# Refresh stable libraries and install the same patched interpreter as production.
#
RUN apk upgrade --no-cache && \
    apk add --no-cache python3 py3-pip nodejs npm && \
    python3 -m venv /opt/typecheck

#
# Resolve imports against the same hash-verified dependencies as production.
#
COPY requirements.txt /tmp/requirements.txt
RUN /opt/typecheck/bin/pip install --no-cache-dir --require-hashes -r /tmp/requirements.txt && \
    /opt/typecheck/bin/pip uninstall --yes pip

#
# Install the locked checker, then remove package managers and their unused bundled libraries.
#
COPY package.json package-lock.json /opt/tools/
RUN npm ci --prefix /opt/tools --omit=dev --ignore-scripts && \
    apk del npm py3-pip && \
    rm -rf /root/.npm

#
# Use the locked checker without adding Node tools to Maraudarr's runtime image.
#
ENV PATH="/opt/tools/node_modules/.bin:${PATH}"

#
# Prevent Python from writing .pyc files to disk, which is unnecessary in this disposable image
#
ENV PYTHONDONTWRITEBYTECODE=1

#
# Run the type checker with the same Python path as the production image.
#
ENTRYPOINT ["pyright", "--pythonpath", "/opt/typecheck/bin/python", "--warnings"]
