#!/usr/bin/env bash
# brightness.sh — scroll-wheel brightness control for waybar
DIRECTION="${1:-up}"
STEP=5

if [[ "$DIRECTION" == "up" ]]; then
    brightnessctl set +"${STEP}%"
else
    brightnessctl set "${STEP}%-"
fi
