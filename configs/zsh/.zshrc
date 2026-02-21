# PATH updates
export PATH="$PATH:$HOME/go/bin"               # Go bin
export PATH="$PATH:$HOME/.cargo/bin"           # Cargo bin
export PATH="$PATH:$HOME/.local/bin:$HOME/bin" # Local bin

# === Aliases ===
# Renames
alias cat="bat --plain"

# Short-cuts
alias dc="docker compose"
alias j="just"
alias z="zellij"
alias ff="fastfetch"

# Nvim
alias v="nvim"
alias vr='nvim -c "cd $(git rev-parse --show-toplevel)"'
alias vz="nvim ~/.zshrc ~/.zsh_local ~/.config/starship.toml && omz reload"
alias vf='start-renamed nvim nvim $(fzf -m --preview "bat --plain --color=always {}")'

# Bookmarks
alias jd="jump"       # Jump [to] directory
alias bm="bookmark"   # Bookmark directory
alias dm="deletemark" # Delete mark
alias sm="showmarks"  # Show marks

# Python
alias python="python3"
alias pip="pip3"
alias py-env="python -m venv .venv"
alias py-activate="source .venv/bin/activate"
alias py-deactivate="deactivate"

# Utils
alias dotenv='export $(cat .evn | xargs)'
alias scripts='jq ".scripts" package.json'
alias jr='cd $(git rev-parse --show-toplevel)' # Jump to repo root

# === Exports ===
DEVICE_NAME="$(hostname)"
export DEVICE_NAME

export BREW_PREFIX="/home/linuxbrew/.linuxbrew"

export EDITOR="nvim"
export SUDO_EDITOR="$BREW_PREFIX/bin/nvim"

export NOTES_DIR="$HOME/notes"

# === Functions ===
# Start zellij session if not already inside one
zd() {
  # Set quiet variable if '-q' flag is sent
  echo "$@" | grep -Eq '\-.*q' && local quiet=1

  local list
  list=$(zellij ls 2>/dev/null)

  if [ -z "$list" ] || echo "$list" | grep -ivq 'current'; then
    zellij a -c "$DEVICE_NAME"
  elif [ -z "$quiet" ]; then
    gum style --foreground 03 "Already inside zellij!" >/dev/stderr
  fi
}

# Blocks until given task is completed
wait-for() {
  local task=$1

  if ! pgrep "$task" >/dev/null; then
    gum style --foreground 3 "Task '$task' is not running"
    return 1
  fi

  while pgrep "$task" >/dev/null; do
    sleep 1s
  done
}

# conditional-eval: conditionally evaluates given command if tool exists
ceval() {
  if which "$1" &>/dev/null; then
    eval "$("$@")"
  fi
}

# Runs command then exits
only() {
  "$@" && exit
}

# Silently runs command
silent() {
  "$@" &>/dev/null
}

start-renamed() {
  # In Zsh trap EXIT works with functions returns; similar to trap RETURN in bash
  trap 'zellij ac undo-rename-pane' EXIT

  local title="$1"
  shift

  zellij ac rename-pane "$title"
  "$@"
}

# Remove anything that comes after file end
self-cleanup() {
  file_name="$(readlink -f "$HOME/.zshrc")"

  # Find the last occurrence of "# === End ==="
  last_line=$(grep -n "# === End ===" "$file_name" | tail -1 | cut -d ":" -f 1)

  # Check if there's content after the marker
  if [ "$(wc -l <"$file_name")" -gt "$last_line" ]; then
    gum style --foreground 3 "[.zshrc self-cleanup] Removing appended content:"

    # Print everything after the last occurrence
    tail -n +$((last_line + 1)) "$file_name"

    # Update self to remove everything that was printed
    temp_file=$(mktemp)
    trap 'rm -f $temp_file' EXIT # Always remove file on exit

    head -n "$last_line" "$file_name" >"$temp_file"
    chmod --reference="$file_name" "$temp_file"
    mv "$temp_file" "$file_name"

    echo
    gum style --foreground 3 "[.zshrc self-cleanup] Reloading zsh..."
    omz reload
  fi
}

# Preview all ANSI colours
colours() {
  # Starting from colour 22, colours cluster into groups of 6
  # There are 234 colours, leading to 39 groups of 6
  # If we want each column to contain 5 groups, then we will have 8 columns
  #
  # Each entry takes 10 characters, adding 2 spaces gives 12 characters
  # 12 (column size) * 8 (number of columns) = 96
  # So width tries to be 96 unless it's larger than current window width

  # Output width cannot exceed window width
  WIDTH=96
  ((WIDTH > COLUMNS)) && WIDTH="$COLUMNS"

  (
    for i in {0..21}; do
      tput setaf "$i"
      echo "Colour $i"
    done
  ) | column --output-width "$WIDTH" --use-spaces 2

  echo

  (
    for i in {22..255}; do
      tput setaf "$i"
      echo "Colour $i"
    done
  ) | column --output-width "$WIDTH" --use-spaces 2
}

notes() {
  mkdir -p "$NOTES_DIR"
  (cd "$NOTES_DIR" && nvim main.md)
}

# === Setup ===
# Setup zsh auto completion
autoload -Uz compinit && compinit

# Perserve auto-completion for passed commands
compdef _precommand only
compdef _precommand silent

[ -f $BREW_PREFIX/bin/brew ] && eval "$($BREW_PREFIX/bin/brew shellenv)" # Activate homebrew
ceval mise activate zsh

# Auto completion
ceval mise completion zsh
ceval just --completions zsh
ceval gum completion zsh
ceval kv completion zsh

# Delete function defintion
unfunction ceval

# Load local config if present
[ -f ~/.zsh_local ] && source "$HOME/.zsh_local"

# Increase open files limit for brew updates
ulimit -n 4096

# Make sure starship is installed
which starship &>/dev/null || brew install starship

# === Oh-My-Zsh Setup ===
# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Install oh-my-zsh if not installed
if [ ! -d "$ZSH" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install zshmarks
if [ ! -d "$ZSH/custom/plugins/zshmarks" ]; then
  git clone https://github.com/jocelynmallon/zshmarks.git "$ZSH/custom/plugins/zshmarks"
fi

plugins=(zshmarks docker starship fzf git golang node bun python)

# Source oh-my-zsh
source "$ZSH/oh-my-zsh.sh"

# === Post-Setup ===

# Needs to be here otherwise it is overridden by oh-my-zsh
if which eza &>/dev/null; then
  alias ls="eza --icons=always --group-directories-first"
  alias la="ls -a"
  alias ll="la -lh --git"
  alias l="ll --git-ignore"
  alias lt="l --tree"
  alias llt="ll --tree"
fi

self-cleanup

# === End ===
