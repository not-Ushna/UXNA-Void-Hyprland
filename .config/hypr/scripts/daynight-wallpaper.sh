#!/bin/bash
# ─────────────────────────────────────────────────────────
#  daynight-wallpaper.sh
#  Switches between day and night wallpaper variants
#  based on current hour. Run every 30 minutes by systemd.
# ─────────────────────────────────────────────────────────

THEMES_DIR="$HOME/.config/hypr/themes"
CURRENT_LINK="$THEMES_DIR/current"

# Bail out if no current theme symlink
[[ -L "$CURRENT_LINK" ]] || exit 0

WALLPAPERS_DIR="$CURRENT_LINK/wallpapers"
HOUR=$(date +"%H")

# Day: 06:00–18:59 | Night: 19:00–05:59
if (( 10#$HOUR >= 6 && 10#$HOUR < 19 )); then
    PERIOD="day"
else
    PERIOD="night"
fi

# Find period-specific wallpaper, fall back to main.*
WALLPAPER=""
for ext in gif webp png jpg jpeg; do
    if [[ -f "$WALLPAPERS_DIR/main-${PERIOD}.${ext}" ]]; then
        WALLPAPER="$WALLPAPERS_DIR/main-${PERIOD}.${ext}"
        break
    fi
done

# If no day/night variant, use main.*
if [[ -z "$WALLPAPER" ]]; then
    for ext in gif webp png jpg jpeg; do
        if [[ -f "$WALLPAPERS_DIR/main.${ext}" ]]; then
            WALLPAPER="$WALLPAPERS_DIR/main.${ext}"
            break
        fi
    done
fi

[[ -z "$WALLPAPER" ]] && exit 0

# Check if swww-daemon is running
if ! pgrep -x swww-daemon > /dev/null 2>&1; then
    swww-daemon &
    sleep 0.5
fi

# Get current wallpaper — avoid unnecessary transitions
CURRENT_WP=$(swww query 2>/dev/null | grep -o 'image: .*' | sed 's/image: //' | head -1)
[[ "$CURRENT_WP" == "$WALLPAPER" ]] && exit 0

# Apply with a slow, gentle fade transition
swww img "$WALLPAPER" \
    --transition-fps 60 \
    --transition-type fade \
    --transition-duration 3 \
    --transition-bezier 0.25,0.1,0.25,1

echo "[daynight] Switched to $PERIOD wallpaper: $WALLPAPER"
