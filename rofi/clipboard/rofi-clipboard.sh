#!/usr/bin/env bash
# rofi-clipboard: browse and paste from clipboard history using cliphist

SELECTED=$(cliphist list | rofi -dmenu -display-columns 2 -theme ~/.config/rofi/clipboard/clipboard.rasi -p "")

# Exit silently if the user cancelled or selected nothing
[[ -z "$SELECTED" ]] && exit 0

# Decode the selected entry and copy it back to the clipboard
printf '%s' "$SELECTED" | cliphist decode | wl-copy
