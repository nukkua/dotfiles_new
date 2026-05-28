# ~/.bashrc

# =========================
# Sakura prompt
# =========================
PS1='\n \[\e[38;5;245m\]\w $\[\e[0m\] '

# =========================
# Aliases
# =========================
alias ls='ls --color=auto'
export LS_COLORS='di=1;38;5;218:fi=0'
stty -ixon


alias grep='grep --color=auto'
alias vim='nvim'

# fman para bash
fman() {
    compgen -c | fzf | xargs -r man
}

# Fish abbr equivalents
alias zbr='zig build run'
alias zz='z ..'

# =========================
# PATHs
# =========================
export PATH="$PATH:/usr/bin"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/flutter/flutter/bin"
export PATH="$PATH:$HOME/.config/composer/vendor/bin"
export PATH="$PATH:$HOME/go/bin"
export PATH="$PATH:/opt/cuda/bin"
export PATH="$PATH:$HOME/RegRipper3.0"

if [ -d "$HOME/flutter/flutter/bin" ]; then
    export PATH="$PATH:$HOME/flutter/flutter/bin"
fi

# cargo / Rust
export CARGO_HOME="$HOME/.cargo"
export PATH="$CARGO_HOME/bin:$PATH"

# CUDA
export LD_LIBRARY_PATH="/opt/cuda/lib64:$LD_LIBRARY_PATH"

# Android
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# uv
export PATH="/home/nukkua/.local/bin:$PATH"

# opencode
export PATH="/home/nukkua/.opencode/bin:$PATH"

# =========================
# zoxide
# =========================

# =========================
# fzf
# =========================
if command -v fzf &> /dev/null; then
    eval "$(fzf --bash)"
fi

# =========================
# editor
# =========================
export FCEDIT="nvim"
export EDITOR="nvim"
export VISUAL="nvim"

# =========================
# LLDB
# =========================
export LLDB_USE_NATIVE_PDB_READER="yes"
PROMPT_COMMAND='printf "\e[?25h"'

if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
fi

