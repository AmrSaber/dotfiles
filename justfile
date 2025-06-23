# Paths
dconf_dir := 'dconf'
shell_dump := dconf_dir / 'shell.toml'
bindings_dump := dconf_dir / 'keybindings.toml'
custom_bindings_dump := dconf_dir / 'custom-bindings.toml'

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

# Stows given packages, defaults to all
[working-directory: './configs']
stow +dirs='*':
  stow -t ~ -R {{dirs}}

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

# Commit nvim lock-file changes
commit-lock-file:
  git reset
  git add ./nvim/.config/nvim/lazy-lock.json
  git commit -m 'nvim: update lock-file'
  git push

# Edit justfile
@edit:
  nvim justfile
