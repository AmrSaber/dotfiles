#!/usr/bin/env bash

SCRIPTS_DIR="$(dirname "${BASH_SOURCE[0]}")/scripts"

# Termux has totally different setup
if [ -n "$TERMUX_VERSION" ]; then
  bash "$SCRIPTS_DIR/termux.sh"
  exit 0
fi

# System packages and OS-level setup (requires root or sudo)
if [ -z "${NO_SYSTEM:-}" ]; then
  sudo bash "$SCRIPTS_DIR/system.sh"
fi

# Install brew if not installed
brew_path="/home/linuxbrew/.linuxbrew/bin/brew"
if ! [ -f "$brew_path" ]; then
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
fi

# Activate brew
eval "$("$brew_path" shellenv)"

# Add personal homebrew tap
brew tap amrsaber/tap

# Install needed brew packages
brew_packages=(
  neovim just mise zellij stow gum kv jumper jq starship # Core tools
  bat fd ripgrep eza                                     # Modern alternatives
  tlrc fzf yazi yq                                       # Quality of life
  neofetch fastfetch btop shellcheck                     # Extras
  ffmpeg sevenzip poppler resvg imagemagick              # Yazi tool-kit to provide previews
  go python                                              # Programming languages
)

brew_casks=(
  font-ubuntu-mono-nerd-font # Nerd font
)

brew install "${brew_packages[@]}"
brew install --cask "${brew_casks[@]}"

# More programming languages
eval "$(mise activate bash)"
mise use -g bun node@lts

# Install bin
if ! command -v bin &>/dev/null; then
  # Initial install using go
  go install github.com/marcosnils/bin@latest

  # Cleanup - remove installed go package
  trap 'rm -f $(go env GOPATH)/bin/bin' EXIT

  if command -v bin; then
    # Get bin to track itself
    bin install github.com/marcosnils/bin
  else
    echo 'bin was not installed successfully!' >&2
  fi
fi

# Stow all the configurations
if [ -z "${NO_STOW:-}" ]; then
  rm ~/.zshrc
  just stow-all
fi
