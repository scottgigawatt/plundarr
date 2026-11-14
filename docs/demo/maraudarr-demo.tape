#
# Copyright 2025-2026 Scott Gigawatt
#
# SPDX-License-Identifier: Apache-2.0
#
# maraudarr-demo.tape: Record interactive default-preset generation using the
#                       published image, followed by quiet Compose validation.
#

Output docs/assets/maraudarr-demo.gif
Require docker
Set Shell "zsh"
Set FontSize 20
Set Width 1200
Set Height 780
Set Padding 20
Set Framerate 8
Set PlaybackSpeed 1.3
Set TypingSpeed 10ms
Set Theme "TokyoNight"
Set CursorBlink false

# Use a disposable working directory without showing a temporary host path.
Hide
Type `cd "$PLUNDARR_DEMO_DIR"`
Enter
Type "clear"
Enter
Show

Sleep 1s
Type `docker run --rm -it --user "$(id -u):$(id -g)" --read-only --network none --cap-drop ALL --security-opt no-new-privileges:true --tmpfs /tmp:rw,noexec,nosuid,size=64m --volume "$PWD:/output:rw" ghcr.io/scottgigawatt/maraudarr:latest configure`
Enter
Sleep 4s

# Select Plundarr and retain defaults in all eight optional service categories.
Enter
Sleep 2s
Enter
Sleep 1200ms
Enter
Sleep 1200ms
Enter
Sleep 1200ms
Enter
Sleep 1200ms
Enter
Sleep 1200ms
Enter
Sleep 1200ms
Enter
Sleep 1200ms
Enter
Sleep 2s

# Confirm generation; then inspect filenames without printing .env values.
Enter
Sleep 5s
Type "clear"
Enter
Type "cd dist/plundarr"
Enter
Type "ls -a"
Enter
Sleep 3s
Type "docker compose config --quiet"
Enter
Sleep 3s
