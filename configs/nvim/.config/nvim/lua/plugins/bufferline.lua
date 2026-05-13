local colors = {
  fill = "#444444",
  selected_bg = "#666666",
  selected_fg = "#ffffff",
}

local selected_style = {
  bg = colors.selected_bg,
  fg = colors.selected_fg,
  bold = true,
}

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
      fill = { bg = colors.fill },

      separator_visible = { fg = colors.fill },
      separator = { fg = colors.fill },
      separator_selected = { fg = colors.fill, bg = colors.selected_bg },

      buffer_selected = selected_style,
      tab_selected = selected_style,
      close_button_selected = selected_style,
      numbers_selected = selected_style,
      modified_selected = selected_style,
      duplicate_selected = selected_style,
      indicator_selected = selected_style,
      pick_selected = selected_style,

      diagnostic_selected = selected_style,

      hint_selected = selected_style,
      hint_diagnostic_selected = selected_style,

      error_selected = selected_style,
      error_diagnostic_selected = selected_style,

      warning_selected = selected_style,
      warning_diagnostic_selected = selected_style,

      info_selected = selected_style,
      info_diagnostic_selected = selected_style,
    },
  },
}
