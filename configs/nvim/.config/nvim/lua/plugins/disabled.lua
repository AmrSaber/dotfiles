local system = require("config.system")

-- Disable treesitter on AL2
local enable_treesitter = not system.is_al2()

return {
  -- Permanently disabled
  { "folke/noice.nvim", enabled = false },
  { "catppuccin/nvim", enabled = false },
  { "folke/tokyonight.nvim", enabled = false },

  { "nvim-treesitter/nvim-treesitter", enabled = enable_treesitter },
  { "nvim-treesitter/nvim-treesitter-textobjects", enabled = enable_treesitter },
}
