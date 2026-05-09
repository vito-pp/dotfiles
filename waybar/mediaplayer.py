#!/usr/bin/env python3
import json
import subprocess


def run(cmd):
    try:
        return subprocess.check_output(cmd, text=True).strip()
    except Exception:
        return ""


def main():
    players = run(["playerctl", "-l"]).splitlines()
    players = [p for p in players if p.strip()]

    if not players:
        print(json.dumps({"text": ""}))
        return

    player = players[0]

    status = run(["playerctl", "-p", player, "status"])
    if status not in ("Playing", "Paused"):
        print(json.dumps({"text": ""}))
        return

    artist = run(["playerctl", "-p", player, "metadata", "artist"])
    title = run(["playerctl", "-p", player, "metadata", "title"])

    if not title:
        print(json.dumps({"text": ""}))
        return

    icon = "" if "spotify" in player.lower() else ""
    state = "" if status == "Playing" else ""

    if artist:
        text = f"{state} {icon} {artist} - {title}"
    else:
        text = f"{state} {icon} {title}"

    print(json.dumps({"text": text, "class": player.lower()}))


if __name__ == "__main__":
    main()
