return {
  "hrsh7th/nvim-cmp",
  opts = function(_, opts)
    local cmp = require("cmp")

    opts.completion = {
      completeopt = "menu,menuone,noselect",
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
      ["<CR>"] = cmp.mapping(function(fallback)
        if cmp.get_selected_entry() then
          cmp.confirm({ select = false })
        else
          fallback()
        end
      end, { "i", "s" }),
    })

    return opts
  end,
}
