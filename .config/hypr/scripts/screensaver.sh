#!/bin/bash

# Function to check if screensaver is in focus
screensaver_in_focus() {
  if command -v jq >/dev/null 2>&1; then
    hyprctl activewindow -j | jq -e '.class == "org.uxna.screensaver"' >/dev/null 2>&1
  else
    hyprctl activewindow | grep -q "class: org.uxna.screensaver"
  fi
}

exit_screensaver() {
  pkill -x tte 2>/dev/null
  pkill -f org.uxna.screensaver 2>/dev/null
  exit 0
}

# Trap signals and window close to exit gracefully
trap exit_screensaver SIGINT SIGTERM SIGHUP SIGQUIT

# Hide cursor and set background to pure black for immersion
printf '\033]11;rgb:00/00/00\007'

# Wait a fraction of a second to ensure Hyprland has focused the new Kitty window
# before we start aggressively checking for focus loss
sleep 0.5

while true; do
  # Run the text effect in the background
  ~/.local/share/tte-venv/bin/tte -i ~/.config/hypr/screensaver.txt \
    --no-restore-cursor \
    --anchor-canvas c \
    --anchor-text c \
    --random-effect &
  
  TTE_PID=$!

  # Loop while our specific TTE instance is running
  while kill -0 $TTE_PID 2>/dev/null; do
    # Listen for any keypress (timeout 1s) OR if the window loses focus
    if read -n1 -t 1 || ! screensaver_in_focus; then
      exit_screensaver
    fi
  done
done
