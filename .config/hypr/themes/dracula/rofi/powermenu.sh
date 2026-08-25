#!/usr/bin/env bash
shutdown=""
reboot=""
sleep=""
logout=""
lock=""

options="$lock\n$sleep\n$logout\n$reboot\n$shutdown"
uptime_icon=""
chosen=$(echo -e "$options" | rofi -dmenu -i -p "$uptime_icon  Uptime: $(uptime -p | sed 's/up //')" -theme "/home/uxna/Projects/UXNA-Hyprland/.config/hypr/themes/dracula/rofi/powermenu.rasi")

confirm_action() {
  echo -e "Yes\nNo" | rofi -dmenu -i -p "Are you sure?" -theme "/home/uxna/Projects/UXNA-Hyprland/.config/hypr/themes/dracula/rofi/powermenu.rasi"
}

case "$chosen" in
  "$shutdown") [[ "$(confirm_action)" == "Yes" ]] && systemctl poweroff ;;
  "$reboot") [[ "$(confirm_action)" == "Yes" ]] && systemctl reboot ;;
  "$sleep") systemctl suspend ;;
  "$logout") [[ "$(confirm_action)" == "Yes" ]] && hyprctl dispatch exit ;;
  "$lock") hyprlock ;;
esac
