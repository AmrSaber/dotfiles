# PATH updates
export PATH="$PATH:$HOME/go/bin" # Go bin
export PATH="$PATH:$HOME/.cargo/bin" # Cargo bin

# === Packages Completions and Setup ===
# Setup zsh auto completion
autoload -Uz compinit && compinit

# Activation
[ -f /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" # homebrew
which mise &> /dev/null && eval "$(mise activate zsh)" # mise

# Auto completion
eval "$(just --completions zsh)" # just
which mise &> /dev/null && eval "$(mise completion zsh)" # mise auto completion
eval "$(gum completion zsh)" # gum
eval "$(skate completion zsh)" # skate
eval "$(zoxide init zsh)" # zoxide

# === Exports ===
export DEVICE_NAME="$(hostname)"
export EDITOR="nvim"

# === Aliases ===
alias sk="skate"
alias dc="docker compose"
alias cat="bat --plain"
alias v="nvim"
alias j="just"

alias nvimz="nvim ~/.zshrc ~/.zsh_local && omz reload"

# Bookmarks
alias jd="jump"       # Jump directory
alias bm="bookmark"   # Bookmark directory
alias dm="deletemark" # Delete mark
alias sm="showmarks"  # Show marks

# Python
alias python="python3"
alias pip="pip3"
alias p-env="python -m venv .venv"
alias p-activate="source .venv/bin/activate"
alias p-deactivate="deactivate"

alias dotenv='export $(cat .evn | xargs)'
alias scripts='jq ".scripts" package.json'
alias jr='cd $(git rev-parse --show-toplevel)' # Jump to repo root

# === Functions ===
# Start zellij session if not already inside one
zd() {
  # Set quiet variable if '-q' flag is sent
  echo "$@" | grep -Eq '\-.*q' && local quiet=1

  local list=$(zellij ls 2> /dev/null)
  if [ -z "$list" ] || echo $list | grep -ivq 'current'; then
    zellij a -c "$DEVICE_NAME"; echo "You are in $(gum style --bold --underline --foreground 032 $DEVICE_NAME)"
  elif [ -z "$quiet" ]; then
    echo $(gum style --foreground 03 "Already inside zellij!") > /dev/stderr
  fi
}

device() {
  echo $DEVICE_NAME
}

wait-for() {
  local task=$1

  if ! pgrep $task > /dev/null; then
    gum style --foreground 3 "Task '$task' is not running"
    return 1
  fi

  while pgrep $task > /dev/null; do
    sleep 1s;
  done
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

# Needs to be here lest it is overridden by oh-my-zsh
if which eza &>/dev/null; then
  alias ls="eza --icons=always --group-directories-first"
  alias la="ls -a"
  alias ll="la -lh --git"
  alias l="ll --git-ignore"
  alias lt="l --tree"
  alias llt="ll --tree"
fi

which zoxide &> /dev/null && alias cd="z"
