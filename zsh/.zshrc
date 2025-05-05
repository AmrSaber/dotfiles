# PATH updates
export PATH="$PATH:$HOME/go/bin" # Go bin
export PATH="$PATH:$HOME/.cargo/bin" # Cargo bin

# === Exports ===
export DEVICE_NAME="$(hostname)"
export EDITOR="nvim"

# === Aliases ===
alias sk="skate"
alias dc="docker compose"

alias nvimz="nvim ~/.zshrc && omz reload"
alias nviml="nvim ~/.zsh_local && omz reload"

# Zellij
alias z="zellij"
alias zd='z a -c $DEVICE_NAME'

# Bookmarks
alias j="jump"
alias bm="bookmark"
alias dm="deletemark"
alias sm="showmarks"

# Python
alias python="python3"
alias pip="pip3"

alias dotenv='export $(cat .evn | xargs)'

# === Zsh Settings ===
# Path to oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="af-magic"

plugins=(fzf zshmarks git golang node bun docker rust timer) 

TIMER_FORMAT='[%d]'
TIMER_PRECISION=2

# Load local config if present
[ -f ~/.zsh_local ] && source ~/.zsh_local

source $ZSH/oh-my-zsh.sh

# === Completions ===
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" # homebrew
eval "$(just --completions zsh)" # just

eval "$(mise activate zsh)" # mise
eval "$(mise completion zsh)" # mise auto completion

