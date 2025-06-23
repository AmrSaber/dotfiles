# PATH updates
export PATH="$PATH:$HOME/go/bin" # Go bin
export PATH="$PATH:$HOME/.cargo/bin" # Cargo bin

# === Packages Completions and Setup ===
# Setup zsh auto completion
autoload -Uz compinit && compinit

# Activation
[ -f /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" # homebrew
eval "$(mise activate zsh)" # mise

# Auto completion
eval "$(just --completions zsh)" # just
eval "$(mise completion zsh)" # mise auto completion
eval "$(gum completion zsh)" # gum
eval "$(skate completion zsh)" # skate

# === Exports ===
export DEVICE_NAME="$(hostname)"
export EDITOR="nvim"

# === Aliases ===
alias sk="skate"
alias dc="docker compose"
alias cat="bat --plain"

alias nvimz="nvim ~/.zshrc ~/.zsh_local && omz reload"

# Zellij
alias z="zellij"
alias zd='z a -c $DEVICE_NAME'
alias zv='z a -c "$DEVICE_NAME-editor"'

# Bookmarks
alias j="jump"
alias bm="bookmark"
alias dm="deletemark"
alias sm="showmarks"

# Python
alias python="python3"
alias pip="pip3"

alias dotenv='export $(cat .evn | xargs)'
alias scripts='jq ".scripts" package.json'

# === Functions ===
# Start zellig main session if no other session is started
start_main_session() {
  z ls &> /dev/null || { zd; echo "You are in $(gum style --bold --underline --foreground 032 $DEVICE_NAME)" }
}

device() {
  echo $DEVICE_NAME
}

# === Zsh Settings ===
# Path to oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="af-magic"

plugins=(fzf zshmarks git golang node bun docker rust timer python) 

# Timer configs
TIMER_FORMAT='[%d]'
TIMER_PRECISION=2

# Python configs
PYTHON_AUTO_VRUN=true
PYTHON_VENV_NAME=".venv"

# === Final setup ===
# Load local config if present
[ -f ~/.zsh_local ] && source ~/.zsh_local

# Source oh-my-zsh
source $ZSH/oh-my-zsh.sh
