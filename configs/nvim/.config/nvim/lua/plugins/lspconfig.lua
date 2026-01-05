return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    -- Disable snippets for all servers
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = false
    opts.servers = opts.servers or {}
    opts.servers["*"] = opts.servers["*"] or {}
    opts.servers["*"].capabilities = capabilities

    -- don't refresh diagnostics while typing
    opts.diagnostics = { update_in_insert = false }

    opts.inlay_hints = { enabled = false }

    return opts
  end,
  init = function()
    -- Increase treesitter highlight priority to override LSP semantic tokens
    -- This allows SQL injection highlighting in strings to work
    vim.highlight.priorities.semantic_tokens = 95
    vim.highlight.priorities.treesitter = 100
  end,
}
