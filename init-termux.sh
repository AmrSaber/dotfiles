#!/usr/bin/bash

nala install curl git openssh
nala install neovim just zellij stow gum skate jq # Core tools
nala install bat fd ripgrep eza zoxide            # Modern alternatives

# Install oh-my-zsh
[[ ! -d ~/.oh-my-zsh ]] && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install zshmarks
[[ ! -d ~/.oh-my-zsh/custom/plugins/zshmarks ]] && git clone https://github.com/jocelynmallon/zshmarks.git ~/.oh-my-zsh/custom/plugins/zshmarks
