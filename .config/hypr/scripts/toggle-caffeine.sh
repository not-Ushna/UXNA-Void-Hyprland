#!/usr/bin/env bash
# toggle-caffeine.sh — Toggle swayidle on/off (caffeine mode)
# Used by Waybar custom/caffeine module

STATE_FILE="/tmp/caffeine-state"
SWAYIDLE_CMD="swayidle -w \
    timeout 240 '~/.config/hypr/scripts/launch-screensaver.sh' \
    timeout 300 '~/.config/hypr/scripts/lock.sh' \
    timeout 600 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on'"

if pgrep -x swayidle > /dev/null; then
    # Caffeine ON: kill swayidle so screen never sleeps/locks
    pkill -x swayidle
    echo "on" > "$STATE_FILE"
    notify-send "☕ Caffeine ON" "Screen will stay awake" \
        --icon=dialog-information --urgency=low -t 2000
else
    # Caffeine OFF: restart swayidle
    eval "$SWAYIDLE_CMD" &
    disown
    echo "off" > "$STATE_FILE"
    notify-send "💤 Caffeine OFF" "Screen will sleep normally" \
        --icon=dialog-information --urgency=low -t 2000
fi
