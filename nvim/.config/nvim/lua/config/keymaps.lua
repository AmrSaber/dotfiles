-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap

-- General keymaps
keymap.set("n", "<leader>qw", ":wq<CR>", { desc = "Save and quit" })
keymap.set("n", "<leader>qq", ":q!<CR>", { desc = "Discard and quit" })
keymap.set("n", "<leader>ww", ":w<CR>", { desc = "Save" })
keymap.set("n", "<leader>wq", ":wq<CR>", { desc = "Save and quit" })

-- Goto Import
vim.keymap.set('n', 'gi', function()
  local word = vim.fn.expand('<cword>')
  vim.cmd('silent! /\\<' .. word .. '\\>')
end, { desc = 'Go to import statement' })

