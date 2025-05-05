-- LSP Support
return {
  -- LSP Configuration
  -- https://github.com/neovim/nvim-lspconfig
  "neovim/nvim-lspconfig",
  dependencies = {
    -- LSP Management
    -- https://github.com/williamboman/mason.nvim
    { "williamboman/mason.nvim" },
    -- https://github.com/williamboman/mason-lspconfig.nvim
    { "williamboman/mason-lspconfig.nvim" },

    -- Useful status updates for LSP
    -- https://github.com/j-hui/fidget.nvim
    {
      "j-hui/fidget.nvim",
      opts = {}
    },

    -- Additional lua configuration, makes nvim stuff amazing!
    -- https://github.com/folke/neodev.nvim
    {
      "folke/neodev.nvim",
      opts = {}
    },
  },
  config = function()
    require("mason").setup({
      ensure_installed = {
        -- LSPs
        "ts_ls", -- requires npm to be installed

        -- Formatters
        "prettier",
        "gofmt",
        "goimports",
        "rustfmt",
        "stylua",
        "black", -- python
      },
    })

    require("mason-lspconfig").setup({
      automatic_installation = true,

      -- Install these LSPs automatically
      ensure_installed = {
        -- 'bashls', -- requires npm to be installed
        "cssls",  -- requires npm to be installed
        "html",   -- requires npm to be installed
        "lua_ls",
        "jsonls", -- requires npm to be installed
        "lemminx",
        "marksman",
        "yamlls", -- requires npm to be installed
        "gopls",
        "rust_analyzer",
        "dockerls",
        "docker_compose_language_service",
      },
    })

    local lspconfig = require("lspconfig")
    local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
    local lsp_attach = function(client, bufnr)
      -- Create your keybindings here...
    end

    -- Call setup on each LSP server
    require("mason-lspconfig").setup_handlers({
      function(server_name)
        lspconfig[server_name].setup({
          on_attach = lsp_attach,
          capabilities = lsp_capabilities,
        })
      end,
    })

    -- Lua LSP settings
    lspconfig.lua_ls.setup({
      settings = {
        Lua = {
          diagnostics = {
            -- Get the language server to recognize the `vim` global
            globals = { "vim" },
          },
        },
      },
    })
  end,
}
