#!/bin/bash
# ============================================================
# UXNA Void Hyprland — One-Command Installer Bootstrap
# https://github.com/not-Ushna/UXNA-Void-Hyprland
# ============================================================

set -e

REPO_URL="https://github.com/not-Ushna/UXNA-Void-Hyprland.git"
TARGET_DIR="$HOME/Projects/UXNA-Void-Hyprland"

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}==> Bootstrapping UXNA Void Hyprland installation...${NC}"

# Detect package manager
PM=""
if command -v xbps-install &> /dev/null; then
    PM="sudo xbps-install -Sy"
elif command -v pacman &> /dev/null; then
    PM="sudo pacman -Sy --noconfirm"
elif command -v apt-get &> /dev/null; then
    PM="sudo apt-get update && sudo apt-get install -y"
elif command -v dnf &> /dev/null; then
    PM="sudo dnf install -y"
elif command -v zypper &> /dev/null; then
    PM="sudo zypper install -y"
else
    echo -e "${RED}==> Error: Could not detect package manager. Please install git manually.${NC}"
    exit 1
fi

# Ensure git is installed
if ! command -v git &> /dev/null; then
    echo -e "${CYAN}==> git not found. Installing git...${NC}"
    eval "$PM git"
fi

# Clone repository
if [ -d "$TARGET_DIR" ]; then
    echo -e "${CYAN}==> Directory $TARGET_DIR already exists. Pulling latest changes...${NC}"
    cd "$TARGET_DIR"
    git pull origin main || echo -e "${RED}Warning: Failed to pull latest changes. Continuing anyway...${NC}"
else
    echo -e "${CYAN}==> Cloning repository...${NC}"
    mkdir -p "$HOME/Projects"
    git clone "$REPO_URL" "$TARGET_DIR"
fi

# Run the actual installer
echo -e "${GREEN}==> Starting full installer...${NC}"
cd "$TARGET_DIR"
chmod +x scripts/install.sh
exec ./scripts/install.sh "$@"
