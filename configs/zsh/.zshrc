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
alias jp="jumper"
alias jd="jump" # Jump [to] directory

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
alias open='xdg-open'

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
  [[ " $* " == *" -q "* ]] && local quiet=1

  local list
  list=$(zellij ls 2>/dev/null)

  if [ -z "$list" ] || echo "$list" | grep -ivq 'current'; then
    zellij a -c "$DEVICE_NAME"
  elif [ -z "$quiet" ]; then
    coloured 3 "Already inside zellij!" >/dev/stderr
  fi
}

# Blocks until given task is completed
wait-for() {
  local task=$1

  if ! pgrep "$task" >/dev/null; then
    coloured 3 "Task '$task' is not running"
    return 1
  fi

  while pgrep "$task" >/dev/null; do
    sleep 1s
  done
}

# Runs command then exits
only() {
  "$@" && exit
}

# Silently runs command
silent() {
  "$@" &>/dev/null
}

# Fails if given command does not exist
exists() {
  command -v "$1" &>/dev/null
  return "$?"
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
    coloured 3 "[.zshrc self-cleanup] Removing appended content:"

    # Print everything after the last occurrence
    tail -n +$((last_line + 1)) "$file_name"

    # Update self to remove everything that was printed
    temp_file=$(mktemp)
    trap 'rm -f $temp_file' EXIT # Always remove file on exit

    head -n "$last_line" "$file_name" >"$temp_file"
    chmod --reference="$file_name" "$temp_file"
    mv "$temp_file" "$file_name"

    echo
    coloured 3 "[.zshrc self-cleanup] Reloading zsh..."
    omz reload
  fi
}

# Preview all ANSI colours
# Use -a or --all to display all colours
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

  # Clear colors before exit
  trap 'tput sgr0' EXIT

  (
    for i in {0..21}; do
      tput setaf "$i"
      echo "Colour $i"
    done
  ) | column --output-width "$WIDTH" --use-spaces 2

  # Stop here if none of ('-a', '--all') flags are set
  [[ " $* " != *" -a "* && " $* " != *" --all "* ]] && return

  echo

  (
    for i in {22..255}; do
      tput setaf "$i"
      echo "Colour $i"
    done
  ) | column --output-width "$WIDTH" --use-spaces 2
}

# Print text in give colour
coloured() {
  if [[ "$#" < "2" ]]; then
    echo "Usage: coloured <colour> <text...>" >&2
    return 1
  fi

  colour="$1"
  shift
  text="$@"

  tput setaf "$colour"
  echo "$text"
  tput sgr0
}
alias clr='coloured'

notes() {
  mkdir -p "$NOTES_DIR"
  (cd "$NOTES_DIR" && nvim main.md)
}

alarm() {
  for i in {0..2}; do
    printf '\a'
    sleep .15s
  done
}

# Stop watch
sw() {
  local FILE="${XDG_STATE_HOME:-$HOME/.local/state}/stopwatch"
  mkdir -p "$(dirname "$FILE")"

  case "$1" in
  start)
    date +%s >"$FILE"
    echo "Started at $(date)"
    ;;
  stop)
    if [[ ! -f "$FILE" ]]; then
      return
    fi

    start=$(cat "$FILE")
    now=$(date +%s)
    diff=$((now - start))
    printf "Elapsed: %02d:%02d:%02d\n" $((diff / 3600)) $(((diff % 3600) / 60)) $((diff % 60))

    rm -f "$FILE"
    ;;
  "" | elapsed)
    if [[ ! -f "$FILE" ]]; then
      echo "No stopwatch running. Use: sw start"
      return 1
    fi

    start=$(cat "$FILE")
    now=$(date +%s)
    diff=$((now - start))
    printf "Elapsed: %02d:%02d:%02d\n" $((diff / 3600)) $(((diff % 3600) / 60)) $((diff % 60))
    ;;
  *)
    echo "Usage: sw [start|stop|elapsed]"
    ;;
  esac
}

# === Setup ===
# Setup zsh auto completion
autoload -Uz compinit && compinit

# Perserve auto-completion for passed commands
compdef _precommand only
compdef _precommand silent

[ -f $BREW_PREFIX/bin/brew ] && eval "$($BREW_PREFIX/bin/brew shellenv)" # Activate homebrew
eval "$(mise activate zsh)"

# Auto completion
eval "$(mise completion zsh)"
eval "$(just --completions zsh)"
eval "$(kv completion zsh)"
eval "$(jumper init)"

exists gum && eval "$(gum completion zsh)"

# Load local config if present
[ -f ~/.zsh_local ] && source "$HOME/.zsh_local"

# Increase open files limit for brew updates
ulimit -n 4096

# Make sure starship is installed
exists starship || brew install starship

# === Oh-My-Zsh Setup ===
# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Install oh-my-zsh if not installed
if [ ! -d "$ZSH" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

plugins=(docker starship fzf git golang node bun python)

# Source oh-my-zsh
source "$ZSH/oh-my-zsh.sh"

# === Post-Setup ===

# Needs to be here otherwise it is overridden by oh-my-zsh
if exists eza; then
  alias ls="eza --icons=always --group-directories-first"
  alias la="ls -a"
  alias ll="la -lh --git"
  alias l="ll --git-ignore"
  alias lt="l --tree"
  alias llt="ll --tree"
fi

self-cleanup

# === End ===
