# ╔══════════════════════════════════════════════════════════════════════╗
# ║  MODERN CLI REPLACEMENTS                                             ║
# ╚══════════════════════════════════════════════════════════════════════╝

# eza: A modern, beautiful replacement for 'ls'
alias ls="eza --icons=always --color=always --group-directories-first"
alias ll="eza --icons=always --color=always --group-directories-first -l"
alias la="eza --icons=always --color=always --group-directories-first -la"

# bat: A modern replacement for 'cat' with syntax highlighting
alias cat="bat --style=plain"

# zoxide: A smarter 'cd' that remembers your frequent folders
eval "$(zoxide init zsh)"

# Pokemon colorscripts
alias pokemon='pokemon-colorscripts -r --no-title'

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  GITHUB SYNC & BACKUP ALIASES                                        ║
# ╚══════════════════════════════════════════════════════════════════════╝

# `sync`: Informs the user about the new symlink architecture
sync_repo() {
  local text_color="\e[38;5;82m"
  echo -e "${text_color}All your configurations are now perfectly symlinked directly to your Git repository!${reset_color}"
  echo -e "You no longer need to run 'sync'. Any changes you make are instantly ready to be pushed."
  echo -e "Just run \e[38;5;226mpush\e[0m to commit and push your changes to GitHub!"
}
alias sync='sync_repo'

# `push`: Automatically stages, commits, and pushes your synced configs
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
