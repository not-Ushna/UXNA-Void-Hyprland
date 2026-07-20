#!/bin/bash
# ============================================================
# switch-theme.sh — Theme Switcher
# Lists themes via Rofi, updates the current symlink, and
# reloads all visual components.
#
# Usage:
#   switch-theme.sh           # Interactive Rofi menu
#   switch-theme.sh Jade      # Direct switch (no menu)
#   switch-theme.sh --grub    # Also update GRUB theme
# ============================================================

set -euo pipefail

THEMES_DIR="$HOME/.config/hypr/themes"
CURRENT_LINK="$THEMES_DIR/current"
UPDATE_GRUB=false

# Parse arguments
DIRECT_THEME=""
for arg in "$@"; do
    case "$arg" in
        --grub) UPDATE_GRUB=true ;;
        *) DIRECT_THEME="$arg" ;;
    esac
done

# List available themes (directories, excluding 'current')
mapfile -t themes < <(
    find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d \
        ! -name "current" \
        -printf "%f\n" | sort
)

if [[ ${#themes[@]} -eq 0 ]]; then
    notify-send "Theme Switcher" "No themes found in $THEMES_DIR"
    exit 1
fi

# Select theme
if [[ -n "$DIRECT_THEME" ]]; then
    chosen="$DIRECT_THEME"
    # Verify it exists
    if [[ ! -d "$THEMES_DIR/$chosen" ]]; then
        notify-send "Theme Switcher" "Theme '$chosen' not found"
        exit 1
    fi
else
    # Show Rofi menu with image previews based on the theme's first wallpaper
    rofi_input=""
    for t in "${themes[@]}"; do
        # Find the first wallpaper in the theme to use as an icon
        icon_path=$(find "$THEMES_DIR/$t/wallpapers" -maxdepth 1 -type f | sort | head -1 || true)
        if [[ -n "$icon_path" ]]; then
            rofi_input+="${t}\x00icon\x1f${icon_path}\n"
        else
            rofi_input+="${t}\n"
        fi
    done

    chosen=$(echo -e -n "$rofi_input" | rofi -dmenu -i -show-icons \
        -p " Theme" \
        -theme "$CURRENT_LINK/rofi/launcher.rasi" \
        -theme-str 'element-icon { size: 6ch; } listview { columns: 2; }' \
        2>/dev/null) || true

    if [[ -z "$chosen" ]]; then
        exit 0  # User cancelled
    fi
fi

# Get current theme name for comparison
current_theme=""
if [[ -L "$CURRENT_LINK" ]]; then
    current_theme=$(basename "$(readlink -f "$CURRENT_LINK")")
fi

if [[ "$chosen" == "$current_theme" ]]; then
    notify-send "Theme Switcher" "Already on '$chosen'"
    exit 0
fi

# ---- Apply the new theme ----

# 1. Update symlink
ln -sfn "$THEMES_DIR/$chosen" "$CURRENT_LINK"

# --- Chameleon: run pywal pipeline instead of static configs ---
if [[ "$chosen" == "Chameleon" ]]; then
    notify-send "🦎 Chameleon" "Generating palette from wallpaper..." -t 2000
    bash "$HOME/.config/hypr/scripts/chameleon-chwall.sh" 2>/dev/null || true
    exit 0
fi

# 2. Apply wallpaper (start swww-daemon if not running)
if ! pgrep -x swww-daemon >/dev/null 2>&1; then
    swww-daemon &
    sleep 0.5
fi

# Find wallpaper (try main.jpg, main.png, or first image)
WALLPAPER=""
for ext in jpg png jpeg webp; do
    if [[ -f "$CURRENT_LINK/wallpapers/main.$ext" ]]; then
        WALLPAPER="$CURRENT_LINK/wallpapers/main.$ext"
        break
    fi
done
if [[ -z "$WALLPAPER" ]]; then
    WALLPAPER=$(find "$CURRENT_LINK/wallpapers/" -type f -name "*.jpg" -o -name "*.png" | head -1)
fi

if [[ -n "$WALLPAPER" ]]; then
    swww img "$WALLPAPER" \
        --transition-fps 60 \
        --transition-type any \
        --transition-duration 2
fi

# 3. Reload Hyprland (picks up new colors.conf)
hyprctl reload 2>/dev/null || true

# 4. Restart Waybar
pkill waybar 2>/dev/null || true
pkill -9 waybar 2>/dev/null || true
sleep 0.3
WAYBAR_LAYOUT="$HOME/.config/hypr/waybar/current-layout"
if [[ -L "$WAYBAR_LAYOUT" ]] || [[ -f "$WAYBAR_LAYOUT" ]]; then
    nohup waybar -c "$WAYBAR_LAYOUT" -s "$CURRENT_LINK/waybar/style.css" >/dev/null 2>&1 &
fi

# 5. Restart Dunst
pkill dunst 2>/dev/null || true
sleep 0.2
if [[ -f "$CURRENT_LINK/dunst/dunstrc" ]]; then
    dunst -conf "$CURRENT_LINK/dunst/dunstrc" &
    disown
fi

# 6. Apply GTK theme
if [[ -f "$CURRENT_LINK/gtk/settings.sh" ]]; then
    bash "$CURRENT_LINK/gtk/settings.sh" 2>/dev/null || true
fi

# 7. Apply Qt/Kvantum theme
if command -v kvantummanager >/dev/null 2>&1; then
    if [[ -f "$CURRENT_LINK/qt/theme.txt" ]]; then
        theme_name=$(head -1 "$CURRENT_LINK/qt/theme.txt" | tr -d '[:space:]')
        if [[ -d "/usr/share/Kvantum/$theme_name" ]] || [[ -d "$HOME/.config/Kvantum/$theme_name" ]]; then
            kvantummanager --set "$theme_name" 2>/dev/null || true
        fi
    fi
fi

# 7.5 Apply fastfetch theme
if [[ -f "$CURRENT_LINK/fastfetch/config.jsonc" ]]; then
    mkdir -p "$HOME/.config/fastfetch"
    cp -f "$CURRENT_LINK/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc" 2>/dev/null || true
fi

# Reload running kitty terminals to pick up the updated current symlink
kill -SIGUSR1 $(pgrep kitty) 2>/dev/null || true
# 8. Update GRUB seamlessly in the background (no sudo required)
GRUB_BOOT_DIR="/boot/grub/themes/hyprtheme"
if [[ -d "$GRUB_BOOT_DIR" ]] && [[ -d "$CURRENT_LINK/grub" ]]; then
    # Since we chowned the hyprtheme folder in setup-grub-permissions.sh,
    # we can copy the new theme directly without a password!
    cp -r "$CURRENT_LINK/grub/"* "$GRUB_BOOT_DIR/" 2>/dev/null || true
fi

# 9. Notify
sleep 0.5  # Wait for dunst to start
notify-send "Theme Switcher" "Switched to $chosen" -t 3000
