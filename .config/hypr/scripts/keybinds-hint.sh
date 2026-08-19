#!/bin/bash
# ─────────────────────────────────────────────────────────
#  ✦  keybinds-hint.sh
#  ✦  Utility Script
# ─────────────────────────────────────────────────────────

README_PATH="$HOME/Projects/UXNA-Hyprland/README.md"

# 1. Find the Keybinds section
# 2. Grab only table rows (starting with |)
# 3. Skip the first 2 header rows
# 4. Remove leading/trailing pipes and backticks
# 5. Format into clean columns
# 6. Pipe into Rofi
awk '/## Keybindings/{flag=1; next} /^## /{if(flag) exit} flag' "$README_PATH" | \
  grep '^|' | \
  tail -n +3 | \
  sed 's/^|//; s/|$//' | \
  sed 's/`//g' | \
  awk -F'|' '{
    # Trim leading/trailing whitespace
    gsub(/^[ \t]+|[ \t]+$/, "", $1);
    gsub(/^[ \t]+|[ \t]+$/, "", $2);
    # Remove markdown bold formatting if any
    gsub(/\*\*/, "", $2);
    printf "%-35s ➜  %s\n", $1, $2
  }' | \
  rofi -dmenu -i -p "Shortcuts" -theme ~/.config/hypr/themes/current/rofi/launcher.rasi -theme-str 'window { width: 750px; } listview { lines: 10; }'
