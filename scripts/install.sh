#!/bin/bash
# ============================================================
# install.sh — Void Linux Hyprland Themes Installer
#
# Sets up a complete Hyprland desktop environment on Void Linux
# with theme switching support.
#
# Usage:
#   ./scripts/install.sh
#   ./scripts/install.sh --no-packages    # Skip package install
#   ./scripts/install.sh --no-shell       # Skip shell setup
# ============================================================

set -euo pipefail

# ---- Configuration ----
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$HOME/.config"
HYPR_DIR="$CONFIG_DIR/hypr"
DEFAULT_THEME="Jade"
DEFAULT_LAYOUT="layout-default.jsonc"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ---- Parse arguments ----
INSTALL_PACKAGES=true
SETUP_SHELL=true

for arg in "$@"; do
    case "$arg" in
        --no-packages) INSTALL_PACKAGES=false ;;
        --no-shell)    SETUP_SHELL=false ;;
        --help|-h)
            echo "Usage: install.sh [--no-packages] [--no-shell]"
            echo "  --no-packages  Skip package installation"
            echo "  --no-shell     Skip Zsh/Oh-My-Zsh setup"
            exit 0
            ;;
    esac
done

# ---- Helper functions ----
info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ---- Banner ----
echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║     Void-Hyprland Themes Installer                  ║"
echo "║     A themeable Hyprland desktop for Void Linux      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ---- Step 1: Install packages ----
if [[ "$INSTALL_PACKAGES" == true ]]; then
    info "Installing system packages..."

    # Core packages available in Void repos
    PACKAGES=(
        hyprland
        waybar
        rofi-wayland
        dunst
        kitty
        thunar
        hyprlock
        wlogout
        swayidle
        grim
        slurp
        wl-clipboard
        cliphist
        pipewire
        wireplumber
        nwg-look
        kvantum
        qt5ct
        qt6ct
        polkit-gnome
        brightnessctl
        NetworkManager
        blueman
        pavucontrol
        gsettings-desktop-schemas
        dconf
        papirus-icon-theme
        zsh
        fastfetch
        git
        curl
        wget
        unzip
        base-devel
    )

    # Build the install command — ignore packages that don't exist
    info "Syncing repositories..."
    sudo xbps-install -Sy

    info "Installing packages (some may already be installed)..."
    for pkg in "${PACKAGES[@]}"; do
        if xbps-query "$pkg" >/dev/null 2>&1; then
            ok "$pkg already installed"
        else
            if sudo xbps-install -y "$pkg" 2>/dev/null; then
                ok "Installed $pkg"
            else
                warn "Could not install $pkg — may not exist in repos or has a different name"
            fi
        fi
    done

    # Install fonts
    info "Installing fonts..."
    FONT_PACKAGES=(
        font-jetbrains-mono-nerd
        nerd-fonts
        font-inter
    )
    for pkg in "${FONT_PACKAGES[@]}"; do
        if xbps-query "$pkg" >/dev/null 2>&1; then
            ok "$pkg already installed"
        else
            sudo xbps-install -y "$pkg" 2>/dev/null || warn "Could not install $pkg"
        fi
    done

    ok "Package installation complete"
fi

# ---- Step 2: Build swww if not available ----
if ! command -v swww >/dev/null 2>&1; then
    info "swww not found — checking for pre-built binary..."
    if [[ -x "$HOME/Projects/swww/target/release/swww" ]]; then
        sudo cp "$HOME/Projects/swww/target/release/swww" /usr/local/bin/swww
        sudo cp "$HOME/Projects/swww/target/release/swww-daemon" /usr/local/bin/swww-daemon
        ok "Installed swww from pre-built binary"
    elif [[ -x "$HOME/Projects/swww-0.11.2/target/release/swww" ]]; then
        sudo cp "$HOME/Projects/swww-0.11.2/target/release/swww" /usr/local/bin/swww
        sudo cp "$HOME/Projects/swww-0.11.2/target/release/swww-daemon" /usr/local/bin/swww-daemon
        ok "Installed swww from pre-built binary"
    else
        info "Building swww from source (requires cargo)..."
        if ! command -v cargo >/dev/null 2>&1; then
            sudo xbps-install -y rust cargo
        fi
        SWWW_BUILD_DIR="/tmp/swww-build"
        git clone https://github.com/LGFae/swww.git "$SWWW_BUILD_DIR" 2>/dev/null || true
        (cd "$SWWW_BUILD_DIR" && cargo build --release)
        sudo cp "$SWWW_BUILD_DIR/target/release/swww" /usr/local/bin/
        sudo cp "$SWWW_BUILD_DIR/target/release/swww-daemon" /usr/local/bin/
        rm -rf "$SWWW_BUILD_DIR"
        ok "Built and installed swww"
    fi
else
    ok "swww already installed"
fi

# ---- Step 3: Set up shell ----
if [[ "$SETUP_SHELL" == true ]]; then
    info "Setting up Zsh..."

    # Set Zsh as default shell
    ZSH_PATH=$(which zsh 2>/dev/null || echo "/bin/zsh")
    if [[ "$SHELL" != "$ZSH_PATH" ]]; then
        info "Setting Zsh as default shell..."
        chsh -s "$ZSH_PATH" 2>/dev/null || warn "Could not set Zsh as default shell (run: chsh -s $ZSH_PATH)"
    fi

    # Install Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        ok "Oh My Zsh installed"
    else
        ok "Oh My Zsh already installed"
    fi

    # Install Powerlevel10k
    P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ ! -d "$P10K_DIR" ]]; then
        info "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
        ok "Powerlevel10k installed"
    else
        ok "Powerlevel10k already installed"
    fi

    # Install zsh plugins
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi

    ok "Shell setup complete"
fi

# ---- Step 4: Backup existing config ----
if [[ -d "$HYPR_DIR" ]] && [[ ! -L "$HYPR_DIR" ]]; then
    BACKUP_DIR="$HYPR_DIR.bak.$(date +%Y%m%d_%H%M%S)"
    warn "Existing Hyprland config found — backing up to $BACKUP_DIR"
    mv "$HYPR_DIR" "$BACKUP_DIR"
fi

# ---- Step 5: Symlink Hyprland config ----
info "Symlinking Hyprland config..."
mkdir -p "$CONFIG_DIR"

# Remove existing symlink if present
[[ -L "$HYPR_DIR" ]] && rm "$HYPR_DIR"

ln -sfn "$REPO_DIR/.config/hypr" "$HYPR_DIR"
ok "Linked $HYPR_DIR → $REPO_DIR/.config/hypr"

# ---- Step 6: Set up Waybar layouts ----
info "Setting up Waybar layouts..."
WAYBAR_LAYOUTS_DEST="$HYPR_DIR/waybar-layouts"

# Symlink the layouts directory
if [[ ! -L "$WAYBAR_LAYOUTS_DEST" ]]; then
    ln -sfn "$REPO_DIR/waybar-layouts" "$WAYBAR_LAYOUTS_DEST"
fi

# Create waybar directory and set initial layout symlink
mkdir -p "$HYPR_DIR/waybar"
if [[ ! -L "$HYPR_DIR/waybar/current-layout" ]]; then
    ln -sfn "$WAYBAR_LAYOUTS_DEST/$DEFAULT_LAYOUT" "$HYPR_DIR/waybar/current-layout"
fi
ok "Waybar layouts configured (default: $DEFAULT_LAYOUT)"

# ---- Step 7: Set initial theme ----
info "Setting initial theme to $DEFAULT_THEME..."
THEMES_DIR="$HYPR_DIR/themes"
if [[ ! -L "$THEMES_DIR/current" ]]; then
    ln -sfn "$THEMES_DIR/$DEFAULT_THEME" "$THEMES_DIR/current"
fi
ok "Active theme: $DEFAULT_THEME"

# ---- Step 8: Symlink shell configs ----
info "Symlinking shell configs..."
if [[ -f "$HOME/.zshrc" ]] && [[ ! -L "$HOME/.zshrc" ]]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d_%H%M%S)"
    warn "Backed up existing .zshrc"
fi
ln -sfn "$REPO_DIR/home/.zshrc" "$HOME/.zshrc"

if [[ -f "$REPO_DIR/home/.p10k.zsh" ]]; then
    ln -sfn "$REPO_DIR/home/.p10k.zsh" "$HOME/.p10k.zsh"
fi
ok "Shell configs linked"

# ---- Step 9: Make scripts executable ----
info "Setting script permissions..."
chmod +x "$HYPR_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$REPO_DIR/scripts/"*.sh 2>/dev/null || true

# Make GTK settings scripts executable
find "$THEMES_DIR" -name "settings.sh" -exec chmod +x {} \;
ok "Scripts are executable"

# ---- Step 10: Enable services ----
info "Checking PipeWire services..."
if command -v pipewire >/dev/null 2>&1; then
    # On Void, PipeWire is typically started via the session
    # Ensure the autostart entries exist
    mkdir -p "$CONFIG_DIR/pipewire"
    ok "PipeWire available — will start with Hyprland session"
fi

# ---- Complete ----
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║          Installation Complete!                      ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Keybind Cheat Sheet:${NC}"
echo -e "  ${CYAN}Super + Return${NC}     Open terminal (Kitty)"
echo -e "  ${CYAN}Super + D${NC}          App launcher (Rofi)"
echo -e "  ${CYAN}Super + T${NC}          Switch theme"
echo -e "  ${CYAN}Super + Shift + B${NC}  Cycle Waybar layout"
echo -e "  ${CYAN}Super + L${NC}          Lock screen"
echo -e "  ${CYAN}Super + Shift + L${NC}  Logout menu"
echo -e "  ${CYAN}Super + Q${NC}          Close window"
echo -e "  ${CYAN}Super + F${NC}          Fullscreen"
echo -e "  ${CYAN}Super + E${NC}          File manager (Thunar)"
echo -e "  ${CYAN}Super + V${NC}          Clipboard history"
echo -e "  ${CYAN}Print${NC}              Screenshot (area)"
echo ""
echo -e "Active theme: ${GREEN}$DEFAULT_THEME${NC}"
echo -e "Active layout: ${GREEN}${DEFAULT_LAYOUT/layout-/}${NC}"
echo ""
echo -e "${YELLOW}Log out and select Hyprland from your login manager to start.${NC}"
