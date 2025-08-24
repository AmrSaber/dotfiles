#!/usr/bin/bash

nala install curl git openssh zsh neovim just zellij stow gum skate jq # Core tools
nala install bat fd ripgrep eza zoxide yazi                            # Modern alternatives

# Install grun, glibc-wrapper. This must be on 2 steps
nala install glibc-repo
nala install glibc-runner

# Install oh-my-zsh
[[ ! -d ~/.oh-my-zsh ]] && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install zshmarks
[[ ! -d ~/.oh-my-zsh/custom/plugins/zshmarks ]] && git clone https://github.com/jocelynmallon/zshmarks.git ~/.oh-my-zsh/custom/plugins/zshmarks
