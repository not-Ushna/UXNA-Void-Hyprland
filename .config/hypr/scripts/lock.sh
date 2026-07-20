#!/bin/bash

# Pause all media players
playerctl pause -a 2>/dev/null

# Mute default microphone
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1 2>/dev/null

# Launch lock screen with theme config
hyprlock -c ~/.config/hypr/themes/current/hyprlock/hyprlock.conf
