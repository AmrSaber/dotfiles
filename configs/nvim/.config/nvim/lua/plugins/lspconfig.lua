return {
  "neovim/nvim-lspconfig",
  opts = {
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
