#!/usr/bin/env bash

SESH="reservations"
WORKDIR="/home/nukkua/working/klubo-reservations/"

if ! tmux has-session -t "=$SESH" 2>/dev/null; then
    tmux new-session  -d -s "$SESH" -n vim
    tmux send-keys    -t "$SESH:vim" "cd $WORKDIR" C-m
    tmux send-keys    -t "$SESH:vim" "vim"         C-m

    tmux new-window   -t "$SESH" -n sv
    tmux send-keys    -t "$SESH:sv" "cd $WORKDIR"     C-m
    tmux send-keys    -t "$SESH:sv" "clear"           C-m
    tmux send-keys    -t "$SESH:sv" "npm run dev -- -p 9001"     C-m

    tmux new-window   -t "$SESH" -n pi
    tmux send-keys    -t "$SESH:pi" "cd $WORKDIR"     C-m
    tmux send-keys    -t "$SESH:pi" "clear"     C-m
    tmux send-keys    -t "$SESH:pi" "pi"     C-m

    tmux select-window -t "$SESH:vim"
fi

if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$SESH" \; set -g status off
else
    tmux attach-session -t "$SESH" \; set -g status off
fi
