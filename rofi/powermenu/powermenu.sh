#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Adapted for Sway

# Current Theme
dir="$HOME/.config/rofi/powermenu/"
theme='style-1'

# CMDs
uptime="$(uptime -p | sed -e 's/up //g')"
host="$(hostname)"

# Options
shutdown='󰐥'
reboot='󰑐'
lock=''
suspend='󰽥'
logout='󰍃'

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "Uptime: $uptime" \
		-mesg "Uptime: $uptime" \
		-theme "${dir}/${theme}.rasi"
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Actions
chosen="$(run_rofi)"
case "$chosen" in
    "$lock")
        swaylock -f
        ;;
    "$logout")
        swaymsg exit
        ;;
    "$suspend")
        systemctl suspend
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$shutdown")
        systemctl poweroff
        ;;
esac
