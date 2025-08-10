return {
  "neovim/nvim-lspconfig",
  opts = {
    -- disable the default tsserver
    servers = { tsserver = false },

    -- enable vtsls with lightweight settings
    setup = {
      vtsls = function(_, opts)
        opts.flags = { debounce_text_changes = 300 }
        opts.handlers = {
          ["textDocument/semanticTokens/full"] = function() end, -- no semantic tokens
        }
        opts.init_options = {
          maxTsServerMemory = 4096,
          preferences = {
            disableSuggestions = true,
            disableAutomaticTypeAcquisition = true,
          },
        }
        opts.settings = {
          typescript = {
            inlayHints = { parameterNames = { enabled = "none" } },
          },
        }
        require("lspconfig").vtsls.setup(opts)
        return true -- stop LazyVim from doing default setup
      end,
    },

    -- don’t refresh diagnostics while typing
    diagnostics = { update_in_insert = false },

    inlay_hints = {
      enabled = false,
    },

    capabilities = {
      textDocument = {
        completion = {
          completionItem = {
            snippetSupport = false, -- Disable snippets
          },
        },
      },
    },
  },
}
