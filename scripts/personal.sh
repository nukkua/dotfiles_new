#!/usr/bin/env bash

SCRIPTS_DIR="$HOME/scripts/personal"

selected=$(
    find "$SCRIPTS_DIR" -maxdepth 1 -type f |
    while IFS= read -r file; do
        basename "$file"
    done |
    fzf \
        --height=100% \
        --layout=reverse \
        --border \
        --prompt=" > " \
        --preview "cat $SCRIPTS_DIR/{}" \
        --preview-window=right:60%
)

if [[ -n "$selected" ]]; then
    clear
    chmod +x "$SCRIPTS_DIR/$selected"
    "$SCRIPTS_DIR/$selected"
fi
