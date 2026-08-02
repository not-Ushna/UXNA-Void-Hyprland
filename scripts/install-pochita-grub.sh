#!/bin/bash
set -e

# Path to the synced custom theme in this repository
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYNCED_THEME="$REPO_ROOT/boot/grub/themes/Pochita_Pochita"
THEMES_DIR="/boot/grub/themes"
THEME_PATH="$THEMES_DIR/Pochita_Pochita/theme.txt"
GRUB_DEFAULT="/etc/default/grub"

if [ ! -d "$SYNCED_THEME" ]; then
    echo "Error: Custom theme not found at $SYNCED_THEME"
    echo "Make sure you have cloned the repo completely."
    exit 1
fi

# 1. Create themes directory and copy custom theme
mkdir -p "$THEMES_DIR"
cp -r "$SYNCED_THEME" "$THEMES_DIR/"
echo "✓ Pochita_Pochita theme copied to $THEMES_DIR/"

# 2. Remove any existing GRUB_THEME lines
sed -i '/^#*\s*GRUB_THEME=/d' "$GRUB_DEFAULT"

# 3. Insert the new GRUB_THEME line
echo "GRUB_THEME=\"$THEME_PATH\"" >> "$GRUB_DEFAULT"
echo "✓ GRUB_THEME set to $THEME_PATH"

# 4. Set correct gfxmode if not already set
if ! grep -q "^GRUB_GFXMODE=" "$GRUB_DEFAULT"; then
    echo 'GRUB_GFXMODE=1920x1080x32,auto' >> "$GRUB_DEFAULT"
fi
sed -i 's/^#GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080x32,auto/' "$GRUB_DEFAULT"
echo "✓ GRUB_GFXMODE set"

# 5. Regenerate grub.cfg
grub-mkconfig -o /boot/grub/grub.cfg
echo "✓ grub.cfg regenerated — Pochita_Pochita will appear on next boot!"
