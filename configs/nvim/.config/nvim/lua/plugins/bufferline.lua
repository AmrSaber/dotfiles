return {
  "akinsho/bufferline.nvim",
  keys = {
    { "gb", "<Cmd>BufferLinePick<CR>", desc = "Pick buffer" },
    { "<leader>bD", "<Cmd>BufferLinePickClose<CR>", desc = "Pick buffer close" },
  },
  opts = {
    options = {
      pick = {
        alphabet = "abcdefghijklmopqrstuvwxyz"
      }
    }
  }
}
