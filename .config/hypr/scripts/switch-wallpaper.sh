#!/bin/bash
# ============================================================
# switch-wallpaper.sh — Wallpaper Switcher
# Cycles through available wallpapers for the current theme,
# or allows selecting one via Rofi.
#
# Usage:
#   switch-wallpaper.sh         # Interactive Rofi menu
#   switch-wallpaper.sh next    # Cycle to next wallpaper
#   switch-wallpaper.sh prev    # Cycle to previous wallpaper
# ============================================================

set -euo pipefail

CURRENT_LINK="$HOME/.config/hypr/themes/current"
WALLPAPERS_DIR="$CURRENT_LINK/wallpapers"
STATE_FILE="/tmp/hypr_current_wallpaper"

# Ensure wallpapers directory exists
if [[ ! -d "$WALLPAPERS_DIR" ]]; then
    notify-send "Wallpaper" "No wallpapers directory found for current theme."
    exit 1
fi

# Get sorted list of image files
mapfile -t wallpapers < <(
    find "$WALLPAPERS_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) \
        -printf "%f\n" | sort
)

if [[ ${#wallpapers[@]} -eq 0 ]]; then
    notify-send "Wallpaper" "No wallpapers found in $WALLPAPERS_DIR"
    exit 1
fi

# Determine current wallpaper
current=""
# 1. Try to read from state file
if [[ -f "$STATE_FILE" ]]; then
    current=$(cat "$STATE_FILE")
    # Verify it still exists in the current theme
    if [[ ! -f "$WALLPAPERS_DIR/$current" ]]; then
        current=""
    fi
fi

# 2. If no state file, query swww
if [[ -z "$current" ]] && command -v swww >/dev/null 2>&1; then
    # Extract the filename from the swww query output
    active_path=$(swww query | grep -oP 'image: \K.*' | head -1 || true)
    if [[ -n "$active_path" ]]; then
        current=$(basename "$active_path")
    fi
fi

# Find current index
idx=0
for i in "${!wallpapers[@]}"; do
    if [[ "${wallpapers[$i]}" == "$current" ]]; then
        idx=$i
        break
    fi
done

chosen=""
ACTION=${1:-""}

if [[ "$ACTION" == "next" ]]; then
    next_idx=$(( (idx + 1) % ${#wallpapers[@]} ))
    chosen="${wallpapers[$next_idx]}"
elif [[ "$ACTION" == "prev" ]]; then
    prev_idx=$(( (idx - 1 + ${#wallpapers[@]}) % ${#wallpapers[@]} ))
    chosen="${wallpapers[$prev_idx]}"
else
    # Interactive Rofi menu with image previews
    rofi_input=""
    for w in "${wallpapers[@]}"; do
        rofi_input+="${w}\x00icon\x1f${WALLPAPERS_DIR}/${w}\n"
    done

    chosen=$(echo -e -n "$rofi_input" | rofi -dmenu -i -show-icons \
        -p " Wallpaper" \
        -theme "$CURRENT_LINK/rofi/launcher.rasi" \
        -theme-str 'element-icon { size: 6ch; } listview { columns: 2; }' \
        2>/dev/null) || true

    if [[ -z "$chosen" ]]; then
        exit 0  # User cancelled
    fi
    
    # Verify choice
    if [[ ! -f "$WALLPAPERS_DIR/$chosen" ]]; then
        exit 1
    fi
fi

# Apply chosen wallpaper
if [[ -n "$chosen" ]]; then
    # Ensure daemon is running
    if ! pgrep -x swww-daemon >/dev/null 2>&1; then
        swww-daemon &
        sleep 0.5
    fi

    # --- Chameleon: delegate to pywal pipeline ---
    CURRENT_THEME=$(basename "$(readlink -f "$CURRENT_LINK")")
    if [[ "$CURRENT_THEME" == "Chameleon" ]]; then
        bash "$HOME/.config/hypr/scripts/chameleon-chwall.sh" "$WALLPAPERS_DIR/$chosen" 2>/dev/null || true
        exit 0
    fi

    swww img "$WALLPAPERS_DIR/$chosen" \
        --transition-fps 60 \
        --transition-type any \
        --transition-duration 2
        
    # Save state
    echo "$chosen" > "$STATE_FILE"
    
    notify-send "Wallpaper" "Switched to $chosen" -t 2000
fi
