#!/bin/bash
gsettings set org.gnome.desktop.interface gtk-theme "Catppuccin-Mocha-Standard-Purple-Dark"
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic"
gsettings set org.gnome.desktop.interface font-name "Inter 11"
gsettings set org.gnome.desktop.wm.preferences theme "Catppuccin-Mocha-Standard-Purple-Dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
mkdir -p ~/.config/gtk-4.0
cp "$SCRIPT_DIR/gtk4.css" ~/.config/gtk-4.0/gtk.css

pkill nautilus 2>/dev/null || true
