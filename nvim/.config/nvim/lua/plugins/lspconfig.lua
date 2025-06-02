return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- Disable golang hints
      gopls = {
        settings = {
          gopls = {
            hints = {
              assignVariableTypes = false,
              compositeLiteralFields = false,
              compositeLiteralTypes = false,
              constantValues = false,
              functionTypeParameters = false,
              parameterNames = false,
              rangeVariableTypes = false,
            },
          },
        },
      },
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
