return {
  "akinsho/bufferline.nvim",
  keys = {
    { "gb", "<Cmd>BufferLinePick<CR>", desc = "Pick buffer" },
    { "<leader>bD", "<Cmd>BufferLinePickClose<CR>", desc = "Pick buffer close" },
  },
  opts = {
    options = {
      truncate_names = false,
      -- separator_style = "slant" | "slope" | "thick" | "thin" | { 'any', 'any' },
      separator_style = "slant",
      pick = {
        alphabet = "abcdefghijklmopqrstuvwxyz",
      },
    },
    highlights = {
      fill = { bg = "#444444" },

      separator_visible = { fg = "#444444" },
      separator = { fg = "#444444" },
      separator_selected = { fg = "#444444", bg = "#666666" },

      buffer_selected = { bg = "#666666" },
      tab_selected = { bg = "#666666" },
      close_button_selected = { bg = "#666666" },
      numbers_selected = { bg = "#666666" },
      modified_selected = { bg = "#666666" },
      duplicate_selected = { bg = "#666666" },
      indicator_selected = { bg = "#666666" },
      pick_selected = { bg = "#666666" },

      diagnostic_selected = { bg = "#666666" },

      hint_selected = { bg = "#666666" },
      hint_diagnostic_selected = { bg = "#666666" },

      error_selected = { bg = "#666666" },
      error_diagnostic_selected = { bg = "#666666" },

      warning_selected = { bg = "#666666" },
      warning_diagnostic_selected = { bg = "#666666" },

      info_selected = { bg = "#666666" },
      info_diagnostic_selected = { bg = "#666666" },
    },
  },
}
