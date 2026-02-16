#!/usr/bin/env bash

# Termux has totally different setup
if [ -n "$TERMUX_VERSION" ]; then
  nala install curl git openssh zsh neovim just zellij stow gum jq starship # Core tools
  nala install bat fd ripgrep eza zoxide yazi                               # Modern alternatives

  # Install grun, glibc-wrapper. This must be on 2 steps
  nala install glibc-repo
  nala install glibc-runner

  # Stow all the configurations
  if [ -z "${NO_STOW:-}" ]; then
    rm ~/.zshrc
    just stow-all
  fi

  exit 0
fi

# Fedora setup
if which dnf &>/dev/null; then
  sudo dnf upgrade -y
  sudo dnf install -y curl git zsh ps @development-tools # Essentials - ps is required by brew
fi

# If apt is installed: update then use nala
if which apt &>/dev/null; then
  # Install nala if it does not exist
  which nala &>/dev/null || sudo apt update && sudo apt install nala -y

  # System update using nala, and install essential packages
  sudo nala upgrade -y
  sudo nala install -y curl git zsh build-essential # Essentials
fi

# Install brew if not installed
brew_path="/home/linuxbrew/.linuxbrew/bin/brew"
[ -f "$brew_path" ] || bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Activate brew
eval "$("$brew_path" shellenv)"

# Install needed brew packages
brew_packages=(
  neovim just mise zellij stow gum amrsaber/tap/kv jq starship # Core tools
  bat fd ripgrep eza                                           # Modern alternatives
  tlrc fzf yazi yq                                             # Quality of life
  neofetch fastfetch btop shellcheck                           # Extras
  ffmpeg sevenzip poppler resvg imagemagick                    # Yazi tool-kit to provide previews
  go python                                                    # Programming languages
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
  │ # Initial install using go
  │ go install github.com/marcosnils/bin@latest

  │ # Cleanup - removed installed go package
  │ trap "rm -f $(go env GOPATH)/bin/bin" EXIT

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

# If not in SSH connection nor in headless mode
if [ -z "${SSH_CLIENT:-}" ] && [ -z "${HEADLESS:-}" ]; then
  # Install kitty
  which nala &>/dev/null && sudo nala install -y kitty
  which dnf &>/dev/null && sudo dnf install -y kitty

  # === Install browsers ===

  # Firefox & Chromium
  if which dnf &>/dev/null; then
    sudo dnf install -y chromium firefox
  elif which snap &>/dev/null; then
    which nala &>/dev/null && sudo nala remove firefox # Usually outdated
    sudo snap install chromium firefox
  fi

  # Vivaldi
  if which flatpak &>/dev/null; then
    flatpak install -y vivaldi
  elif which snap &>/dev/null; then
    sudo snap install vivaldi
  fi
fi
