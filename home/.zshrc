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
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  02. OH-MY-ZSH CONFIGURATION                                         ║
# ╚══════════════════════════════════════════════════════════════════════╝
export ZSH="$HOME/.oh-my-zsh"

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  🎨 Prompt Theme                                                      ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Change this if you don't want to use Powerlevel10k (e.g. "robbyrussell").
ZSH_THEME="powerlevel10k/powerlevel10k"

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  ⚙️ Optional Settings                                                ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Uncomment (remove the #) to enable any of these tweaks.
# CASE_SENSITIVE="true"              # Require exact casing for tab-completion
# HYPHEN_INSENSITIVE="true"          # Treat _ and - interchangeably
# zstyle ':omz:update' mode disabled # Stop Oh-My-Zsh from asking to update
# DISABLE_AUTO_TITLE="true"          # Stop terminal title from changing
# ENABLE_CORRECTION="true"           # Prompt to correct typos

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  03. PLUGINS                                                         ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Add or remove plugins here. Keep this list lean for maximum terminal speed!
# Available plugins: https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
plugins=(
    git                       # git aliases (gst, gco, gp, gl, gd …)
    sudo                      # press ESC twice to prepend 'sudo' to a command
    extract                   # type `x file.tar.gz` to extract anything effortlessly
    colored-man-pages         # syntax-colored manual pages
    common-aliases            # ll, la, l, ... standard ls aliases
    copypath                  # type `copypath` to copy the current folder path
    copyfile                  # type `copyfile file` to copy file contents
    dirhistory                # Alt+← / Alt+→ to go forward/back in directory history
    history-substring-search  # Type a few letters and use Up/Down arrow to search history
    fzf                       # Ctrl+R fuzzy history, Ctrl+T fuzzy file insert
    npm                       # node package manager aliases
    python                    # python/pip aliases & venv helpers
    rust                      # cargo/rustup completions
    rsync                     # rsync aliases (rsync-copy, rsync-move …)
)

source $ZSH/oh-my-zsh.sh

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  04. MODERN CLI REPLACEMENTS                                         ║
# ╚══════════════════════════════════════════════════════════════════════╝
# These override legacy, boring Unix commands with modern, colorful Rust rewrites.

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  📁 eza: A modern, beautiful replacement for 'ls'                     ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Change --group-directories-first to customize sorting behavior.
alias ls="eza --icons=always --color=always --group-directories-first"
alias ll="eza --icons=always --color=always --group-directories-first -l"
alias la="eza --icons=always --color=always --group-directories-first -la"

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  📄 bat: A modern replacement for 'cat' with syntax highlighting      ║
# ╚══════════════════════════════════════════════════════════════════════╝
# You can change --style=plain to --style=numbers to show line numbers.
alias cat="bat --style=plain"

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  🚀 zoxide: A smarter 'cd' that remembers your frequent folders       ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Type `z myfolder` instead of `cd ~/deep/path/to/myfolder`.
eval "$(zoxide init zsh)"

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
# ║  06. GITHUB SYNC & BACKUP ALIASES                                    ║
# ╚══════════════════════════════════════════════════════════════════════╝

# 🔄 `sync` 
# Copies your live system configurations into your local UXNA-Hyprland repo folder.
# NOTE: It does not push to GitHub! It only updates your local git folder.
sync_repo() {
  local repo_path="$HOME/Projects/UXNA-Hyprland"
  local text_color="\e[38;5;82m"
  local file_color="\e[38;5;226m"
  local err_color="\e[38;5;196m"
  local reset_color="\e[0m"

  # Animated typewriter output helper
  type_out() {
    local text="$1"
    local delay=0.03
    echo -ne "$2"
    local i
    for ((i=1; i<=${#text}; i++)); do
      echo -n "${text[i]}"
      sleep "$delay"
    done
    echo -e "$reset_color"
  }

  echo -n "Syncing configs to repository... "
  local spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local j; for ((j=1; j<=2; j++)); do
    for i in {1..10}; do echo -en "\b${spin[$i]}"; sleep 0.05; done
  done
  echo -en "\b \b\n"

  # Rsync active configs into repo folder and capture changes
  local changed_files=""
  changed_files+=$(rsync -ai --delete "$HOME/.config/hypr/"      "$repo_path/.config/hypr/"      2>/dev/null | grep -E '^>|^cd|^\*deleting' | awk '{print $2}')
  changed_files+=$'\n'$(rsync -ai --delete "$HOME/.config/fastfetch/" "$repo_path/.config/fastfetch/" 2>/dev/null | grep -E '^>|^cd|^\*deleting' | awk '{print $2}')
  changed_files+=$'\n'$(rsync -ai --delete "$HOME/.config/kitty/" "$repo_path/.config/kitty/" 2>/dev/null | grep -E '^>|^cd|^\*deleting' | awk '{print $2}')
  changed_files+=$'\n'$(rsync -ai "$HOME/.var/app/com.visualstudio.code/config/Code/User/settings.json" "$repo_path/vscode/settings.json" 2>/dev/null | grep -E '^>|^cd' | awk '{print $2}')
  changed_files+=$'\n'$(rsync -ai --delete "/boot/grub/themes/Pochita_Pochita/" "$repo_path/boot/grub/themes/Pochita_Pochita/" 2>/dev/null | grep -E '^>|^cd|^\*deleting' | awk '{print $2}')
  changed_files+=$'\n'$(rsync -ai "$HOME/.zshrc"    "$repo_path/home/.zshrc"    2>/dev/null | grep -E '^>|^cd' | awk '{print $2}')
  changed_files+=$'\n'$(rsync -ai "$HOME/.p10k.zsh" "$repo_path/home/.p10k.zsh" 2>/dev/null | grep -E '^>|^cd' | awk '{print $2}')

  # Remove blank lines from output
  changed_files=$(echo "$changed_files" | grep -v '^$')

  if [[ -n "$changed_files" ]]; then
    type_out "Found updates in the following files:" "$text_color"
    echo "$changed_files" | while IFS= read -r line; do
      type_out "  $line" "$file_color"
      sleep 0.05
    done
    type_out $'\nSuccessfully backed up updates to your local repo folder!' "$text_color"
  else
    type_out $'\nEverything is already up to date!' "$text_color"
  fi
}
alias sync='sync_repo'

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  🚀 `push`                                                            ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Automatically stages, commits, and pushes your synced configs to GitHub.
# Usage:
#   `push` -> Uses the default commit message
#   `push my custom message` -> Uses your custom commit message
push_repo() {
  local current_dir=$(pwd)
  cd "$HOME/Projects/UXNA-Hyprland" || return 1
  
  local commit_msg="$*"
  if [[ -z "$commit_msg" ]]; then
    commit_msg="sync latest configs and theme updates: $(date +'%Y-%m-%d %H:%M')"
  fi

  echo -e "\e[38;5;82mCommitting and pushing to GitHub...\e[0m"
  git add .
  git commit -m "$commit_msg" || echo -e "\e[38;5;226mNothing new to commit.\e[0m"
  git push
  
  cd "$current_dir"
}
alias push='push_repo'

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  07. DYNAMIC FASTFETCH WRAPPER                                       ║
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
    fi

    # Fallback to default behavior if the theme isn't explicitly configured above
    command fastfetch "$@"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  08. POWERLEVEL10K PROMPT CONFIGURATION                              ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Source the .p10k.zsh configuration file to style the prompt.
# Run `p10k configure` in the terminal to visually rebuild this file.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  09. POKEMON COLORSCRIPTS                                            ║
# ╚══════════════════════════════════════════════════════════════════════╝
export PATH="$HOME/.local/bin:$PATH"
alias pokemon='pokemon-colorscripts -r --no-title'

# Run a random pokemon colorscript on startup ONLY if the active theme is Pixel-Dream
if [[ -L ~/.config/hypr/themes/current ]]; then
    CURRENT_THEME=$(basename "$(readlink -f ~/.config/hypr/themes/current)")
    if [[ "$CURRENT_THEME" == "Pixel-Dream" ]]; then
        pokemon
    fi
fi

# End of ~/.zshrc
