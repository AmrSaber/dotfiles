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
  sudo dnf install -y curl git zsh snapd ps @development-tools # Essentials - ps is required by brew
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
which brew &>/dev/null || bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Activate brew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install needed brew packages
brew install neovim just mise zellij stow gum amrsaber/tap/kv jq starship # Core tools
brew install bat fd ripgrep eza                                           # Modern alternatives
brew install tlrc fzf yazi yq                                             # Quality of life
brew install neofetch fastfetch btop                                      # Extras
brew install ffmpeg sevenzip poppler resvg imagemagick                    # Yazi tool-kit to provide previews
brew install --cask font-ubuntu-mono-nerd-font                            # Nerd font
brew install go python                                                    # Programming languages

# Activate mise based on current shell (always bash as required by the shebang)
eval "$(mise activate bash)"

# More programming languages
mise use -g bun node@lts

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

  # Install browsers
  if which snap &>/dev/null && gum confirm 'Install browsers?'; then
    which nala &>/dev/null && sudo nala remove firefox
    sudo snap install vivaldi firefox chromium
  fi
fi
