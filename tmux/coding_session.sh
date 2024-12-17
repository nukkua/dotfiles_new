#!/bin/bash

SESH="code"
tmux has-session -t $SESH 2>/dev/null

if [ $? != 0 ]; then
    # tmux new-session -d -s $SESH -n "vim-front"
    # tmux send-keys -t $SESH:vim-front "cd ~/precos/front/frontendrrhh-appv1/" C-m
    # tmux send-keys -t $SESH:vim-front "vim ." C-m

    tmux new-session -d -s $SESH -n "vim"
    tmux send-keys -t $SESH:vim "cd ~/grinding_laravel/first-api/" C-m
    tmux send-keys -t $SESH:vim "vim ." C-m

    # tmux new-window -t $SESH -n "server-front"
    # tmux send-keys -t $SESH:server-front "cd ~/precos/front/frontendrrhh-appv1/" C-m
    # tmux send-keys -t $SESH:server-front "npm install && npm run dev" C-m

    tmux new-window -t $SESH -n "server"
    tmux send-keys -t $SESH:server "cd ~/grinding_laravel/first-api/" C-m
    tmux send-keys -t $SESH:server "php artisan test" C-m
    tmux send-keys -t $SESH:server "php artisan serve" C-m


    tmux new-window -t $SESH -n "database"

    tmux new-window -t $SESH -n "term"

    tmux select-window -t $SESH:vim
fi

tmux send-keys -t $SESH:database "cd ~/databases/postgres/first-api/ && sudo systemctl start docker && sudo systemctl start docker.socket && docker ps && docker images" C-m
tmux send-keys -t $SESH:term "cd ~/curls/first-api/" C-m
tmux attach-session -t $SESH

