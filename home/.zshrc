# ╭──────────────────────────────────────────────────────────────────────────╮
# │                                                                          │
# │                              ~ / . Z S H R C                             │
# │                                                                          │
# │                      UXNA's Aesthetic Environment                        │
# │                                                                          │
# ╰──────────────────────────────────────────────────────────────────────────╯
#
#  EDIT INSTRUCTIONS: 
#  - This file controls how your terminal behaves, looks, and feels.
#  - To apply any changes you make here, type: `source ~/.zshrc` in your terminal.
#  - Comment out a line by adding a `#` at the start of it.
#  - Uncomment a line by removing the `#` at the start of it.

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  01. POWERLEVEL10K PROMPT INITIALIZATION                             ║
# ╚══════════════════════════════════════════════════════════════════════╝
# NOTE: This must stay at the very top of .zshrc. 
# It handles instant prompt rendering for blazing fast terminal startups.
local _current_theme_path="$HOME/.config/hypr/themes/current"
if [[ ! -f "$_current_theme_path/starship/palette.toml" ]]; then
    if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
      source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
    fi
fi



# ╔══════════════════════════════════════════════════════════════════════╗
# ║  04. CUSTOM ZSH MODULES                                              ║
# ╚══════════════════════════════════════════════════════════════════════╝
# These override legacy, boring Unix commands with modern, colorful Rust rewrites.
source "$HOME/.config/zsh/aliases.zsh"
source "$HOME/.config/zsh/functions.zsh"
source "$HOME/.config/zsh/exports.zsh"

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  05. TERMINAL AESTHETICS & QUALITY OF LIFE                           ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  👻 Autosuggestions (Fish-style)                                      ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Shows subtle grey ghost text of your command history as you type.
# Press 'Right Arrow' (→) to accept the suggestion.
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#555555"

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  🌈 Syntax Highlighting                                               ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Commands turn green when valid, and red when they have a typo.
# Note: This MUST be the last source command in this file.
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

local current_theme_name="$(basename "$(readlink -f "$HOME/.config/hypr/themes/current")" 2>/dev/null)"
if [[ "$current_theme_name" == "PromisedFuture" ]]; then
    # Highlighting color tweaks (tailored to look great on Frutiger Aero themes)
    ZSH_HIGHLIGHT_STYLES[command]="fg=#50C8FF,bold" # Sky blue
    ZSH_HIGHLIGHT_STYLES[alias]="fg=#50C8FF,bold"
    ZSH_HIGHLIGHT_STYLES[builtin]="fg=#50C8FF"
    ZSH_HIGHLIGHT_STYLES[function]="fg=#50C8FF"
    ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#FF6B6B,bold" # Fail red
    ZSH_HIGHLIGHT_STYLES[path]="fg=#FFFFFF,underline" # White
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#F7DC6F"
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#F7DC6F"
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#F7DC6F"
    ZSH_HIGHLIGHT_STYLES[comment]="fg=#1A3A5C,italic"
else
    # Highlighting color tweaks (tailored to look great on Chameleon/Dark themes)
    ZSH_HIGHLIGHT_STYLES[command]="fg=cyan,bold"
    ZSH_HIGHLIGHT_STYLES[alias]="fg=cyan,bold"
    ZSH_HIGHLIGHT_STYLES[builtin]="fg=cyan"
    ZSH_HIGHLIGHT_STYLES[function]="fg=cyan"
    ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=red,bold"
    ZSH_HIGHLIGHT_STYLES[path]="fg=white,underline"
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=yellow"
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=yellow"
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=yellow"
    ZSH_HIGHLIGHT_STYLES[comment]="fg=#555555,italic"
fi



# ╔══════════════════════════════════════════════════════════════════════╗
# ║  08. POWERLEVEL10K PROMPT CONFIGURATION                              ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Source the .p10k.zsh configuration file to style the prompt.
# Run `p10k configure` in the terminal to visually rebuild this file.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh



# Run a random pokemon colorscript on startup ONLY if the active theme is PixelCraft
if [[ -L ~/.config/hypr/themes/current ]]; then
    CURRENT_THEME=$(basename "$(readlink -f ~/.config/hypr/themes/current)")
    if [[ "$CURRENT_THEME" == "PixelCraft" ]]; then
        pokemon
    fi
fi

# End of ~/.zshrc
