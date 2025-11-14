# PATH updates
export PATH="$PATH:$HOME/go/bin" # Go bin
export PATH="$PATH:$HOME/.cargo/bin" # Cargo bin
export PATH="$PATH:$HOME/.local/bin" # Local bin

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

# Blocks until given task is completed
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

# Conditionally runs given command if tool exists
ceval() {
  if which $1 &>/dev/null; then
    eval "$($@)"
  fi
}

# Prints $DEVICE_NAME
device() {
  echo $DEVICE_NAME
}

# Runs command then exits
only() {
  $@ && exit
}

# Silently runs command
silent() {
  $@ &>/dev/null
}

start-renamed() {
  zellij ac rename-pane $1
  shift

  "$@"
  local exit_code=$?

  zellij ac undo-rename-pane
  return $exit_code
}

# Perserve auto-completion for passed commands
compdef _precommand only
compdef _precommand silent
compdef _precommand ceval

# === Packages Completions and Setup ===
# Setup zsh auto completion
autoload -Uz compinit && compinit

# Activation
[ -f /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" # homebrew
ceval mise activate zsh

# Auto completion
ceval mise completion zsh
ceval just --completions zsh
ceval gum completion zsh
ceval skate completion zsh
ceval kv completion zsh

# === Exports ===
export DEVICE_NAME="$(hostname)"
export EDITOR="nvim"
export SUDO_EDITOR="/home/linuxbrew/.linuxbrew/bin/nvim"

# === Aliases ===
# Renames
alias cat="bat --plain"

# Short-cuts
alias sk="skate"
alias dc="docker compose"
alias j="just"
alias z="zellij"
alias ff="fastfetch"

# Nvim
alias v="nvim"
alias vz="nvim ~/.zshrc ~/.zsh_local && omz reload"
alias vf='start-renamed nvim nvim $(fzf -m --preview "bat --plain --color=always {}")'

# Bookmarks
alias jd="jump"       # Jump [to] directory
alias bm="bookmark"   # Bookmark directory
alias dm="deletemark" # Delete mark
alias sm="showmarks"  # Show marks

# Python
alias python="python3"
alias pip="pip3"
alias p-env="python -m venv .venv"
alias p-activate="source .venv/bin/activate"
alias p-deactivate="deactivate"

# Utils
alias dotenv='export $(cat .evn | xargs)'
alias scripts='jq ".scripts" package.json'
alias jr='cd $(git rev-parse --show-toplevel)' # Jump to repo root

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
