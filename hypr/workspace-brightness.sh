#!/usr/bin/env bash

previous_workspace=''
normal_brightness=''

while sleep 0.25; do
    workspace=$(hyprctl activeworkspace -j 2>/dev/null | sed -n 's/.*"id":\([0-9]*\).*/\1/p')
    [ -n "$workspace" ] || continue
    [ "$workspace" = "$previous_workspace" ] && continue

    if [ "$workspace" = 1 ]; then
        normal_brightness=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
        [ -n "$normal_brightness" ] && brightnessctl set "$((normal_brightness > 15 ? normal_brightness - 15 : 0))%" >/dev/null
    elif [ "$previous_workspace" = 1 ] && [ -n "$normal_brightness" ]; then
        brightnessctl set "$normal_brightness%" >/dev/null
        normal_brightness=''
    fi

    previous_workspace="$workspace"
done
