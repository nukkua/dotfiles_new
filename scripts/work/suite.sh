#!/usr/bin/env bash
# Crea (si no existe) y adjunta una sesión tmux con 3 ventanas:
#   1) vim    – abre el directorio de trabajo en Neovim
#   2) compile– compila/ejecuta con Zig
#   3) term   – shell normal en el mismo path

SESH="suite"
WORKDIR="/home/nukkua/working/klubo-suite/"

if ! tmux has-session -t "=$SESH" 2>/dev/null; then
    tmux new-session  -d -s "$SESH" -n vim
    tmux send-keys    -t "$SESH:vim" "cd $WORKDIR" C-m
    tmux send-keys    -t "$SESH:vim" "vim"         C-m

    tmux new-window   -t "$SESH" -n sv
    tmux send-keys    -t "$SESH:sv" "cd $WORKDIR"     C-m
    tmux send-keys    -t "$SESH:sv" "npm run dev:dev -- -p 9003"     C-m
    tmux send-keys    -t "$SESH:sv" "clear"     C-m

    tmux new-window   -t "$SESH" -n pi
    tmux send-keys    -t "$SESH:pi" "cd $WORKDIR"     C-m
    tmux send-keys    -t "$SESH:pi" "clear"     C-m

    tmux select-window -t "$SESH:vim"
fi

if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$SESH"
else
    tmux attach-session -t "$SESH"
fi
