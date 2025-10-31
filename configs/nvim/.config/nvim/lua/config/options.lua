-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Handle clipboard for SSH connectinos
if os.getenv("SSH_CLIENT") or os.getenv("SSH_TTY") then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      -- Kitty does not allow apps to read clipboard easily
      ["+"] = function()
        return {}, ""
      end,
      ["*"] = function()
        return {}, ""
      end,
    },
  }
end

vim.opt.colorcolumn = "121"

-- Do not conceal syntax
vim.opt.conceallevel = 0

-- Disable trouble lualine. No need for noisy components in lualine
vim.g.trouble_lualine = false

-- Override colors for popups and floating windows
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "Pmenu", { bg = "#2d2d2d" })
    vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#4a4a4a", fg = "#ffffff" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#2d2d2d" })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#2d2d2d", fg = "#6a6a6a" })
  end,
})
