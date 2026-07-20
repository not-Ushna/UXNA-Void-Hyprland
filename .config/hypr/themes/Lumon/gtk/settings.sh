#!/bin/bash
# ============================================================
# Lumon Theme — GTK Settings (The Severed Floor)
# Light theme with blue accents — clinical Severance aesthetic.
# ============================================================

# GTK theme
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"
gsettings set org.gnome.desktop.wm.preferences theme "Adwaita"

# Icon and cursor themes
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Light"
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic"
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.gnome.desktop.interface font-name "Inter 11"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
fi

# Apply GTK4 / libadwaita colors (Nautilus, GNOME apps)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
mkdir -p ~/.config/gtk-4.0
cp "$SCRIPT_DIR/gtk4.css" ~/.config/gtk-4.0/gtk.css

# Force Nautilus to restart so it drops the old CSS from memory
pkill nautilus 2>/dev/null || true
