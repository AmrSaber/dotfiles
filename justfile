# Paths
dconf_dir := 'configs/dconf'
shell_dump := dconf_dir / 'shell.toml'
bindings_dump := dconf_dir / 'keybindings.toml'
custom_bindings_dump := dconf_dir / 'custom-bindings.toml'
last_updated_at_file := '.last-updated-at'

# dconf paths
dconf_shell := '/org/gnome/shell/'
dconf_bindings := '/org/gnome/desktop/wm/keybindings/'
dconf_custom_bindings := '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/'

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

# Add all, commit, and push
commit:
  git add .
  git commit
  git push

# Update dotfiles but only once a day
update:
  #!/bin/zsh
  last_updated=$(cat {{last_updated_at_file}} 2> /dev/null)
  today=$(date -uI)

  if [[ -z $last_updated || $last_updated -lt $today ]]; then
    if [ -n "$(git status --untracked-files=no --porcelain)" ]; then
      gum style --foreground 3 "dotfiles workspace is not clean, skipping update!"
      exit 0
    fi

    gum style --foreground 4 "Updating dotfiles..."
    git pull
    echo $today > {{last_updated_at_file}}
  fi

# Edit justfile
@edit:
  nvim justfile
