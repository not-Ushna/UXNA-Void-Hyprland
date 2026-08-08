#!/bin/bash
# Apply specific GTK and icon themes for Evangelion
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
gsettings set org.gnome.desktop.interface icon-theme "Vimix-ruby-dark"
gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic"
gsettings set org.gnome.desktop.interface font-name "Inter 11"
gsettings set org.gnome.desktop.wm.preferences theme "Catppuccin-Mocha-Standard-Purple-Dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
mkdir -p ~/.config/gtk-4.0
cp "$SCRIPT_DIR/gtk4.css" ~/.config/gtk-4.0/gtk.css

pkill nautilus 2>/dev/null || true

# Sync GTK3 settings.ini for apps that ignore gsettings on Wayland
mkdir -p ~/.config/gtk-3.0
cat <<EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")
gtk-icon-theme-name=$(gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")
gtk-cursor-theme-name=$(gsettings get org.gnome.desktop.interface cursor-theme | tr -d "'")
gtk-font-name=$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")
gtk-application-prefer-dark-theme=$([ "$(gsettings get org.gnome.desktop.interface color-scheme | tr -d "'")" == "prefer-dark" ] && echo 1 || echo 0)
EOF
