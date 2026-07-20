#!/bin/bash

notified_20=0
notified_10=0

while true; do
  if [[ -d "/sys/class/power_supply/BAT0" ]]; then
    status=$(cat /sys/class/power_supply/BAT0/status)
    capacity=$(cat /sys/class/power_supply/BAT0/capacity)

    if [[ "$status" == "Discharging" ]]; then
      if [[ $capacity -le 5 ]]; then
        dunstify -u critical "Battery Critical ($capacity%)" "System will suspend in 10 seconds to prevent data loss!"
        sleep 10
        # Check again to ensure it wasn't plugged in during the 10s warning
        if [[ "$(cat /sys/class/power_supply/BAT0/status)" == "Discharging" ]]; then
          ~/.config/hypr/scripts/lock.sh &
          sleep 1
          zzz
        fi
      elif [[ $capacity -le 10 && $notified_10 -eq 0 ]]; then
        dunstify -u critical "Battery Low ($capacity%)" "Please connect your charger immediately."
        notified_10=1
      elif [[ $capacity -le 20 && $capacity -gt 10 && $notified_20 -eq 0 ]]; then
        dunstify -u normal "Battery Warning ($capacity%)" "Battery is getting low."
        notified_20=1
      fi
    else
      # Reset states if charging
      notified_20=0
      notified_10=0
    fi
  fi
  sleep 60
done
