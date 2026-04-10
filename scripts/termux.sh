#!/usr/bin/env bash

packages=(
  curl git openssh zsh neovim just zellij stow gum jq starship # Core tools
  bat fd ripgrep eza zoxide yazi                               # Modern alternatives
)

nala install "${packages[@]}"

# Install grun, glibc-wrapper. This must be on 2 steps
nala install glibc-repo
nala install glibc-runner

if [ -z "${NO_STOW:-}" ]; then
  rm ~/.zshrc
  just stow-all
fi
