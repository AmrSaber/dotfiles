-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap

-- General keymaps
keymap.set("n", "<leader>qw", ":wqa<CR>", { desc = "Save all and quit" })
keymap.set("n", "<leader>qq", ":q!<CR>", { desc = "Discard and quit" })
keymap.set("n", "<leader>ww", ":wa<CR>", { desc = "Save all" })
keymap.set("n", "<leader>wq", ":wqa<CR>", { desc = "Save all and quit" })

-- Goto Import
keymap.set("n", "gi", function()
  local word = vim.fn.expand("<cword>")
  vim.cmd("silent! /\\<" .. word .. "\\>")
end, { desc = "Go to import statement" })

-- Marks
local wk = require("which-key")
wk.add({ { "<leader>m", group = "Marks", desc = "Manage marks" } })
keymap.set("n", "<leader>md", ":delm", { desc = "Delete mark" })
keymap.set("n", "<leader>mD", ":delm! | delm A-Z0-9<CR>:wshada!<CR>", { desc = "Delete all marks" })

-- Deletions do not copy - Only "d" and "D" copy
keymap.set("n", "x", '"_x')
keymap.set("n", "X", '"_X')
keymap.set("v", "x", '"_x')
keymap.set("n", "c", '"_c')
keymap.set("n", "C", '"_C')
keymap.set("v", "c", '"_c')
keymap.set("v", "p", '"_dP')

-- Open mini.files through <leader>e
keymap.set("n", "<leader>e", "<leader>fm", { remap = true, desc = "Open mini.files" })
keymap.set("n", "<leader>E", "<leader>fm", { remap = true, desc = "Open mini.files (cwd)" })

-- Yank operations
wk.add({ { "<leader>y", group = "Yank", desc = "Yank operations", mode = { "n", "v" } } })
keymap.set("v", "<leader>yr", function()
  vim.cmd("normal! ") -- Exit visual mode

  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local filepath = vim.fn.expand("%:p")

  local ref = ""
  if start_line ~= end_line then
    ref = string.format("%s#L%d-%d", filepath, start_line, end_line)
  else
    ref = string.format("%s#L%d", filepath, start_line)
  end

  vim.fn.setreg("+", ref)
  vim.print("Copied: " .. ref)
end, { desc = "Yank range reference" })

keymap.set("n", "<leader>yl", function()
  local line_num = vim.fn.line(".")
  local filepath = vim.fn.expand("%:p")
  local ref = string.format("%s#L%d", filepath, line_num)
  vim.fn.setreg("+", ref)
  print("Copied: " .. ref)
end, { desc = "Yank line reference" })

keymap.set("n", "<leader>yp", function()
  local filepath = vim.fn.expand("%:p")
  vim.fn.setreg("+", filepath)
  print("Copied: " .. filepath)
end, { desc = "Yank buffer path" })

-- Markdown: toggle checklist item
keymap.set("n", "<C-Space>", function()
  local line = vim.api.nvim_get_current_line()
  if line:match("%- %[x%]") then
    vim.api.nvim_set_current_line((line:gsub("%- %[x%]", "- [ ]", 1)))
  elseif line:match("%- %[ %]") then
    vim.api.nvim_set_current_line((line:gsub("%- %[ %]", "- [x]", 1)))
  end
end, { desc = "Toggle markdown checkbox" })
