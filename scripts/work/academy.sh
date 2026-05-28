#!/usr/bin/env bash

SESH="kluboacademy"
WORKDIR="/home/nukkua/working/klubo-academy/"

if ! tmux has-session -t "=$SESH" 2>/dev/null; then
    tmux new-session  -d -s "$SESH" -n nvim
    tmux send-keys    -t "$SESH:nvim" "cd $WORKDIR" C-m
    tmux send-keys    -t "$SESH:nvim" "vim"         C-m

    tmux new-window   -t "$SESH" -n sv
    tmux send-keys    -t "$SESH:sv" "cd $WORKDIR"     C-m
    tmux send-keys    -t "$SESH:sv" "clear"     C-m
    tmux send-keys    -t "$SESH:sv" "npm run dev:dev"     C-m

    tmux new-window   -t "$SESH" -n lazygit
    tmux send-keys    -t "$SESH:lazygit" "cd $WORKDIR"     C-m
    tmux send-keys    -t "$SESH:lazygit" "clear"     C-m
    tmux send-keys    -t "$SESH:lazygit" "lazygit"     C-m

    tmux new-window   -t "$SESH" -n pancakes
    tmux send-keys    -t "$SESH:pancakes" "cd $WORKDIR"     C-m
    tmux send-keys    -t "$SESH:pancakes" "clear"     C-m

    tmux select-window -t "$SESH:nvim"
fi

if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$SESH"
else
    tmux attach-session -t "$SESH"
fi
