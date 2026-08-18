local system = require("config.system")

-- Disable treesitter on AL2 (old toolchain can't build the parsers)
local enable_treesitter = not system.is_al2()

return {
  -- Permanently disabled
  { "folke/noice.nvim", enabled = false },

  { "nvim-treesitter/nvim-treesitter", enabled = enable_treesitter },
  { "nvim-treesitter/nvim-treesitter-textobjects", enabled = enable_treesitter },
  { "windwp/nvim-ts-autotag", enabled = enable_treesitter },
}
