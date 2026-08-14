#!/bin/bash
# ============================================================
# UXNA Universal Hyprland — One-Command Installer Bootstrap
# https://github.com/not-Ushna/UXNA-Hyprland
# ============================================================

set -e

REPO_URL="https://github.com/not-Ushna/UXNA-Hyprland.git"
TARGET_DIR="$HOME/Projects/UXNA-Hyprland"

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}==> Bootstrapping UXNA Universal Hyprland installation...${NC}"

# Ensure git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}==> Error: git is not installed.${NC}"
    echo -e "${CYAN}==> Please install git using your system's package manager and run this script again.${NC}"
    exit 1
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
