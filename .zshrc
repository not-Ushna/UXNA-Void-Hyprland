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
#  - Most of the configuration has been modularized into ~/.config/zsh/

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  01. POWERLEVEL10K PROMPT INITIALIZATION                             ║
# ╚══════════════════════════════════════════════════════════════════════╝
# NOTE: This must stay at the very top of .zshrc. 
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  02. LOAD MODULAR CONFIGURATION                                      ║
# ╚══════════════════════════════════════════════════════════════════════╝
if [[ -d "$HOME/.config/zsh" ]]; then
    for f in "$HOME/.config/zsh/"*.zsh; do
        source "$f"
    done
fi

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  03. TERMINAL AESTHETICS & QUALITY OF LIFE                           ║
# ╚══════════════════════════════════════════════════════════════════════╝

# Autosuggestions (Fish-style)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#555555"

# Syntax Highlighting
# Note: This MUST be the last source command before prompt config.
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

local current_theme_name="$(basename "$(readlink -f "$HOME/.config/hypr/themes/current")" 2>/dev/null)"
if [[ "$current_theme_name" == "PromisedFuture" ]]; then
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
# ║  04. POWERLEVEL10K PROMPT CONFIGURATION                              ║
# ╚══════════════════════════════════════════════════════════════════════╝
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  05. STARTUP SCRIPTS                                                 ║
# ╚══════════════════════════════════════════════════════════════════════╝
if [[ -L ~/.config/hypr/themes/current ]]; then
    CURRENT_THEME=$(basename "$(readlink -f ~/.config/hypr/themes/current)")
    if [[ "$CURRENT_THEME" == "PixelCraft" ]]; then
        pokemon
    fi
fi
