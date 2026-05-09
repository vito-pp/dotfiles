#!/usr/bin/env bash
# rofi-network: nmcli + rofi wifi menu
# Based on ericmurphyxyz/rofi-wifi-menu and firecat53/networkmanager-dmenu

THEME="$HOME/.config/rofi/nm-manager/network.rasi"

# ─── wifi toggle entry ───────────────────────────────────────────────────────

connected=$(nmcli -fields WIFI g)
if [[ "$connected" =~ "enabled" ]]; then
    toggle="󰖪      Disable Wi-Fi"
else
    toggle="󰖩      Enable Wi-Fi"
fi

# ─── build network list ──────────────────────────────────────────────────────

# List networks: signal icon + lock icon + SSID, mark active with ✓
# Sorted by signal descending, deduped
wifi_list=$(nmcli --fields "IN-USE,SIGNAL,SECURITY,SSID" device wifi list \
    | sed 1d \
    | sort -k2 -rn \
    | awk '
        {
            inuse = ($1 == "*") ? " ✓" : ""
            sig   = int($2)
            sec   = ($3 != "--") ? "   󰌾" : ""
            # Rebuild SSID from field 4 onward (handles spaces in names)
            ssid  = ""
            for (i=4; i<=NF; i++) ssid = ssid (i==4?"":OFS) $i

            if      (sig >= 80) icon = "󰤨    "
            else if (sig >= 60) icon = "󰤥    "
            else if (sig >= 40) icon = "󰤢    "
            else if (sig >= 20) icon = "󰤟    "
            else                icon = "󰤯    "

            printf "%s  %s%s%s\n", icon, ssid, sec, inuse
        }
    ' \
    | awk '!seen[$0]++')

# ─── rofi prompt ─────────────────────────────────────────────────────────────

chosen=$(echo -e "$toggle\n$wifi_list" \
    | rofi -dmenu -i -theme "$THEME" -p "" -selected-row 1)

[[ -z "$chosen" ]] && exit 0

# ─── handle toggle ───────────────────────────────────────────────────────────

if [[ "$chosen" == "󰖩  Enable Wi-Fi" ]]; then
    nmcli radio wifi on
    exit 0
fi

if [[ "$chosen" == "󰖪  Disable Wi-Fi" ]]; then
    nmcli radio wifi off
    exit 0
fi

# ─── extract bare SSID ───────────────────────────────────────────────────────

# Strip leading icon, lock icon, and active marker
ssid=$(echo "$chosen" \
    | sed 's/^[^ ]*  //' \
    | sed 's/ 󰌾//' \
    | sed 's/ ✓//' \
    | xargs)

[[ -z "$ssid" ]] && exit 0

# ─── connect ─────────────────────────────────────────────────────────────────

saved=$(nmcli -g NAME connection)

if echo "$saved" | grep -qxF "$ssid"; then
    # Saved profile — connect directly
    nmcli connection up id "$ssid"
else
    # New network — ask for password only if secured
    if [[ "$chosen" =~ "󰌾" ]]; then
        password=$(rofi -dmenu -theme "$THEME" -p "Password" -password)
        [[ -z "$password" ]] && exit 0
        nmcli device wifi connect "$ssid" password "$password"
    else
        nmcli device wifi connect "$ssid"
    fi
fi
