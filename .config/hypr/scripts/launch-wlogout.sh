#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
#  ✦  launch-wlogout.sh
#  ✦  Kill any existing instances first
# ─────────────────────────────────────────────────────────

pkill -x wlogout
sleep 0.1

THEME=$(readlink -f ~/.config/hypr/themes/current | awk -F/ '{print $NF}')

# Output to a log file for debugging
exec > /tmp/wlogout_launch.log 2>&1
echo "Launching wlogout for theme: $THEME"

if [[ "$THEME" == "Chameleon" ]]; then
    # 3×2 compact grid
    exec wlogout --protocol layer-shell -b 3 -c 0 -r 0 -m 0 -L 330 -R 330 -T 140 -B 140 \
        --layout ~/.config/hypr/themes/current/wlogout/layout \
        --css ~/.config/hypr/themes/current/wlogout/style.css
else
    # Default 3x2 grid design for other themes (Jade, Lumon, etc.)
    exec wlogout --protocol layer-shell -b 3 -m 200 -L 400 -R 400 \
        --layout ~/.config/hypr/themes/current/wlogout/layout \
        --css ~/.config/hypr/themes/current/wlogout/style.css
fi
