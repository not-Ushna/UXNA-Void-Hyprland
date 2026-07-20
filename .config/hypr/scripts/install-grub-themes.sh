#!/bin/bash

echo "Creating Jade GRUB Theme..."
mkdir -p /boot/grub/themes/Jade
cp -r /boot/grub/themes/Void/* /boot/grub/themes/Jade/
cp /home/uxna/Projects/UXNA-Void-Hyprland/.config/hypr/themes/Jade/wallpapers/main.jpg /boot/grub/themes/Jade/background.jpg
sed -i 's/desktop-image: "Void.png"/desktop-image: "background.jpg"/g' /boot/grub/themes/Jade/theme.txt
sed -i 's/color = "#D1D3D2"/color = "#89b482"/g' /boot/grub/themes/Jade/theme.txt
sed -i 's/item_color = "#D1D3D2"/item_color = "#89b482"/g' /boot/grub/themes/Jade/theme.txt
sed -i 's/selected_item_color = "#D1D3D2"/selected_item_color = "#A7C080"/g' /boot/grub/themes/Jade/theme.txt

echo "Creating Lumon GRUB Theme..."
mkdir -p /boot/grub/themes/Lumon
cp -r /boot/grub/themes/Void/* /boot/grub/themes/Lumon/
cp /home/uxna/Projects/UXNA-Void-Hyprland/.config/hypr/themes/Lumon/wallpapers/main.jpg /boot/grub/themes/Lumon/background.jpg
sed -i 's/desktop-image: "Void.png"/desktop-image: "background.jpg"/g' /boot/grub/themes/Lumon/theme.txt
sed -i 's/color = "#D1D3D2"/color = "#89b4fa"/g' /boot/grub/themes/Lumon/theme.txt
sed -i 's/item_color = "#D1D3D2"/item_color = "#89b4fa"/g' /boot/grub/themes/Lumon/theme.txt
sed -i 's/selected_item_color = "#D1D3D2"/selected_item_color = "#89b4fa"/g' /boot/grub/themes/Lumon/theme.txt

echo "=========================================="
echo "✨ GRUB Themes Installed Successfully! ✨"
echo "=========================================="
echo "To switch your bootloader to JADE, run:"
echo "sudo sed -i 's|GRUB_THEME=.*|GRUB_THEME=\"/boot/grub/themes/Jade/theme.txt\"|g' /etc/default/grub && sudo update-grub"
echo ""
echo "To switch your bootloader to LUMON, run:"
echo "sudo sed -i 's|GRUB_THEME=.*|GRUB_THEME=\"/boot/grub/themes/Lumon/theme.txt\"|g' /etc/default/grub && sudo update-grub"
