local opt = vim.opt

-- Folding
opt.foldmethod = "indent"
opt.foldlevelstart = 999

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Spell checking
opt.spell = true
opt.spelllang = { "en_us", "en_gb" }
opt.spelloptions = 'camel'

-- Tabs & Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
vim.bo.softtabstop = 2

-- Misc options
opt.mouse = "a"
opt.cursorline = true
opt.wrap = false
opt.smartcase = true
