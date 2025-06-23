#!/usr/bin/bash

# If apt is installed: update then use nala
if which apt &>/dev/null; then
  sudo apt update
  sudo apt install nala
  sudo nala full-upgrade -y
  sudo nala install curl git # Essentials
fi

# Install brew if not installed
which brew &>/dev/null || eval "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install needed brew packages
brew install neovim just mise zellij stow gum skate fzf bat jq yazi tldr # Tools
brew install go rust gleam                                               # Programming languages

# More programming languages
mise use -g bun node@lts

# Browsers, if snap is available
if which snap &>/dev/null; then
  sudo nala remove firefox
  sudo snap install vivaldi firefox chromium
fi
