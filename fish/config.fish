# ~/.config/fish/config.fish

# Sakura color for invalid commands
set -g fish_color_error ffb6c1

# Aliases
set -x LS_COLORS 'di=1;38;5;218:fi=0'
alias vim='nvim'

set -Ux PATH $PATH /usr/bin $HOME/.cargo/bin $HOME/.local/bin $HOME/flutter/flutter/bin $HOME/.config/composer/vendor/bin $HOME/go/bin /opt/cuda/bin $HOME/RegRipper3.0

if test -d "$HOME/flutter/flutter/bin"
    set -x PATH $PATH $HOME/flutter/flutter/bin
end

# cargo (Rust)
set -x CARGO_HOME $HOME/.cargo
set -x PATH $CARGO_HOME/bin $PATH

# zoxide
zoxide init fish | source
fzf --fish | source
set -x FCEDIT nvim
set -x EDITOR nvim
set -x VISUAL nvim

set -x LLDB_USE_NATIVE_PDB_READER "yes"
abbr --add zbr zig build run
abbr --add zz z ..

fish_add_path "/home/nukkua/.local/bin"
stty -ixon

set -g fish_cursor_default block
set -g fish_cursor_insert block
set -g fish_cursor_replace_one block
set -g fish_cursor_replace block
set -g fish_cursor_visual block

function fish_user_key_bindings
    fish_vi_key_bindings

    bind -M insert \cs accept-autosuggestion
    bind \cg '~/scripts/personal/sx'

    bind -M insert \cc 'set fish_bind_mode default; commandline -f repaint'
    bind -M default \cc 'commandline -f cancel-commandline'
end
