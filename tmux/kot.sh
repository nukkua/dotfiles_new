#!/usr/bin/env fish
# Crea (si no existe) y adjunta una sesión tmux con 3 ventanas:
#   1) vim    – abre el directorio de trabajo en Neovim
#   2) compile– compila/ejecuta con Zig
#   3) term   – shell normal en el mismo path

set -l SESH kot
set -l WORKDIR /home/leverna/AndroidStudioProjects/Amanu/

# ¿Ya existe la sesión?
tmux has-session -t $SESH ^/dev/null

if test $status -ne 0
    # Ventana 1: vim
    tmux new-session  -d -s $SESH -n vim
    tmux send-keys    -t $SESH:vim "cd $WORKDIR" C-m
    tmux send-keys    -t $SESH:vim "vi"         C-m

    # Ventana 2: compile
    tmux new-window   -t $SESH -n compile
    tmux send-keys    -t $SESH:compile "cd $WORKDIR"     C-m
    tmux send-keys    -t $SESH:compile "./gradlew clean"   C-m
    tmux send-keys    -t $SESH:compile "./gradlew assembleDebug"   C-m

    # Ventana 3: term
    tmux new-window   -t $SESH -n term
    tmux send-keys    -t $SESH:term "cd $WORKDIR"        C-m

    # Sitúate en la primera ventana
    tmux select-window -t $SESH:vim
end

# Entra/adjunta a la sesión
tmux attach-session -t $SESH
