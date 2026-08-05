#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# maraudarr-demo.tape: Record Maraudarr generating and starting Plundarr.
#

Output docs/assets/maraudarr-demo.gif

Require docker
Require make

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

Hide
Type `cd "$PLUNDARR_DEMO_DIR"`
Enter
Type "clear"
Enter
Show

Sleep 1s
Type "make configure"
Sleep 500ms
Enter
Sleep 3s

# Choose the Plundarr preset.
Enter
Sleep 2s

# Keep qBittorrent, skip the extra automation services, and add Jellyfin.
Enter
Sleep 700ms
Enter
Sleep 700ms
Down
Space
Enter
Sleep 700ms

# Keep Cleanuparr and skip the optional notification service.
Enter
Sleep 700ms
Enter
Sleep 2s

# Confirm the generated manifest.
Enter
Sleep 5s

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

Sleep 1s
Type "make up"
Sleep 500ms
Enter
Sleep 35s

Type "make ps"
Sleep 500ms
Enter
Sleep 6s
