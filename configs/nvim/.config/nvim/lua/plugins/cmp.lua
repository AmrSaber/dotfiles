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

    performance = {
      debounce = 500, -- ms to wait after last keystroke
      throttle = 500, -- ms between successive completion requests
      fetching_timeout = 500, -- optional: cancel slow sources
    },
  },
}
