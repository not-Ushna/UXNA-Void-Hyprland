#!/bin/bash
set -e

echo "Starting GRUB one-time setup..."

# 1. Create the dedicated theme folder
mkdir -p /boot/grub/themes/hyprtheme

# 2. Tell GRUB to use this folder permanently (remove any old theme lines first!)
sed -i '/^GRUB_THEME=/d' /etc/default/grub
echo 'GRUB_THEME="/boot/grub/themes/hyprtheme/theme.txt"' >> /etc/default/grub

# 3. Build the GRUB config once
echo "Running grub-mkconfig... this may take a few seconds."
grub-mkconfig -o /boot/grub/grub.cfg

# 4. Change ownership of the theme folder so uxna can overwrite it without a password!
chown -R uxna:uxna /boot/grub/themes/hyprtheme

echo "=========================================================="
echo "✨ Setup Complete! ✨"
echo "Your theme switcher will now automatically update the GRUB"
echo "theme instantly in the background without needing a password!"
echo "=========================================================="
