#!/bin/bash
# ============================================================
# Midnight-Slate Theme — GTK Settings
# Apply dark GTK theme with monochrome Midnight-Slate accents.
# Also copies the GTK4 libadwaita colors for Nautilus etc.
# ============================================================

# Apply specific GTK and icon themes for Midnight-Slate
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
gsettings set org.gnome.desktop.wm.preferences theme "Midnight-Slate"
gsettings set org.gnome.desktop.interface icon-theme "Tela-circle-black"
gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice"

# Apply other settings
if command -v gsettings >/dev/null 2>&1; then
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

# Configure Thunar GTK3 CSS
cp "$SCRIPT_DIR/gtk4.css" ~/.config/gtk-3.0/gtk.css
cat "$HOME/Projects/UXNA-Hyprland/.config/hypr/scripts/thunar.css" >> ~/.config/gtk-3.0/gtk.css
pkill thunar 2>/dev/null || true
