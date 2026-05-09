#!/usr/bin/env bash

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/waybar-settings-menu"
mkdir -p "$STATE_DIR"

ROFI_THEME="${HOME}/.config/rofi/config.rasi"

get_idle_icon() {
    if pgrep -f "waybar.*idle_inhibitor" >/dev/null 2>&1; then
        printf ""
    else
        printf ""
    fi
}

get_power_icon() {
    profile="$(powerprofilesctl get 2>/dev/null)"
    case "$profile" in
        performance) printf "" ;;
        power-saver) printf "" ;;
        *) printf "" ;;
    esac
}

get_bt_icon() {
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        printf ""
    else
        printf "󰂲"
    fi
}

open_menu() {
    idle_icon="$(get_idle_icon)"
    power_icon="$(get_power_icon)"
    bt_icon="$(get_bt_icon)"
    net_icon=""

    printf "%s\n%s\n%s\n%s\n" \
        "$idle_icon" \
        "$power_icon" \
        "$net_icon" \
        "$bt_icon" | \
    rofi -dmenu \
        -theme "$ROFI_THEME" \
        -p "" \
        -mesg "" \
        -theme-str '
            listview {
                columns: 2;
                lines: 2;
                layout: vertical;
                fixed-height: true;
            }
            inputbar {
                children: [ entry ];
            }
            prompt {
                enabled: false;
            }
            entry {
                placeholder: "Settings";
            }
            element {
                orientation: vertical;
                padding: 18px;
            }
            element-text {
                horizontal-align: 0.5;
                vertical-align: 0.5;
                font: "Noto Sans Bold 24";
            }
        '
}

selection="$(open_menu)"

case "$selection" in
    ""|"")
        pkill -USR1 waybar
        ;;
    "")
        powerprofilesctl set power-saver
        ;;
    "")
        powerprofilesctl set performance
        ;;
    "")
        powerprofilesctl set balanced
        ;;
    "")
        nm-connection-editor >/dev/null 2>&1 &
        ;;
    ""|"󰂲")
        blueman-manager >/dev/null 2>&1 &
        ;;
esac
