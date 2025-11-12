local system = require("config.system")

return {
  { "folke/noice.nvim", enabled = false },

  -- Disable treesitter on AL2
  { "nvim-treesitter/nvim-treesitter", enabled = not system.is_al2() },
}
