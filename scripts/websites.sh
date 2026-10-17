#!/usr/bin/env bash
set -euo pipefail

SITES_DIR="$HOME/scripts/websites"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/scripts"
USAGE_FILE="$CACHE_DIR/websites.usage"

if [[ ! -d "$SITES_DIR" ]]; then
    echo "Missing directory: $SITES_DIR" >&2
    exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
    echo "Missing dependency: fzf" >&2
    exit 1
fi

mkdir -p -- "$CACHE_DIR"
touch -- "$USAGE_FILE"

selected=$(
    find "$SITES_DIR" -maxdepth 1 -type f -printf '%f\n' |
    awk -F '\t' 'FILENAME == ARGV[1] { used[$2]=$1; next } { print (used[$0] + 0) "\t" $0 }' "$USAGE_FILE" - |
    sort -t $'\t' -k1,1nr -k2,2 |
    cut -f2- |
    fzf \
        --height=100% \
        --layout=reverse \
        --border \
        --prompt="web > " \
        --preview "bash -c 'cat -- \"\$1\"' _ '$SITES_DIR/{}'" \
        --preview-window=right:60%
)

[[ -n "${selected:-}" ]] || exit 0

script="$SITES_DIR/$selected"

if [[ ! -f "$script" ]]; then
    echo "Missing script: $script" >&2
    exit 1
fi

tmp_usage=$(mktemp)
awk -F '\t' -v OFS='\t' -v file="$selected" '
    $2 == file { $1++; seen=1 }
    { print }
    END { if (!seen) print 1, file }
' "$USAGE_FILE" > "$tmp_usage"
mv -- "$tmp_usage" "$USAGE_FILE"

clear
chmod +x -- "$script"
"$script"

if [[ -t 0 ]]; then
    read -n 1 -s -r -p "Press any key to close..."
fi
