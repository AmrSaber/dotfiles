#!/usr/bin/env bash

# Must be run as root (via sudo)
if [ "$(id -u)" != "0" ]; then
  echo "system.sh must be run as root" >&2
  exit 1
fi

is_headless() {
  [[ -n "${SSH_CLIENT:-}" || -n "${HEADLESS:-}" ]]
}

if grep -iq fedora /etc/os-release; then
  dnf upgrade -y

  packages=(
    curl git zsh @development-tools flatpak # Essentials
    ps                                      # Required by brew
    hostname                                # Not found in some environments
  )
  if ! is_headless; then
    dnf copr enable -y scottames/ghostty
    packages+=(ghostty chromium firefox)
  fi

  dnf install -y "${packages[@]}"

  is_headless || flatpak install -y vivaldi
elif grep -iq ubuntu /etc/os-release; then
  # Install nala if it does not exist
  if ! command -v nala &>/dev/null; then
    apt update
    apt install nala -y
  fi

  nala upgrade -y
  nala install -y curl git zsh build-essential # Essentials

  if ! is_headless; then
    # Install ghostty
    curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh | bash

    # Browsers
    nala remove firefox # Usually outdated
    snap install chromium firefox vivaldi
  fi
else
  echo "Unhandled OS to setup!" >&2
  exit 1
fi
