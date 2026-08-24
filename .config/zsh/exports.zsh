# ╔══════════════════════════════════════════════════════════════════════╗
# ║  OH-MY-ZSH CONFIGURATION & EXPORTS                                   ║
# ╚══════════════════════════════════════════════════════════════════════╝
export ZSH="$HOME/.oh-my-zsh"

# Prompt Theme
# Change this if you don't want to use Powerlevel10k (e.g. "robbyrussell").
ZSH_THEME="powerlevel10k/powerlevel10k"

# Add or remove plugins here. Keep this list lean for maximum terminal speed!
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

# Export PATH
export PATH="$HOME/.local/bin:$PATH"
