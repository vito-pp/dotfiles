#!/usr/bin/env bash
# rofi-web-search: open a DuckDuckGo search in Firefox (focus existing window or open new)

QUERY=$(printf '' | rofi -dmenu -theme ~/.config/rofi/web-search/web-search.rasi -p "")

# Exit silently if the user cancelled or typed nothing
[[ -z "$QUERY" ]] && exit 0

URL="https://duckduckgo.com/?q=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote_plus(sys.argv[1]))" "$QUERY")"

# Check if Firefox is already running
if pgrep -x firefox > /dev/null; then
    # Focus the existing Firefox window via swaymsg, then open URL in a new tab
    swaymsg '[app_id="firefox"] focus' 2>/dev/null || true
    firefox --new-tab "$URL" &
else
    firefox "$URL" &
fi
