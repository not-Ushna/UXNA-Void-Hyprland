#!/usr/bin/env bash

THEME=$(readlink -f ~/.config/hypr/themes/current | awk -F/ '{print $NF}')

if [[ "$THEME" == "Chameleon" ]]; then
    # 3×2 compact grid
    wlogout -b 3 -c 0 -r 0 -m 0 -L 330 -R 330 -T 140 -B 140 \
        --layout ~/.config/hypr/themes/current/wlogout/layout \
        --css ~/.config/hypr/themes/current/wlogout/style.css
else
    # Default 3x2 grid design for other themes (Jade, Lumon, etc.)
    wlogout -b 3 -m 200 -L 400 -R 400 --layout ~/.config/hypr/themes/current/wlogout/layout --css ~/.config/hypr/themes/current/wlogout/style.css
fi
