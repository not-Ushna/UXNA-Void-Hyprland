#!/bin/bash
if [ "$1" = "full" ]; then
    grim - | wl-copy
else
    grim -g "$(slurp -b '#00000099' -c '#ffffff')" - | wl-copy
fi
