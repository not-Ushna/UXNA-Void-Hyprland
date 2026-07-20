#!/bin/bash

notify-send -t 2000 "Scanning Wi-Fi..." "Fetching available networks..."

# Fetch list of networks and format it for Rofi
# Output from nmcli: SSID:WPA2:80
list=$(nmcli -t -f SSID,SECURITY,SIGNAL device wifi list | grep -v "^:")

# Display formatted list in Rofi
chosen=$(echo "$list" | awk -F':' '{printf "%s | %s | %s%%\n", $1, $2, $3}' | rofi -dmenu -i -p "Wi-Fi" -theme ~/.config/hypr/themes/current/rofi/launcher.rasi)

# Exit if user hits Esc
if [[ -z "$chosen" ]]; then
    exit 0
fi

# Extract the exact SSID from the chosen string
ssid=$(echo "$chosen" | awk -F' \\| ' '{print $1}')

# Check if the connection is already known
if nmcli -t connection show | grep -q "^${ssid}:"; then
    # Connect directly
    notify-send -t 2000 "Connecting..." "Connecting to known network: $ssid"
    if nmcli connection up id "$ssid" | grep -q "successfully"; then
        notify-send "Connected" "Successfully connected to $ssid"
    else
        notify-send -u critical "Connection Failed" "Failed to connect to $ssid"
    fi
else
    # Prompt for password in Rofi
    pass=$(rofi -dmenu -p "Password for $ssid" -password -theme ~/.config/hypr/themes/current/rofi/launcher.rasi)
    if [[ -n "$pass" ]]; then
        notify-send -t 2000 "Connecting..." "Connecting to new network: $ssid"
        if nmcli device wifi connect "$ssid" password "$pass" | grep -q "successfully"; then
            notify-send "Connected" "Successfully connected to $ssid"
        else
            notify-send -u critical "Connection Failed" "Failed to connect to $ssid. Check password."
        fi
    fi
fi
