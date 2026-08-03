#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Promised Future Theme — GTK Settings                                ║
# ║  Apply the diinki-aero GTK theme for a true Frutiger Aero feel.     ║
# ╚══════════════════════════════════════════════════════════════════════╝

AERO_THEME_SRC="$HOME/Resource/diinki-aero-main/GTKTheme/diinki-aero"
AERO_THEME_DEST="$HOME/.themes/diinki-aero"

# Install the aero GTK theme if not already present
if [ ! -d "$AERO_THEME_DEST" ] && [ -d "$AERO_THEME_SRC" ]; then
    mkdir -p "$HOME/.themes"
    cp -r "$AERO_THEME_SRC" "$AERO_THEME_DEST"
fi

# Apply GTK theme
if [ -d "$AERO_THEME_DEST" ]; then
    gsettings set org.gnome.desktop.interface gtk-theme "diinki-aero"
    gsettings set org.gnome.desktop.wm.preferences theme "diinki-aero"
else
    gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
    gsettings set org.gnome.desktop.wm.preferences theme "Adwaita-dark"
fi

# Install the aero icon theme if not already present
AERO_ICON_SRC="$HOME/Resource/diinki-aero-main/IconTheme/crystal-remix-icon-theme-diinki-version"
AERO_ICON_DEST="$HOME/.icons/crystal-remix-icon-theme-diinki-version"

if [ ! -d "$AERO_ICON_DEST" ] && [ -d "$AERO_ICON_SRC" ]; then
    mkdir -p "$HOME/.icons"
    cp -r "$AERO_ICON_SRC" "$AERO_ICON_DEST"
fi

# Icon theme, cursor, font
if command -v gsettings > /dev/null 2>&1; then
    if [ -d "$AERO_ICON_DEST" ]; then
        gsettings set org.gnome.desktop.interface icon-theme "crystal-remix-icon-theme-diinki-version"
    else
        gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
    fi
    gsettings set org.gnome.desktop.interface cursor-theme "Windows-7-Aero-Cursors_Default"
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.gnome.desktop.interface font-name "JetBrains Mono Nerd Font 11"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
fi

# Apply GTK4 / libadwaita colors (Nautilus, GNOME apps)
# Modern GNOME apps ignore gsettings and require the CSS in ~/.config/gtk-4.0/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
mkdir -p ~/.config/gtk-4.0
cp -r "$AERO_THEME_SRC/gtk-4.0/"* ~/.config/gtk-4.0/

pkill nautilus 2>/dev/null || true
