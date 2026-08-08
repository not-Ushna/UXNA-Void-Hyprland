#!/bin/bash
# ============================================================
# Jade Theme — GTK Settings
# Apply dark GTK theme with jade/green Everforest accents.
# Also copies the GTK4 libadwaita colors for Nautilus etc.
# Apply dark GTK theme with jade/green accents.
# ============================================================

# GTK theme (use Adwaita-dark as fallback; user can install Everforest-Dark)
if [ -d "$HOME/.themes/Everforest-Dark" ] || [ -d "/usr/share/themes/Everforest-Dark" ]; then
    gsettings set org.gnome.desktop.interface gtk-theme "Everforest-Dark"
    gsettings set org.gnome.desktop.wm.preferences theme "Everforest-Dark"
else
    gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
    gsettings set org.gnome.desktop.wm.preferences theme "Adwaita-dark"
fi

# Icon theme
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface icon-theme "Tela-circle-509475-dark"
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic"
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.gnome.desktop.interface font-name "JetBrains Mono Nerd Font 11"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
fi

# Apply GTK4 / libadwaita colors (Nautilus, GNOME apps)
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
