#!/usr/bin/env bash

search_dirs=(
    "$HOME/Downloads"
    "$HOME/books"
)

valid_dirs=()

for dir in "${search_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        valid_dirs+=("$dir")
    fi
done

if [[ ${#valid_dirs[@]} -eq 0 ]]; then
    echo "No hay directorios válidos."
    exit 1
fi

selected_pdf=$(
    find "${valid_dirs[@]}" -type f -iname "*.pdf" 2>/dev/null \
    | sort \
    | fzf \
        --height=50% \
        --layout=reverse \
        --border \
        --prompt=" > "
)

if [[ -n "$selected_pdf" ]]; then
    nohup setsid sh -c 'zathura "$1" >/dev/null 2>&1 &' sh "$selected_pdf"
fi
