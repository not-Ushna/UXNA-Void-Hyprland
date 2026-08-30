#!/usr/bin/env bash

# Kill any existing notification daemons
pkill -x dunst
pkill -x swaync

# Wait for them to terminate
while pgrep -x dunst >/dev/null; do sleep 0.1; done
while pgrep -x swaync >/dev/null; do sleep 0.1; done

# Launch the appropriate daemon for the current theme
if [ -d "$HOME/.config/hypr/themes/current/swaync" ]; then
    swaync -c "$HOME/.config/hypr/themes/current/swaync/config.json" -s "$HOME/.config/hypr/themes/current/swaync/style.css" &
elif [ -d "$HOME/.config/hypr/themes/current/dunst" ]; then
    dunst -conf "$HOME/.config/hypr/themes/current/dunst/dunstrc" &
fi
