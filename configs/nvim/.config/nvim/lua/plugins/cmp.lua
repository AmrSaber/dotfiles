return {
  "hrsh7th/nvim-cmp",
  opts = function(_, opts)
    local cmp = require("cmp")

    opts.completion = {
      completeopt = "menu,menuone",
    }

    -- Only use built-in snippets, do not insert from LSP
    opts.snippet = {
      expand = function(args)
        vim.snippet.expand(args.body)
      end,
    }

    opts.sources = {
      { name = "nvim_lsp" }, -- LSP
      { name = "path" }, -- file system path
    }

    opts.performance = {
      debounce = 500, -- ms to wait after last keystroke
      throttle = 500, -- ms between successive completion requests
      fetching_timeout = 500, -- optional: cancel slow sources
    }

    opts.mapping = vim.tbl_extend("force", opts.mapping or {}, {
      ["<C-y>"] = cmp.mapping.confirm({ select = true }),
      ["<CR>"] = cmp.mapping(function(fallback)
        fallback()
      end, { "i", "s" }),
      ["<S-CR>"] = cmp.mapping(function(fallback)
        fallback()
      end, { "i", "s" }),
      ["<C-CR>"] = cmp.mapping(function(fallback)
        fallback()
      end, { "i", "s" }),
    })

    return opts
  end,
}
