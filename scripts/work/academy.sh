#!/usr/bin/env fish
set -l SESH kluboacademy
set -l WORKDIR /home/nukkua/working/klubo-academy/

tmux has-session -t $SESH ^/dev/null

if test $status -ne 0
    tmux new-session  -d -s $SESH -n nvim
    tmux send-keys    -t $SESH:nvim "cd $WORKDIR" C-m
    tmux send-keys    -t $SESH:nvim "vim"         C-m

    tmux new-window   -t $SESH -n sv
    tmux send-keys    -t $SESH:sv "cd $WORKDIR"     C-m
    tmux send-keys    -t $SESH:sv "clear"     C-m
    tmux send-keys    -t $SESH:sv "npm run dev:dev"     C-m

    tmux new-window   -t $SESH -n lazygit
    tmux send-keys    -t $SESH:lazygit "cd $WORKDIR"     C-m
    tmux send-keys    -t $SESH:lazygit "clear"     C-m
    tmux send-keys    -t $SESH:lazygit "lazygit"     C-m

    tmux new-window   -t $SESH -n agent
    tmux send-keys    -t $SESH:agent "cd $WORKDIR"     C-m
    tmux send-keys    -t $SESH:agent "clear"     C-m

    tmux select-window -t $SESH:vim
end

tmux attach-session -t $SESH
