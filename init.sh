#!/usr/bin/env bash

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
brew install neovim just mise zellij stow gum skate jq # Core tools
brew install bat fd ripgrep eza                        # Modern alternatives
brew install tlrc fzf yazi                             # Quality of life
brew install neofetch fastfetch btop                   # Extras
brew install ffmpeg sevenzip poppler resvg imagemagick # Yazi tool-kit to provide previews
brew install --cask font-ubuntu-mono-nerd-font         # Nerd font
brew install go python rust                            # Programming languages

# Activate mise based on current shell
eval "$(mise activate "$(basename "$SHELL")")"

# More programming languages
mise use -g bun node@lts

# Install oh-my-zsh if not installed
if [ ! -d ~/.oh-my-zsh ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install zshmarks
if [ ! -d ~/.oh-my-zsh/custom/plugins/zshmarks ]; then
  git clone https://github.com/jocelynmallon/zshmarks.git ~/.oh-my-zsh/custom/plugins/zshmarks
fi

# Stow all the configurations
if [ -z "${NO_STOW:-}" ]; then
  rm ~/.zshrc
  just stow-all
fi

cp ./themes/zsh/* ~/.oh-my-zsh/themes/

# If not in SSH connection nor in headless mode
if [ -z "${SSH_CLIENT:-}" ] && [ -z "${HEADLESS:-}" ]; then
  # Install kitty if on Debian based system
  which nala &>/dev/null && sudo nala install -y kitty

  # Install browsers
  if which snap &>/dev/null && gum confirm 'Install browsers?'; then
    which nala &>/dev/null && sudo nala remove firefox
    sudo snap install vivaldi firefox chromium
  fi
fi
