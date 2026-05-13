return {
  "romgrk/barbar.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  init = function()
    vim.g.barbar_auto_setup = false
  end,
  keys = {
    { "gb", "<Cmd>BufferPick<CR>", desc = "Pick buffer" },
    { "<leader>bD", "<Cmd>BufferPickDelete<CR>", desc = "Pick buffer close" },
  },
  opts = {
    animation = true,
    auto_hide = 1,
    icons = { preset = "slanted", },
    letters = "abcdefghijklmopqrstuvwxyz",
  },
  config = function(_, opts)
    require("barbar").setup(opts)

    local colors = {
      fill_bg    = "#444444",
      selected_bg = "#666666",
      selected_fg = "#ffffff",
    }

    vim.api.nvim_set_hl(0, "BufferTabpageFill", { bg = colors.fill_bg })

    -- Selected tab: all parts get the same bg, signs use fill as fg (the "up"/outside part)
    vim.api.nvim_set_hl(0, "BufferCurrent",           { fg = colors.selected_fg, bg = colors.selected_bg, bold = true })
    vim.api.nvim_set_hl(0, "BufferCurrentMod",        { fg = colors.selected_fg, bg = colors.selected_bg, bold = true })
    vim.api.nvim_set_hl(0, "BufferCurrentBtn",        { fg = colors.selected_fg, bg = colors.selected_bg })
    vim.api.nvim_set_hl(0, "BufferCurrentIndex",      { fg = colors.selected_fg, bg = colors.selected_bg, bold = true })
    vim.api.nvim_set_hl(0, "BufferCurrentNumber",     { fg = colors.selected_fg, bg = colors.selected_bg, bold = true })
    vim.api.nvim_set_hl(0, "BufferCurrentTarget",     { fg = colors.selected_fg, bg = colors.selected_bg, bold = true })
    vim.api.nvim_set_hl(0, "BufferCurrentSign",       { fg = colors.fill_bg, bg = colors.selected_bg })
    vim.api.nvim_set_hl(0, "BufferCurrentSignRight",  { fg = colors.fill_bg, bg = colors.selected_bg })

    -- Inactive/visible/alternate tabs: fix sign fg=fill (outside), bg=tab (inside)
    for _, status in ipairs({ "Inactive", "Visible", "Alternate" }) do
      local existing = vim.api.nvim_get_hl(0, { name = "Buffer" .. status, link = false })
      local tab_bg = existing.bg and string.format("#%06x", existing.bg) or nil
      vim.api.nvim_set_hl(0, "Buffer" .. status .. "Sign",      { fg = colors.fill_bg, bg = tab_bg })
      vim.api.nvim_set_hl(0, "Buffer" .. status .. "SignRight", { fg = colors.fill_bg, bg = tab_bg })
    end
  end,
}
