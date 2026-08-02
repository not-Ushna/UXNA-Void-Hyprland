# ╔══════════════════════════════════════════════════════╗
# ║  ~/.zshrc  ·  uxna's Zsh configuration             ║
# ╚══════════════════════════════════════════════════════╝

# --- Powerlevel10k Instant Prompt ------------------------------
# Must stay at the very top of .zshrc.
# Anything requiring console input must go ABOVE this block.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- Oh-My-Zsh -------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# --- OMZ Options (uncomment to enable) -------------------------
# CASE_SENSITIVE="true"
# HYPHEN_INSENSITIVE="true"
# zstyle ':omz:update' mode disabled   # disable auto-updates
# zstyle ':omz:update' mode auto       # update automatically
# zstyle ':omz:update' mode reminder   # remind me to update
# zstyle ':omz:update' frequency 13
# DISABLE_MAGIC_FUNCTIONS="true"
# DISABLE_LS_COLORS="true"
# DISABLE_AUTO_TITLE="true"
# ENABLE_CORRECTION="true"
# COMPLETION_WAITING_DOTS="true"
# DISABLE_UNTRACKED_FILES_DIRTY="true"
# HIST_STAMPS="yyyy-mm-dd"
# ZSH_CUSTOM=/path/to/new-custom-folder

# --- Plugins ---------------------------------------------------
# Curated to match installed tools — keep this list lean.
plugins=(
    git                      # git aliases (gst, gco, gp, gl, gd …)
    sudo                     # press ESC twice to prepend sudo to last command
    extract                  # `x file.tar.gz` — universal archive extractor
    colored-man-pages         # syntax-colored man pages
    common-aliases            # ll, la, l, ... standard ls aliases
    copypath                  # `copypath` copies current dir to clipboard
    copyfile                  # `copyfile file` copies file contents to clipboard
    dirhistory                # Alt+← / Alt+→ to navigate directory history
    history-substring-search  # Up/Down arrow searches history by typed prefix
    fzf                       # Ctrl+R fuzzy history, Ctrl+T fuzzy file insert
    npm                       # npm aliases & completions
    python                    # python/pip aliases & venv helpers
    rust                      # cargo/rustup completions
    rsync                     # rsync aliases (rsync-copy, rsync-move …)
)

source $ZSH/oh-my-zsh.sh

# --- Autosuggestions -------------------------------------------
# Fish-style inline grey suggestions as you type (→ to accept)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)  # history first, then tab-complete
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#555555"   # subtle grey ghost text

# --- Syntax Highlighting ---------------------------------------
# Commands turn green when valid, red when unknown (must be last)
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
# Tweak highlight colors to match the Chameleon theme
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

# --- User Config (uncomment to enable) -------------------------
# export MANPATH="/usr/local/man:$MANPATH"
# export LANG=en_US.UTF-8
# export EDITOR='nvim'
# export ARCHFLAGS="-arch $(uname -m)"
# alias zshconfig="$EDITOR ~/.zshrc"
# alias ohmyzsh="$EDITOR ~/.oh-my-zsh"

# --- Powerlevel10k Prompt --------------------------------------
# Run `p10k configure` to customize, or edit ~/.p10k.zsh directly
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- Sync Alias ------------------------------------------------
# `sync` — copies active configs into ~/Projects/UXNA-Void-Hyprland
# using rsync only (no git operations).
sync_repo() {
  local repo_path="$HOME/Projects/UXNA-Void-Hyprland"
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

  # Spinner while rsync runs
  echo -n "Syncing configs to repository... "
  local spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local j
  for ((j=1; j<=2; j++)); do
    for i in {1..10}; do
      echo -en "\b${spin[$i]}"
      sleep 0.05
    done
  done
  echo -en "\b \b\n"

  # Rsync active configs into repo folder and capture changes
  local changed_files=""
  changed_files+=$(rsync -ai --delete "$HOME/.config/hypr/"      "$repo_path/.config/hypr/"      2>/dev/null | grep -E '^>|^cd|^\*deleting' | awk '{print $2}')
  changed_files+=$'\n'$(rsync -ai --delete "$HOME/.config/fastfetch/" "$repo_path/.config/fastfetch/" 2>/dev/null | grep -E '^>|^cd|^\*deleting' | awk '{print $2}')
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

# --- Fastfetch Wrapper -----------------------------------------
# Theme-aware fastfetch: picks the right logo/config per active theme.
# Supports: Evangelion (random logo), Lumon, Chameleon, and fallback.
function fastfetch() {
    local theme_dir="$HOME/.config/hypr/themes/current"
    local theme_name="$(basename "$(readlink -f "$theme_dir")" 2>/dev/null)"

    if [[ "$theme_name" == "Evangelion" ]]; then
        # Pick a random logo from the Evangelion theme assets
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
        # 50/50 between custom logo and Void logo
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

    # Fallback — default fastfetch behavior
    command fastfetch "$@"
}

# --- Modern CLI Replacements -----------------------------------
# eza: better ls with colors and icons
alias ls="eza --icons=always --color=always --group-directories-first"
alias ll="eza --icons=always --color=always --group-directories-first -l"
alias la="eza --icons=always --color=always --group-directories-first -la"

# bat: better cat with syntax highlighting
alias cat="bat --style=plain"

# zoxide: smarter cd
eval "$(zoxide init zsh)"
