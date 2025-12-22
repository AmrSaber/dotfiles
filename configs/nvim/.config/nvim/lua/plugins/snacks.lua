return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader><leader>",
      function()
        Snacks.picker.files({
          hidden = true,
          no_ignore_vcs = false,
        })
      end,
      desc = "Find Files (cwd, hidden, no git-ignored)",
    },
    { "<leader>e", false },
    { "<leader>E", false },
    { "<leader>fe", false },
    { "<leader>fE", false },
  },

  opts = {
    explorer = { enabled = false },

    picker = {
      formatters = {
        -- Only truncate file path after it exceeds 9999 characters
        -- Effectively disables truncation
        file = {
          truncate = "right",
          min_width = 9999,
        },
      },
    },
  },
}
