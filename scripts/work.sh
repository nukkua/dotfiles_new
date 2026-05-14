#!/usr/bin/env fish

set SCRIPTS_DIR ~/scripts/work

set selected (
    find $SCRIPTS_DIR -maxdepth 1 -type f |
    while read -l file
        echo (basename $file)
    end |
    fzf \
        --height=100% \
        --layout=reverse \
        --border \
        --prompt=" > " \
        --preview "cat $SCRIPTS_DIR/{}" \
        --preview-window=right:60%
)

if test -n "$selected"
    clear
    chmod +x "$SCRIPTS_DIR/$selected"
    "$SCRIPTS_DIR/$selected"
end
