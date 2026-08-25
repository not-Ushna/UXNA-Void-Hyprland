# ╔══════════════════════════════════════════════════════════════════════╗
# ║  DYNAMIC FASTFETCH WRAPPER                                           ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Overrides the 'fastfetch' command so that it automatically picks the 
# correct logo, color scheme, and configuration for your currently active theme.
function fastfetch() {
    local theme_dir="$HOME/.config/hypr/themes/current"
    local theme_name="$(basename "$(readlink -f "$theme_dir")" 2>/dev/null)"

    if [[ "$theme_name" == "Evangelion" ]]; then
        local logos=("logo1.txt" "logo2.txt" "logo3.txt" "logo.png" "default")
        local idx=$(( RANDOM % ${#logos[@]} + 1 ))
        local rand_logo=${logos[$idx]}
        local logo_path="$theme_dir/fastfetch/$rand_logo"

        if [[ "$rand_logo" == "default" ]]; then
            command fastfetch -c "$HOME/.config/fastfetch/config.jsonc" \
                --logo-color-1 red --logo-color-2 yellow "$@"
        elif [[ "$rand_logo" == *.png ]]; then
            command fastfetch -c "$HOME/.config/fastfetch/config.jsonc" \
                --logo-type kitty --logo "$logo_path" \
                --logo-width 35 --logo-height 16 \
                --logo-padding-top 1 --logo-padding-left 2 --logo-padding-right 4 "$@"
        else
            command fastfetch -c "$HOME/.config/fastfetch/config.jsonc" \
                --logo-type file --logo "$logo_path" \
                --logo-color-1 red --logo-color-2 yellow \
                --logo-padding-top 2 --logo-padding-left 2 --logo-padding-right 4 "$@"
        fi
        return

    elif [[ "$theme_name" == "Lumon" ]]; then
        if (( RANDOM % 2 == 0 )); then
            command fastfetch --logo "$theme_dir/fastfetch/logo.txt" "$@"
        else
            command fastfetch --logo void --logo-color-1 cyan --logo-color-2 $'\e[38;2;93;129;152m' "$@"
        fi
        return

    elif [[ "$theme_name" == "Chameleon" ]]; then
        command fastfetch -c "$HOME/.config/hypr/themes/Chameleon/fastfetch/config.jsonc" \
            --logo void --logo-color-1 cyan --logo-color-2 $'\e[38;2;93;129;152m' "$@"
        return
    elif [[ "$theme_name" == "PixelCraft" ]]; then
        command fastfetch -c "$HOME/.config/hypr/themes/PixelCraft/fastfetch/config.jsonc" "$@"
        return

    elif [[ "$theme_name" == "dracula" || "$theme_name" == "gruvbox" || "$theme_name" == "nord" || "$theme_name" == "tokyo-night" || "$theme_name" == "one-dark" || "$theme_name" == "rose-pine" || "$theme_name" == "catppuccin-latte" || "$theme_name" == "catppuccin-mocha" ]]; then
        command fastfetch -c "$HOME/.config/fastfetch/simple.jsonc" "$@"
        return
    fi

    # Fallback to default behavior if the theme isn't explicitly configured above
    command fastfetch "$@"
}
