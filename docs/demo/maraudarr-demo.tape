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
Set PlaybackSpeed 1
Set TypingSpeed 35ms
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
Type `docker run --rm -it \`
Enter
Type `  --user "$(id -u):$(id -g)" \`
Enter
Type `  --read-only --network none \`
Enter
Type `  --cap-drop ALL --security-opt no-new-privileges:true \`
Enter
Type `  --tmpfs /tmp:rw,noexec,nosuid,size=64m \`
Enter
Type `  --volume "$PWD:/output:rw" \`
Enter
Type `  ghcr.io/scottgigawatt/maraudarr:latest configure`

# Hold the complete command for one minute before opening the configurator.
Sleep 60s
Enter
Sleep 6s

# Select Plundarr and retain defaults in all eight optional service categories.
Enter
Sleep 4s
Enter
Sleep 4s
Enter
Sleep 4s
Enter
Sleep 4s
Enter
Sleep 4s
Enter
Sleep 4s
Enter
Sleep 4s
Enter
Sleep 4s
Enter
Sleep 4s

# Confirm generation; then inspect filenames without printing .env values.
Enter
Sleep 8s
Type "clear"
Enter
Type "cd dist/plundarr"
Enter
Type "ls -a"
Enter
Sleep 5s
Type "docker compose config --quiet"
Enter
Sleep 5s
