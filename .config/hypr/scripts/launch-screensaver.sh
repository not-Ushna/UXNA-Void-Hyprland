#!/bin/bash

# Prevent multiple instances
pgrep -f org.uxna.screensaver && exit 0

# Launch Kitty with the screensaver class and script
kitty --class=org.uxna.screensaver --override font_size=16 --override window_padding_width=0 -e ~/.config/hypr/scripts/screensaver.sh
