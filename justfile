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

# Stows all configs
[working-directory: './configs']
stow:
  #!/usr/bin/env bash

  for app in *; do
    if [[ "$app" == "opencode" ]]; then
      stow -t "$HOME" --no-folding -R "$app"
    else
      stow -t "$HOME" -R "$app"
    fi

    if (($? == 0)); then
      gum style --foreground 4 "Stowed '$app'"
    else
      gum style --foreground 1 "Could not stow '$app'"
    fi

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
