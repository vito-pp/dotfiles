#!/usr/bin/env python3
"""Single PipeWire privacy class -> one Waybar text label.

Usage: privacy-text.py [share|mic|audio]
Requires `pw-dump`. Without an argument, emits the combined legacy label.
"""
import json
import subprocess
import sys

CLASSES = {
    "share": "Stream/Input/Video",
    "mic": "Stream/Input/Audio",
    "audio": "Stream/Output/Audio",
}

kind = sys.argv[1].lower() if len(sys.argv) > 1 else "all"
if kind not in (*CLASSES, "all"):
    raise SystemExit("Use share, mic, audio, or all")

try:
    result = subprocess.run(
        ["pw-dump"], capture_output=True, check=True, text=True, timeout=3
    )
    nodes = json.loads(result.stdout)
except (OSError, subprocess.SubprocessError, ValueError):
    # Show only one short warning rather than three repeated warnings.
    text = "priv ?" if kind in ("share", "all") else ""
    print(json.dumps({
        "text": text, "tooltip": "PipeWire privacy check unavailable",
        "class": "error"
    }))
    raise SystemExit(0)

active = {name: [] for name in CLASSES}
for node in nodes:
    if node.get("type") != "PipeWire:Interface:Node":
        continue
    info = node.get("info") or {}
    if str(info.get("state", "")).lower() != "running":
        continue
    props = info.get("props") or {}
    if str(props.get("stream.monitor", "false")).lower() == "true":
        continue
    matched = next((name for name, media in CLASSES.items()
                    if props.get("media.class") == media), None)
    if not matched:
        continue
    app = props.get("application.name") or props.get("node.name") or "Unknown application"
    active[matched].append(str(app))

selected = [name for name in CLASSES if active[name]] if kind == "all" else ([kind] if active[kind] else [])
print(json.dumps({
    "text": " ".join(selected),
    "tooltip": "\n".join(f"{name}: {', '.join(active[name])}" for name in selected),
    "class": "active" if selected else "idle"
}))
