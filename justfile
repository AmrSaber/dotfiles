# Paths
dconf_dir := 'dconf'
shell_dump := dconf_dir / 'shell.toml'
bindings_dump := dconf_dir / 'keybindings.toml'
custom_bindings_dump := dconf_dir / 'custom-bindings.toml'

# dconf paths
dconf_shell := '/org/gnome/shell/'
dconf_bindings := '/org/gnome/desktop/wm/keybindings/'
dconf_custom_bindings := '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/'

set fallback

[private]
@default:
  just --list --unsorted

# Dumps dconf configs
dump-config:
  mkdir -p {{dconf_dir}}
  dconf dump {{dconf_shell}} > {{shell_dump}}
  dconf dump {{dconf_bindings}} > {{bindings_dump}}
  dconf dump {{dconf_custom_bindings}} > {{custom_bindings_dump}}

# Loads dconf configs
load-config:
  dconf load {{dconf_shell}} < {{shell_dump}}
  dconf load {{dconf_bindings}} < {{bindings_dump}}
  dconf load {{dconf_custom_bindings}} < {{custom_bindings_dump}}

# Stows given packages. If none provided, interactive select is used.
[working-directory: './configs']
stow *apps:
  #!/usr/bin/bash
 
  apps={{apps}}

  # If no apps provided, choose which ones to stow
  [ -z "$apps" ] && apps=$(gum choose --no-limit $(ls))

  # Stow provided/selected apps
  if [ -n "$apps" ]; then
    echo "Stowing [$(echo $apps | tr '\n' ' ' | sed 's/ *$//')]"
    stow -t ~ -R $apps
  else
    gum style --foreground=03 "Nothing provided to stow!"
  fi

# List existing configs
list-configs:
  @ls ./configs
alias ls := list-configs

# Pull origin main
pull:
  git pull origin main

# Add all, commit, and push
commit:
  git add .
  git commit
  git push

# Commit nvim lock-file changes
commit-lock-file:
  git reset
  git add ./configs/nvim/.config/nvim/lazy-lock.json
  git commit -m 'nvim: update lock-file'
  git push

# Edit justfile
@edit:
  nvim justfile
