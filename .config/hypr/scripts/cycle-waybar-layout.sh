#!/bin/bash
# ============================================================
# cycle-waybar-layout.sh — Waybar Layout Cycler
# Cycles through Waybar layout files while preserving the
# current theme's colors.
# ============================================================

set -euo pipefail
exec > /tmp/cycle.log 2>&1
set -x

GLOBAL_LAYOUTS_DIR="$HOME/.config/hypr/waybar-layouts"
THEME_LAYOUTS_DIR="$HOME/.config/hypr/themes/current/waybar/layouts"
CURRENT_LAYOUT_LINK="$HOME/.config/hypr/waybar/current-layout"
CURRENT_THEME_STYLE="$HOME/.config/hypr/themes/current/waybar/style.css"

# Get sorted list of layout file paths
mapfile -t layouts < <(
    {
        if [[ -d "$GLOBAL_LAYOUTS_DIR" ]]; then
            find "$GLOBAL_LAYOUTS_DIR/" -maxdepth 1 -type f -name "layout-*" -printf "%p\n"
        fi
        if [[ -d "$THEME_LAYOUTS_DIR" ]]; then
            find "$THEME_LAYOUTS_DIR/" -maxdepth 1 -type f -name "layout-*" -printf "%p\n"
        fi
    } | sort
)

if [[ ${#layouts[@]} -eq 0 ]]; then
    notify-send "Waybar Layout" "No layout files found."
    exit 1
fi

# Get current layout path
current_path=""
if [[ -L "$CURRENT_LAYOUT_LINK" ]]; then
    current_path=$(readlink -f "$CURRENT_LAYOUT_LINK")
elif [[ -f "$CURRENT_LAYOUT_LINK" ]]; then
    current_path=$(realpath "$CURRENT_LAYOUT_LINK")
fi

# Find current index
idx=0
current_file=$(basename "$current_path")
for i in "${!layouts[@]}"; do
    if [[ "$(basename "${layouts[$i]}")" == "$current_file" ]]; then
        idx=$i
        break
    fi
done

# Compute next (circular)
next_idx=$(( (idx + 1) % ${#layouts[@]} ))
next_layout="${layouts[$next_idx]}"

# Update symlink
ln -sfn "$next_layout" "$CURRENT_LAYOUT_LINK"

# Kill waybar and wait for it to exit
killall waybar 2>/dev/null || true
while pgrep -x waybar >/dev/null; do
    sleep 0.1
done
killall -9 waybar 2>/dev/null || true

# Restart Waybar
setsid waybar -c "$CURRENT_LAYOUT_LINK" -s "$CURRENT_THEME_STYLE" > ~/.cache/waybar-cycle.log 2>&1 &
disown

# Notify
filename=$(basename "$next_layout")
notify-send "Waybar Layout" "Switched to ${filename/layout-/}" -t 2000
