return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {

      -- Optimize tsserver a bit
      tsserver = {
        flags = { debounce_text_changes = 300 },
        handlers = { ["textDocument/semanticTokens/full"] = function() end },
        init_options = {
          maxTsServerMemory = 4096,
          preferences = {
            disableSuggestions = true,
            disableAutomaticTypeAcquisition = true,
          },
        },
      },
    },

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
