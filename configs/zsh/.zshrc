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

# Get servers to work with kitty
if [ -n "$SSH_CLIENT" ] && [ "$TERM" = "xterm-kitty" ]; then export TERM="xterm-256color"; fi

# === Aliases ===
alias sk="skate"
alias dc="docker compose"
alias cat="bat --plain"
alias v="nvim"

alias nvimz="nvim ~/.zshrc ~/.zsh_local && omz reload"

# Zellij
alias z="zellij"

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
alias jr='cd $(git rev-parse --show-toplevel)' # Jump to repo root

# === Functions ===
# Start zellij session if not already inside one
zd() {
  # Set quiet variable if '-q' flag is sent
  echo "$@" | grep -Eq '\-.*q' && local quiet=1

  local list=$(z ls 2> /dev/null)
  if [ -z "$list" ] || echo $list | grep -ivq 'current'; then
    z a -c "$DEVICE_NAME"; echo "You are in $(gum style --bold --underline --foreground 032 $DEVICE_NAME)"
  elif [ -z "$quiet" ]; then
    echo $(gum style --foreground 03 "Already inside zellij!") > /dev/stderr
  fi
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

# === Final setup ===
# Load local config if present
[ -f ~/.zsh_local ] && source ~/.zsh_local

# Increase open files limit for brew updates
ulimit -n 4096

# Source oh-my-zsh
source $ZSH/oh-my-zsh.sh
