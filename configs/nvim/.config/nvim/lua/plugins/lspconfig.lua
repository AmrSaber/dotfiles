return {
  "neovim/nvim-lspconfig",
  opts = {
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
