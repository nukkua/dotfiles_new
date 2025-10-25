# ~/.config/fish/config.fish

# Aliases
alias ls='ls --color=auto'
set -x LS_COLORS 'di=1;38;5;218:fi=0'

alias grep='grep --color=auto'
alias recon-ng='/home/leverna/packages/recon-ng/recon-ng'
alias im='nvim'
alias wmqttx='nohup flatpak run com.emqx.MQTTX &> /dev/null &'
alias sortty='python3 /usr/local/bin/sortty-bin/sortty.py'
alias php82='/usr/local/php82/bin/php'
alias fman='commandline -f insert-command; compgen -c | fzf | xargs man'
alias fold='~/scripts/fzf-oldfiles.sh'
alias zen='~/packages/zen/zen'
alias lett='~/lettbar/zig-out/bin/lettbar'
alias sslscan='/home/leverna/packages/sslscan/sslscan'
alias roblox='flatpak run org.vinegarhq.Sober'

alias beef='/home/leverna/packages/beef-master/beef'


# PATHs
set -Ux PATH $PATH /usr/bin $HOME/.cargo/bin $HOME/.local/bin $HOME/flutter/flutter/bin $HOME/.config/composer/vendor/bin $HOME/go/bin /opt/cuda/bin $HOME/RegRipper3.0

# flutter
if test -d "$HOME/flutter/flutter/bin"
    set -x PATH $PATH $HOME/flutter/flutter/bin
end

# cargo env
# cargo (Rust)
set -x CARGO_HOME $HOME/.cargo
set -x PATH $CARGO_HOME/bin $PATH

# CUDA
set -x LD_LIBRARY_PATH /opt/cuda/lib64 $LD_LIBRARY_PATH

set -x ANDROID_HOME "$HOME/Android/Sdk"
set -x ANDROID_SDK_ROOT "$HOME/Android/Sdk"

# bun
set -x BUN_INSTALL "$HOME/.bun"
set -x PATH $BUN_INSTALL/bin $PATH

# zoxide
zoxide init fish | source
# fzf
fzf --fish | source


# editor
set -x FCEDIT nvim
set -x EDITOR nvim
set -x VISUAL nvim

# LLDB
set -x LLDB_USE_NATIVE_PDB_READER "yes"
abbr --add zbr zig build run
abbr --add zz z ..

bind \ch backward-word
bind \cl forward-word

