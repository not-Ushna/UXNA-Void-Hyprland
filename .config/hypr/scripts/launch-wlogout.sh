#!/usr/bin/env bash

THEME=$(readlink -f ~/.config/hypr/themes/current | awk -F/ '{print $NF}')

if [[ "$THEME" == "Chameleon" ]]; then
    # 3-column × 2-row glassmorphism grid
    wlogout -b 3 -c 15 -r 15 -m 300 -L 200 -R 200 -T 100 -B 100 \
        --layout ~/.config/hypr/themes/current/wlogout/layout \
        --css ~/.config/hypr/themes/current/wlogout/style.css
else
    # Default 3x2 grid design for other themes (Jade, Lumon, etc.)
    wlogout -b 3 -m 200 -L 400 -R 400 --layout ~/.config/hypr/themes/current/wlogout/layout --css ~/.config/hypr/themes/current/wlogout/style.css
fi
