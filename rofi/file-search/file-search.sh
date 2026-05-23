#!/usr/bin/env bash
# rofi-file-search

FILE=$(
    fd . "$HOME" \
        --type f \
        --exclude .git \
        --exclude .cache \
        --exclude node_modules \
        --exclude .local/share/Trash \
        --exclude .var \
        --exclude target \
        --exclude build \
    | awk -F/ '{ print $NF "\t" $0 }' \
    | rofi -dmenu -i -theme ~/.config/rofi/file-search/file-search.rasi -p "" \
    | cut -f2-
)

[[ -z "$FILE" ]] && exit 0

xdg-open "$FILE" >/dev/null 2>&1 &
