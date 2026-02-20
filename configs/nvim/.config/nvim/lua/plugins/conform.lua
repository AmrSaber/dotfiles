return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      -- Disable prettier for markdown to prevent it from adding blank lines
      -- around headings, bullet points, and other block elements
      markdown = {},
    },
  },
}
