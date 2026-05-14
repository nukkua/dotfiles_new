#!/usr/bin/env fish

set -l search_dirs \
    ~/Downloads \
    ~/books

set -l valid_dirs

for dir in $search_dirs
    if test -d "$dir"
        set valid_dirs $valid_dirs "$dir"
    end
end

if test (count $valid_dirs) -eq 0
    echo "No hay directorios válidos."
    exit 1
end

set -l selected_pdf (
    find $valid_dirs -type f -iname "*.pdf" 2>/dev/null \
    | sort \
    | fzf \
        --height=50% \
        --layout=reverse \
        --border \
        --prompt=" > "
)

if test -n "$selected_pdf"
    nohup setsid sh -c 'zathura "$1" >/dev/null 2>&1 &' sh "$selected_pdf"
end
