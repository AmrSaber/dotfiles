return {
  -- Prettier defaults trailingComma to "all", which adds trailing commas to
  -- jsonc/json — jsonls then flags them as warnings. Drop them at the source.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        prettier = {
          prepend_args = { "--trailing-comma", "none" },
        },
      },
    },
  },
}
