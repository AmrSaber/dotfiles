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
