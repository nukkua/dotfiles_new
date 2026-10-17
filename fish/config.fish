# ~/.config/fish/config.fish

# Sakura color for invalid commands
set -g fish_color_error ffb6c1

# Aliases
set -x LS_COLORS 'di=1;38;5;218:fi=0'
alias vim='nvim'
alias p='pi'
alias kbdtoggle="$HOME/scripts/disable-laptop-keyboard.sh"
alias work='bash ~/scripts/work.sh'

# fish_add_path skips dirs that are already in PATH or missing, and persists nothing on each start
fish_add_path -g $HOME/.cargo/bin $HOME/.local/bin $HOME/go/bin $HOME/.config/composer/vendor/bin $HOME/flutter/flutter/bin /opt/cuda/bin $HOME/RegRipper3.0
set -x CARGO_HOME $HOME/.cargo

# zoxide
zoxide init fish | source
fzf --fish | source
set -x FCEDIT nvim
set -x EDITOR nvim
set -x VISUAL nvim

set -x LLDB_USE_NATIVE_PDB_READER "yes"

abbr --add zbr zig build run
abbr --add zz z ..

if status is-interactive
    stty -ixon
end

set -g fish_cursor_default block
set -g fish_cursor_insert block
set -g fish_cursor_replace_one block
set -g fish_cursor_replace block
set -g fish_cursor_visual block

set -x NVM_DIR "$HOME/.nvm"
function nvm --wraps nvm
    bass source "$NVM_DIR/nvm.sh" --no-use ';' nvm $argv
end

function fish_user_key_bindings
    fish_vi_key_bindings

    bind -M insert \cs accept-autosuggestion
    bind \cg '~/scripts/tmux-sessionizer'
    bind -M insert \cg '~/scripts/tmux-sessionizer'

    bind -M insert \cc 'set fish_bind_mode default; commandline -f repaint'
    bind -M default \cc 'commandline -f cancel-commandline'
end
