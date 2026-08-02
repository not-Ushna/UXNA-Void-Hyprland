#!/bin/bash
set -e

ARCHIVE="$HOME/Resource/HyDE-master/Source/arcs/Grub_Pochita.tar.gz"
THEMES_DIR="/boot/grub/themes"
THEME_PATH="$THEMES_DIR/Pochita/theme.txt"
GRUB_DEFAULT="/etc/default/grub"

# 1. Create themes directory and extract
mkdir -p "$THEMES_DIR"
tar -xzf "$ARCHIVE" -C "$THEMES_DIR"
echo "✓ Pochita theme extracted to $THEMES_DIR/Pochita/"

# 2. Remove any existing GRUB_THEME lines (handles duplicates/commented variants)
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
echo "✓ grub.cfg regenerated — Pochita will appear on next boot!"
