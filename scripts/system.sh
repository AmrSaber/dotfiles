#!/usr/bin/env bash

# Must be run as root (via sudo)
if [ "$(id -u)" != "0" ]; then
  echo "system.sh must be run as root" >&2
  exit 1
fi

# Fedora setup
if command -v dnf &>/dev/null; then
  dnf upgrade -y
  dnf install -y curl git zsh ps @development-tools hostname # Essentials - ps is required by brew
fi

# If apt is installed: update then use nala
if command -v apt &>/dev/null; then
  # Install nala if it does not exist
  command -v nala &>/dev/null || apt update && apt install nala -y

  # System update using nala, and install essential packages
  nala upgrade -y
  nala install -y curl git zsh build-essential # Essentials
fi

# If not in SSH connection nor in headless mode
if [ -z "${SSH_CLIENT:-}" ] && [ -z "${HEADLESS:-}" ]; then
  # Install ghostty
  command -v nala &>/dev/null && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"

  if command -v dnf &>/dev/null; then
    dnf copr enable -y scottames/ghostty
    dnf install -y ghostty
  fi

  # === Install browsers ===

  # Firefox & Chromium
  if command -v dnf &>/dev/null; then
    dnf install -y chromium firefox
  elif command -v snap &>/dev/null; then
    command -v nala &>/dev/null && nala remove firefox # Usually outdated
    snap install chromium firefox
  fi

  # Vivaldi
  if command -v flatpak &>/dev/null; then
    flatpak install -y vivaldi
  elif command -v snap &>/dev/null; then
    snap install vivaldi
  fi
fi
