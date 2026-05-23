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
    | awk -F/ '{ 
        file=$NF
        path=$0
        print "<b>" file "</b>\t<span alpha=\"60%\">" path "</span>"
    }' \
    | rofi -dmenu -markup-rows -i \
        -theme ~/.config/rofi/file-search/file-search.rasi \
        -p "" \
    | sed -E 's/<[^>]+>//g' \
    | cut -f2-
)

[[ -z "$FILE" ]] && exit 0

xdg-open "$FILE" >/dev/null 2>&1 &
