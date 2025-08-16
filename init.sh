#!/usr/bin/bash

# If apt is installed: update then use nala
if which apt &>/dev/null; then
  sudo apt update
  sudo apt install nala -y

  # System update using nala, and install essential packages
  sudo nala upgrade -y
  sudo nala install -y curl git zsh # Essentials
fi

# Install brew if not installed
which brew &>/dev/null || eval "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Activate brew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install needed brew packages
brew install neovim just mise zellij stow gum skate jq # Core tools
brew install bat fd ripgrep eza zoxide                 # Modern alternatives
brew install tlrc fzf yazi                             # Quality of life
brew install ffmpeg sevenzip poppler resvg imagemagick # Yazi tool-kit to provide previews
brew install font-ubuntu-mono-nerd-font                # Nerd font
brew install go rust elixir                            # Programming languages

# Activate mise
eval "$(mise activate zsh)"

# More programming languages
mise use -g bun node@lts

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install zshmarks
git clone https://github.com/jocelynmallon/zshmarks.git ~/.oh-my-zsh/custom/plugins

# If not in SSH connection
if [ -z "$SSH_CLIENT" ]; then
  # Install kitty if on depian based system
  which nala &>/dev/null && sudo nala install -y kitty

  # Install browsers
  if which snap &>/dev/null && gum confirm 'Install browsers?'; then
    which nala &>/dev/null && sudo nala remove firefox
    sudo snap install vivaldi firefox chromium
  fi
fi
