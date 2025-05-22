return {
  "hrsh7th/nvim-cmp",
  opts = {
    completion = {
      completeopt = "menu,menuone,noinsert",
    },

    sources = {
      { name = "nvim_lsp" }, -- lsp
      { name = "path" }, -- file system paths
    },
  },
}
