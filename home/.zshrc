# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Sync function with text animation for Void-Hyprland repository
sync_repo() {
  local repo_path="$HOME/Projects/UXNA-Void-Hyprland"
  local text_color="\e[38;5;82m"
  local file_color="\e[38;5;226m"
  local err_color="\e[38;5;196m"
  local reset_color="\e[0m"

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
  local j
  for ((j=1; j<=2; j++)); do
    for i in {1..10}; do
      echo -en "\b${spin[$i]}"
      sleep 0.05
    done
  done
  echo -en "\b \b\n"

  # Automatically copy local active configs into the repo folder and capture changes
  local changed_files=""
  changed_files+=$(rsync -ai --delete "$HOME/.config/hypr/" "$repo_path/.config/hypr/" 2>/dev/null | grep -E '^>|^cd|^\*deleting' | awk '{print $2}')
  changed_files+=$'\n'$(rsync -ai --delete "$HOME/.config/fastfetch/" "$repo_path/.config/fastfetch/" 2>/dev/null | grep -E '^>|^cd|^\*deleting' | awk '{print $2}')
  changed_files+=$'\n'$(rsync -ai "$HOME/.zshrc" "$repo_path/home/.zshrc" 2>/dev/null | grep -E '^>|^cd' | awk '{print $2}')
  changed_files+=$'\n'$(rsync -ai "$HOME/.p10k.zsh" "$repo_path/home/.p10k.zsh" 2>/dev/null | grep -E '^>|^cd' | awk '{print $2}')

  # Clean up empty lines
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

# Unified fastfetch wrapper for theme-specific layouts
function fastfetch() {
    local theme_dir="$HOME/.config/hypr/themes/current"
    local theme_name="$(basename "$(readlink -f "$theme_dir")" 2>/dev/null)"
    
    if [[ "$theme_name" == "Evangelion" ]]; then
        local logos=("logo1.txt" "logo2.txt" "logo3.txt" "logo.png" "default")
        local idx=$(( RANDOM % ${#logos[@]} + 1 ))
        local rand_logo=${logos[$idx]}
        local logo_path="$theme_dir/fastfetch/$rand_logo"
        
        if [[ "$rand_logo" == "default" ]]; then
            command fastfetch -c "$HOME/.config/fastfetch/config.jsonc" --logo-color-1 red --logo-color-2 yellow "$@"
        elif [[ "$rand_logo" == *.png ]]; then
            command fastfetch -c "$HOME/.config/fastfetch/config.jsonc" --logo-type kitty --logo "$logo_path" --logo-width 35 --logo-height 16 --logo-padding-top 1 --logo-padding-left 2 --logo-padding-right 4 "$@"
        else
            command fastfetch -c "$HOME/.config/fastfetch/config.jsonc" --logo-type file --logo "$logo_path" --logo-color-1 red --logo-color-2 yellow --logo-padding-top 2 --logo-padding-left 2 --logo-padding-right 4 "$@"
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
        command fastfetch -c "$HOME/.config/hypr/themes/Chameleon/fastfetch/config.jsonc" --logo void --logo-color-1 cyan --logo-color-2 $'\e[38;2;93;129;152m' "$@"
        return
    fi
    
    command fastfetch "$@"
}
