#!/usr/bin/env bash
# caffeine-status.sh — Output current caffeine state for Waybar
# Outputs JSON: {"text": "icon", "class": "on/off", "tooltip": "..."}

if pgrep -x swayidle > /dev/null; then
    # swayidle running = caffeine OFF (normal sleep mode)
    echo '{"text":"󱠒","class":"off","tooltip":"Caffeine OFF — Click to keep awake"}'
else
    # swayidle not running = caffeine ON (screen staying awake)
    echo '{"text":"󰛊","class":"on","tooltip":"Caffeine ON — Click to allow sleep"}'
fi
