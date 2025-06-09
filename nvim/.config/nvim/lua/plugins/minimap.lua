return {
  "Isrothy/neominimap.nvim",
  version = "v3.x.x",
  lazy = false, -- No need to lazy-load
  keys = {
    -- Global Minimap Controls
    { "<leader>mgt", "<cmd>Neominimap Toggle<cr>", desc = "Toggle global minimap" },
    { "<leader>mgo", "<cmd>Neominimap Enable<cr>", desc = "Enable global minimap" },
    { "<leader>mgc", "<cmd>Neominimap Disable<cr>", desc = "Disable global minimap" },
    { "<leader>mgr", "<cmd>Neominimap Refresh<cr>", desc = "Refresh global minimap" },

    -- Window-Specific Minimap Controls
    { "<leader>mwt", "<cmd>Neominimap WinToggle<cr>", desc = "Toggle minimap for current window" },
    { "<leader>mwo", "<cmd>Neominimap WinEnable<cr>", desc = "Enable minimap for current window" },
    { "<leader>mwc", "<cmd>Neominimap WinDisable<cr>", desc = "Disable minimap for current window" },
    { "<leader>mwr", "<cmd>Neominimap WinRefresh<cr>", desc = "Refresh minimap for current window" },

    -- Tab-Specific Minimap Controls
    { "<leader>mtt", "<cmd>Neominimap TabToggle<cr>", desc = "Toggle minimap for current tab" },
    { "<leader>mto", "<cmd>Neominimap TabEnable<cr>", desc = "Enable minimap for current tab" },
    { "<leader>mtc", "<cmd>Neominimap TabDisable<cr>", desc = "Disable minimap for current tab" },
    { "<leader>mtr", "<cmd>Neominimap TabRefresh<cr>", desc = "Refresh minimap for current tab" },

    -- Buffer-Specific Minimap Controls
    { "<leader>mbt", "<cmd>Neominimap BufToggle<cr>", desc = "Toggle minimap for current buffer" },
    { "<leader>mbo", "<cmd>Neominimap BufEnable<cr>", desc = "Enable minimap for current buffer" },
    { "<leader>mbc", "<cmd>Neominimap BufDisable<cr>", desc = "Disable minimap for current buffer" },
    { "<leader>mbr", "<cmd>Neominimap BufRefresh<cr>", desc = "Refresh minimap for current buffer" },

    ---Focus Controls
    { "<leader>mff", "<cmd>Neominimap Focus<cr>", desc = "Focus on minimap" },
    { "<leader>mfu", "<cmd>Neominimap Unfocus<cr>", desc = "Unfocus minimap" },
    { "<leader>mft", "<cmd>Neominimap ToggleFocus<cr>", desc = "Toggle focus on minimap" },
  },
  init = function()
    -- The following options are recommended when layout == "float"
    vim.opt.wrap = false
    vim.opt.sidescrolloff = 36 -- Set a large value

    -- Put your configuration here
    vim.g.neominimap = {
      auto_enable = true,
    }

    -- which-key setup
    local wk = require("which-key")
    wk.add({
      { "<leader>m", group = "Minimap" },
      { "<leader>mg", group = "Global" },
      { "<leader>mw", group = "Window" },
      { "<leader>mt", group = "Tab" },
      { "<leader>mb", group = "Buffer" },
      { "<leader>mf", group = "Focus" },
    })
  end,
}
