#!/bin/sh

xdotool key --clearmodifiers Alt+n
sleep 0.25

xdotool key --clearmodifiers Alt+e
sleep 0.50

pgrep firefox >/dev/null || firefox &

