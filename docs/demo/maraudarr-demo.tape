#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# maraudarr-demo.tape: This tape records Maraudarr generating and starting a
#                       complete Plundarr Docker Compose stack.
#
# The recording:
#   - Opens Maraudarr's interactive configurator through Make.
#   - Selects the Plundarr voyage with qBittorrent, Cleanuparr, and Jellyfin.
#   - Generates the complete Compose chart, environment, and configuration.
#   - Applies the credential-free runtime override outside the visible capture.
#   - Starts the selected Compose fleet and displays its container status.
#

#
# Write the generated animation to the README asset directory.
#
Output docs/assets/maraudarr-demo.gif

#
# Fail before recording when a required command is unavailable.
#
Require docker
Require make

#
# Configure terminal dimensions, playback, typing, colors, and cursor behavior.
#
Set Shell "zsh"
Set FontSize 16
Set Width 1200
Set Height 720
Set Padding 20
Set Framerate 12
Set PlaybackSpeed 1.4
Set LoopOffset 8%
Set TypingSpeed 35ms
Set Theme "TokyoNight"
Set CursorBlink false

#
# Enter the disposable checkout without exposing its temporary host path.
#
Hide
Type `cd "$PLUNDARR_DEMO_DIR"`
Enter
Type "clear"
Enter
Show

#
# Open Maraudarr's interactive stack configurator through Make.
#
Sleep 1s
Type "make configure"
Sleep 500ms
Enter
Sleep 3s

#
# Choose the default Plundarr voyage.
#
Enter
Sleep 2s

#
# Keep qBittorrent, skip extra automation services, and add Jellyfin.
#
Enter
Sleep 700ms
Enter
Sleep 700ms
Down
Space
Enter
Sleep 700ms

#
# Keep Cleanuparr and skip the optional notification service.
#
Enter
Sleep 700ms
Enter
Sleep 2s

#
# Confirm the resolved Plundarr service manifest and generate its files.
#
Enter
Sleep 5s

#
# Merge the credential-free runtime override outside the visible recording.
#
Hide
Type `docker compose --env-file .env -f docker-compose.yml -f docker-compose.demo.yml config > docker-compose.runtime.yml`
Enter
Sleep 2s
Type "mv docker-compose.runtime.yml docker-compose.yml"
Enter
Type "clear"
Enter
Sleep 500ms
Show

#
# Start the complete selected Compose fleet through Make.
#
Sleep 1s
Type "make up"
Sleep 500ms
Enter
Sleep 35s

#
# Display the final service and container status table.
#
Type "make ps"
Sleep 500ms
Enter
Sleep 6s
