#!/usr/bin/bash

# Only run on servers
if [ -n "$SSH_CLIENT" ]; then
  # Get servers to work with kitty
  [ "$TERM" = "xterm-kitty" ] && export TERM="xterm-256color"
fi

# If apt is installed: update then use nala
if which apt &>/dev/null; then
  sudo apt update
  sudo apt install nala

  # System update using nala, and install essential packages
  sudo nala full-upgrade -y
  sudo nala install curl git # Essentials
fi

# Install brew if not installed
which brew &>/dev/null || eval "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install needed brew packages
brew install neovim just mise zellij stow gum skate fzf bat jq yazi tlrc # Tools
brew install go rust gleam                                               # Programming languages

# Activate mise
eval "$(mise activate zsh)"

# More programming languages
mise use -g bun node@lts

# If not in SSH connection
if [ -z "$SSH_CLIENT" ]; then
  brew install kitty # Install kitty terminal

  # Install browsers
  if which snap &>/dev/null && [ -z "$SSH_CLIENT" ]; then
    sudo nala remove firefox
    sudo snap install vivaldi firefox chromium
  fi
fi
