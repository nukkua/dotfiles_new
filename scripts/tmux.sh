#!/usr/bin/env bash

selected=$(
    tmux list-sessions -F '#{session_name}' 2>/dev/null |
    fzf \
        --height=100% \
        --layout=reverse \
        --border \
        --prompt=" > "
)

if [[ -n "$selected" ]]; then
    if [[ -n "${TMUX:-}" ]]; then
        tmux switch-client -t "$selected"
    else
        tmux attach-session -t "$selected"
    fi
fi
