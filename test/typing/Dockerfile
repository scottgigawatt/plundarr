#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# Dockerfile: Isolate strict Python tooling from the published Maraudarr image.
#

#
# Alpine 3.24 is the last release to support Python 3.11, which is the last release to support the legacy typing module.
#
ARG ALPINE_TAG=3.24@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6

#
# Stage 1 of 1: Provide the real runtime imports and the pinned development checker.
#
FROM alpine:${ALPINE_TAG}

#
# Install validation tools only in this disposable development image.
#
RUN apk add --no-cache python3 py3-pip nodejs npm && \
    python3 -m venv /opt/typecheck

#
# Resolve imports against the same hash-verified dependencies as production.
#
COPY requirements.txt /tmp/requirements.txt
RUN /opt/typecheck/bin/pip install --no-cache-dir --require-hashes -r /tmp/requirements.txt && \
    npm install --global pyright@1.1.414 && npm cache clean --force

#
# Prevent Python from writing .pyc files to disk, which is unnecessary in this disposable image
#
ENV PYTHONDONTWRITEBYTECODE=1

#
# Run the type checker with the same Python path as the production image.
#
ENTRYPOINT ["pyright", "--pythonpath", "/opt/typecheck/bin/python", "--warnings"]
