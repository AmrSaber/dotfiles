return {
  "hrsh7th/nvim-cmp",
  opts = {
    completion = {
      completeopt = "menu,menuone,noinsert",
    },

    -- Only use built-in snippets, do not insert from LSP
    snippet = {
      expand = function(args)
        vim.snippet.expand(args.body)
      end,
    },

    sources = {
      { name = "nvim_lsp" }, -- LSP
      { name = "path" }, -- file system path
    },

    performance = {
      debounce = 500, -- ms to wait after last keystroke
      throttle = 500, -- ms between successive completion requests
      fetching_timeout = 500, -- optional: cancel slow sources
    },
  },
}
