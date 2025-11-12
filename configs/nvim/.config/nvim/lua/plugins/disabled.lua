local system = require("config.system")

-- Disable treesitter on AL2
local enable_treesitter = not system.is_al2()

return {
  -- Permanently disable noice
  { "folke/noice.nvim", enabled = false },

  { "nvim-treesitter/nvim-treesitter", enabled = enable_treesitter },
  { "nvim-treesitter/nvim-treesitter-textobjects", enabled = enable_treesitter },
}
