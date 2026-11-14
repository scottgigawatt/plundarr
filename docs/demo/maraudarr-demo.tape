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
Set Width 2400
Set Height 1800
Set Padding 20
Set Framerate 8
Set PlaybackSpeed 1
Set TypingSpeed 35ms
Set Theme {"name": "Maraudarr", "background": "#0b0f14", "foreground": "#e6edf3", "cursor": "#e6edf3", "black": "#0b0f14", "red": "#ff7b72", "green": "#00cc66", "yellow": "#f2c14e", "blue": "#79c0ff", "magenta": "#d2a8ff", "cyan": "#56d4dd", "white": "#e6edf3", "brightBlack": "#8b949e", "brightRed": "#ffa198", "brightGreen": "#56d364", "brightYellow": "#e3b341", "brightBlue": "#a5d6ff", "brightMagenta": "#d2a8ff", "brightCyan": "#a5d6ff", "brightWhite": "#ffffff"}
Set CursorBlink false

# Use a disposable working directory without showing a temporary host path.
Hide
Type `cd "$PLUNDARR_DEMO_DIR"`
Enter
Type `export PS1='%F{#00ff00}$%f '`
Enter
Type `export PS2='%F{#00ff00}>%f '`
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
Type `  ghcr.io/scottgigawatt/maraudarr:3.2.0 configure`

# Hold the complete command for five seconds before opening the configurator.
Sleep 5s
Enter
Sleep 3s

# Select Plundarr and retain defaults in all eight optional service categories.
Enter
Sleep 3s
Enter
Sleep 3s
Enter
Sleep 3s
Enter
Sleep 3s
Enter
Sleep 3s
Enter
Sleep 3s
Enter
Sleep 3s
Enter
Sleep 3s
Enter
Sleep 3s

# Confirm generation; then inspect filenames without printing .env values.
Enter
Sleep 3s
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
