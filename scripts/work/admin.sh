#!/usr/bin/env fish
# Crea (si no existe) y adjunta una sesión tmux con 3 ventanas:
#   1) vim    – abre el directorio de trabajo en Neovim
#   2) compile– compila/ejecuta con Zig
#   3) term   – shell normal en el mismo path

set -l SESH admin
set -l WORKDIR /home/nukkua/working/klubo-admin-v2/

tmux has-session -t $SESH ^/dev/null

if test $status -ne 0
    # Ventana 1: vim
    tmux new-session  -d -s $SESH -n nvim
    tmux send-keys    -t $SESH:nvim "cd $WORKDIR" C-m
    tmux send-keys    -t $SESH:nvim "vim"         C-m

    # Ventana 2: server
    tmux new-window   -t $SESH -n sv
    tmux send-keys    -t $SESH:sv "cd $WORKDIR"     C-m
    tmux send-keys    -t $SESH:sv "clear"     C-m
    tmux send-keys    -t $SESH:sv "npm run dev:dev"     C-m

    # Ventana 3: git
    tmux new-window   -t $SESH -n lazygit
    tmux send-keys    -t $SESH:lazygit "cd $WORKDIR"        C-m
    tmux send-keys    -t $SESH:lazygit "lazygit"        C-m

    # Ventana 4: opencode
    tmux new-window   -t $SESH -n agent
    tmux send-keys    -t $SESH:agent "cd $WORKDIR"        C-m
    tmux send-keys    -t $SESH:agent "clear"        C-m

    # Sitúate en la primera ventana
    tmux select-window -t $SESH:nvim
end

# Entra/adjunta a la sesión
tmux attach-session -t $SESH
