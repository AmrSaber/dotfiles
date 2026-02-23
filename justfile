# Paths
backup_dir := 'backup'
extensions_dir := backup_dir / 'extensions'
extension_configs_path := backup_dir / 'extension-configs.dconf'

set fallback

[private]
@default:
  just --list --unsorted

# Backup extensions and their config
backup-extensions:
  #!/usr/bin/env bash

  mkdir -p {{backup_dir}}

  # Remove old extensions
  rm -rf {{extensions_dir}}

  cp -r ~/.local/share/gnome-shell/extensions {{extensions_dir}} # Backup extensions
  dconf dump /org/gnome/shell/extensions/ > {{extension_configs_path}} # Backup extension configs

# Restore extensions and their config
restore-extensions:
  cp -r {{extensions_dir}} ~/.local/share/gnome-shell/extensions
  dconf load /org/gnome/shell/extensions/ < {{extension_configs_path}} # Load extension configs

# Stows given packages. If none provided, interactive select is used.
[working-directory: './configs']
stow *apps:
  #!/usr/bin/env bash
 
  apps={{apps}}

  # If no apps provided, choose which ones to stow
  [ -z "$apps" ] && apps=$(gum choose --no-limit $(ls))

  # Stow provided/selected apps
  if [ -n "$apps" ]; then
    echo "Stowing [$(echo $apps | tr '\n' ' ' | sed 's/ *$//')]"
    stow -t "$HOME" -R $apps
  else
    gum style --foreground=03 "Nothing provided to stow!"
  fi

# Stows all configs
[working-directory: './configs']
stow-all:
  #!/usr/bin/env bash

  for app in *; do
    stow -t "$HOME" -R "$app" && echo "Stowed $app" || echo "Could not stow $app"
  done

# List existing configs
list-configs:
  @ls ./configs
alias ls := list-configs

# Pull origin main
pull:
  git pull origin main

# Add all, commit, pull, and push
commit:
  git add .
  git commit
  git pull
  git push

# Edit justfile
@edit:
  nvim justfile
