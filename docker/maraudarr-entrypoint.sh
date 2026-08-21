#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# maraudarr-entrypoint.sh: Launch Maraudarr as PID 1 and forward every command
#                          argument supplied by Docker or Docker Compose.
#
# Usage: docker/maraudarr-entrypoint.sh [maraudarr arguments]
#

#
# Fail on errors and unset variables.
#
set -eu

#
# Open the interactive configurator when no explicit command was supplied.
#
if [ "$#" -eq 0 ]; then
    set -- configure
fi

#
# Replace this wrapper so Maraudarr receives terminal and stop signals directly.
#
exec maraudarr "$@"
