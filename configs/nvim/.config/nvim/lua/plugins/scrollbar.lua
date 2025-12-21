return {
  "petertriho/nvim-scrollbar",
  event = "VeryLazy",
  dependencies = { "lewis6991/gitsigns.nvim" },
  config = function()
    require("scrollbar").setup({
      handlers = { cursor = false },
      marks = {
        Search = {
          text = { "-", "=" },
        },
        Error = {
          text = { "-", "=" },
        },
        Warn = {
          text = { "-", "=" },
        },
        Info = {
          text = { "-", "=" },
        },
        Hint = {
          text = { "-", "=" },
        },
        Misc = {
          text = { "-", "=" },
        },
        GitAdd = {
          text = "┃",
        },
        GitChange = {
          text = "┃",
        },
        GitDelete = {
          text = "▁",
        },
      },
    })
    require("scrollbar.handlers.gitsigns").setup()
  end,
}
