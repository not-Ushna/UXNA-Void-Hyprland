#!/bin/bash

state_file="/tmp/focus_mode_state"

if [[ -f "$state_file" ]]; then
    # Toggle OFF
    rm -f "$state_file"
    dunstctl set-paused false
    hyprctl keyword decoration:dim_inactive false
    notify-send "Focus Mode: OFF" "Notifications and window brightness restored."
else
    # Toggle ON
    touch "$state_file"
    notify-send -t 2500 "Focus Mode: ON" "Notifications paused. Inactive windows dimmed."
    sleep 2.5 # Wait for the notification to disappear before pausing Dunst
    dunstctl set-paused true
    hyprctl keyword decoration:dim_inactive true
    hyprctl keyword decoration:dim_strength 0.65
fi
