# Personal Neovim Config
Personal configurations for neovim. This is built over https://github.com/bcampolo/nvim-starter-kit repo with some edits.

## Install
To remove old config run...
```bash
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
```

## Structure
```
nvim
├── ftplugin
│   └── markdown.lua -- Special instructions for specific file types
├── init.lua -- entry point, just installs lazy, and imports other files
├── lazy-lock.json -- package-lock for lazy
├── lua
│   ├── core
│   │   ├── keymaps.lua -- for custom key maps, mainly for the plugins
│   │   └── options.lua -- for custom options and configurations
│   └── plugins -- contains all the needed plugins, add any additional plugin here
└── README.md -- this file you're viewing :)
```

