return {
  -- Prettier defaults trailingComma to "all", which adds trailing commas to
  -- jsonc — jsonls then flags them as warnings. Use a jsonc-only prettier
  -- variant so other filetypes keep prettier's defaults.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        prettier_jsonc = {
          inherit = false,
          command = "prettier",
          args = { "--parser", "jsonc", "--trailing-comma", "none" },
          stdin = true,
        },
      },
      formatters_by_ft = {
        jsonc = { "prettier_jsonc" },
      },
    },
  },
}
