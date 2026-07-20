#!/bin/bash

# Check if a scratchpad terminal is already running
if ! hyprctl clients | grep -q "class: scratchpad"; then
    # Start kitty with the scratchpad class
    kitty --class scratchpad &
    
    # Give it a tiny moment to spawn before toggling
    sleep 0.2
fi

# Toggle the scratchpad special workspace
hyprctl dispatch togglespecialworkspace scratchpad
