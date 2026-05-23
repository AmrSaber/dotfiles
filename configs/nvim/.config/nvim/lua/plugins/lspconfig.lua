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

    -- Fix gopls semantic tokens workaround crash ("table index is nil" at
    -- vim/lsp/semantic_tokens.lua:66): pad the fabricated legend's
    -- tokenTypes/tokenModifiers lists so gopls can't reference OOB indices.
    -- The Go extra workaround creates these from client capabilities (10 mods,
    -- 23 types) but gopls may use higher indices.
    opts.setup = opts.setup or {}
    local orig_gopls_setup = opts.setup.gopls
    opts.setup.gopls = function(client, config)
      if orig_gopls_setup then
        orig_gopls_setup(client, config)
      end

      Snacks.util.lsp.on({ name = "gopls" }, function(_, client)
        local prov = client.server_capabilities.semanticTokensProvider
        if prov and prov.legend then
          local function pad(t, n)
            for i = #t + 1, n do
              t[i] = ""
            end
            return t
          end

          prov.legend.tokenModifiers = pad(prov.legend.tokenModifiers or {}, 64)
          prov.legend.tokenTypes = pad(prov.legend.tokenTypes or {}, 64)
        end
      end)
    end

    return opts
  end,
  init = function()
    -- Increase treesitter highlight priority to override LSP semantic tokens
    -- This allows SQL injection highlighting in strings to work
    vim.highlight.priorities.semantic_tokens = 95
    vim.highlight.priorities.treesitter = 100

    -- Make <Esc> close the LSP hover float from the source buffer.
    -- Wrapping open_floating_preview is necessary because vim.lsp.buf.hover() in
    -- 0.11+ no longer exposes the float's bufnr/winnr (no callback, no global handler).
    local orig = vim.lsp.util.open_floating_preview
    vim.lsp.util.open_floating_preview = function(contents, syntax, opts)
      local src_buf = vim.api.nvim_get_current_buf()
      local bufnr, winnr = orig(contents, syntax, opts)
      if opts and opts.focus_id == "textDocument/hover" and winnr and vim.api.nvim_win_is_valid(winnr) then
        vim.keymap.set("n", "<Esc>", function()
          if vim.api.nvim_win_is_valid(winnr) then
            vim.api.nvim_win_close(winnr, true)
          end
          pcall(vim.keymap.del, "n", "<Esc>", { buffer = src_buf })
        end, { buffer = src_buf, silent = true, nowait = true, desc = "Close hover" })
        vim.api.nvim_create_autocmd("WinClosed", {
          pattern = tostring(winnr),
          once = true,
          callback = function()
            pcall(vim.keymap.del, "n", "<Esc>", { buffer = src_buf })
          end,
        })
      end
      return bufnr, winnr
    end
  end,
}
