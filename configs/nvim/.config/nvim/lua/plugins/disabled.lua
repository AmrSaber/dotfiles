return {
  { "folke/noice.nvim", enabled = false },
  {
    "nvim-treesitter/nvim-treesitter",

    -- Disable treesitter on AL2
    enabled = not vim.fn.filereadable("/etc/system-release-cpe") or
              not vim.fn.readfile("/etc/system-release-cpe")[1]:match("amazon_linux:2"),
  },
}
