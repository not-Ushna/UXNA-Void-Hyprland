#!/bin/bash
# ============================================================
# install.sh — Universal Hyprland Themes Installer
#
# Sets up a complete distro-agnostic Hyprland desktop environment
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
echo "║     Universal Hyprland Themes Installer             ║"
echo "║     A distro-agnostic themeable Hyprland desktop     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ---- Step 1: Check dependencies ----
if [[ "$INSTALL_PACKAGES" == true ]]; then
    info "Verifying dependencies..."
    if ! bash "$REPO_DIR/scripts/dependency-checker.sh"; then
        echo ""
        err "Missing dependencies detected! The installation will not proceed.\nPlease install them manually."
    fi
    ok "All dependencies are installed"
fi

# ---- Step 2: (Removed) ----
# swww is now enforced by dependency-checker.sh

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

# Link kitty and fastfetch
[[ -L "$CONFIG_DIR/kitty" ]] && rm "$CONFIG_DIR/kitty"
ln -sfn "$REPO_DIR/.config/kitty" "$CONFIG_DIR/kitty"
ok "Linked kitty config"

[[ -L "$CONFIG_DIR/fastfetch" ]] && rm "$CONFIG_DIR/fastfetch"
ln -sfn "$REPO_DIR/.config/fastfetch" "$CONFIG_DIR/fastfetch"
ok "Linked fastfetch config"

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
    ln -sfn "$DEFAULT_THEME" "$THEMES_DIR/current"
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

# ---- Step 9: Deploy Custom Assets (Anifetch & GIFs) ----
info "Deploying custom binaries and GIFs..."
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
cp -f "$REPO_DIR/bin/anifetch" "$BIN_DIR/"
cp -f "$REPO_DIR/bin/brrtfetch" "$BIN_DIR/"
chmod +x "$BIN_DIR/anifetch"
chmod +x "$BIN_DIR/brrtfetch"
ok "Installed anifetch and brrtfetch to $BIN_DIR"

GIF_DIR="$HOME/Pictures/brrtfetch"
mkdir -p "$GIF_DIR"
cp -rf "$REPO_DIR/assets/gifs" "$GIF_DIR/"
ok "Deployed custom GIFs to $GIF_DIR"

# ---- Step 10: Make scripts executable ----
info "Setting script permissions..."
chmod +x "$HYPR_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$REPO_DIR/scripts/"*.sh 2>/dev/null || true

# Make GTK settings scripts executable
find "$THEMES_DIR" -name "settings.sh" -exec chmod +x {} \;
ok "Scripts are executable"

# ---- Step 11: Enable services ----
info "Checking PipeWire services..."
if command -v pipewire >/dev/null 2>&1; then
    # PipeWire is typically started via the session
    # Ensure the autostart entries exist
    mkdir -p "$CONFIG_DIR/pipewire"
    ok "PipeWire available — will start with Hyprland session"
fi

info "Enabling essential services..."
if command -v systemctl &> /dev/null; then
    sudo systemctl enable NetworkManager 2>/dev/null || true
    sudo systemctl enable polkit 2>/dev/null || true
    sudo systemctl enable bluetooth 2>/dev/null || true
elif command -v sv &> /dev/null || [ -d /var/service ]; then
    if [ -d /etc/sv/dbus ]; then
        sudo ln -s /etc/sv/dbus /var/service/ 2>/dev/null || true
    fi
    if [ -d /etc/sv/NetworkManager ]; then
        sudo ln -s /etc/sv/NetworkManager /var/service/ 2>/dev/null || true
    fi
    if [ -d /etc/sv/polkitd ]; then
        sudo ln -s /etc/sv/polkitd /var/service/ 2>/dev/null || true
    fi
    if [ -d /etc/sv/bluetoothd ]; then
        sudo ln -s /etc/sv/bluetoothd /var/service/ 2>/dev/null || true
    fi
fi
ok "Essential services configured"

# ---- Complete ----
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║          Installation Complete!                      ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Keybind Cheat Sheet:${NC}"
echo -e "  ${CYAN}Super + T${NC}          Open terminal (Kitty)"
echo -e "  ${CYAN}Super + A${NC}          App launcher (Rofi)"
echo -e "  ${CYAN}Super + Shift + T${NC}  Switch theme"
echo -e "  ${CYAN}Super + Shift + W${NC}  Change wallpaper"
echo -e "  ${CYAN}Super + L${NC}          Lock screen"
echo -e "  ${CYAN}Super + X${NC}          Power menu"
echo -e "  ${CYAN}Super + Q${NC}          Close window"
echo -e "  ${CYAN}Shift + F11${NC}        Fullscreen"
echo -e "  ${CYAN}Super + E${NC}          File manager (Thunar)"
echo -e "  ${CYAN}Super + V${NC}          Clipboard history"
echo -e "  ${CYAN}Super + /${NC}          Show all keybinds"
echo ""
echo -e "Active theme: ${GREEN}$DEFAULT_THEME${NC}"
echo -e "Active layout: ${GREEN}${DEFAULT_LAYOUT/layout-/}${NC}"
echo ""
echo -e "${YELLOW}Log out and select Hyprland from your login manager to start.${NC}"
