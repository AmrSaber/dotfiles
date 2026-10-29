return {
  "petertriho/nvim-scrollbar",
  -- shortcut: pin v2 until it reaches main on 2026-11-16, then remove this line
  branch = "refactor/v2",
  event = "VeryLazy",
  dependencies = { "lewis6991/gitsigns.nvim" },
  opts = {
    providers = {
      cursor = false,
      search = false,
      marks = false,
      gitsigns = true,
    },
  },
}
