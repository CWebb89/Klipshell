#!/bin/bash
# klipshell launcher — single instance (quickshell -n exits if already running).
# Usage: ./launch.sh   (or bind: hyprctl dispatch exec "$(pwd)/launch.sh")

REPO="$(cd "$(dirname "$0")" && pwd)"
exec quickshell -n -p "$REPO"