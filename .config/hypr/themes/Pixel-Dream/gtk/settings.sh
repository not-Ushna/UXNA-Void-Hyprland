#!/usr/bin/env bash

GTK_THEME="Pixel-Dream"
ICON_THEME="pixel-dream"
CURSOR_THEME="pixel-dream-cursor"
FONT="Monocraft Nerd Font Book 10"

gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
gsettings set org.gnome.desktop.interface font-name "$FONT"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

# Apply for hyprcursor if configured
hyprctl setcursor "$CURSOR_THEME" 20
