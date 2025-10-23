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
  },
  opts = {
    picker = {
      sources = {
        -- explorer opens to the right
        explorer = {
          layout = {
            layout = {
              position = "right"
            }
          }
        }
      }
    }
  }
}
