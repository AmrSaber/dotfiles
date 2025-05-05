-- Set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap

-- General keymaps
keymap.set("n", "<leader>wq", ":wq<CR>")       -- save and quit
keymap.set("n", "<leader>qq", ":q!<CR>")       -- quit without saving
keymap.set("n", "<leader>ww", ":w<CR>")        -- save
keymap.set("n", "gx", ":!open <c-r><c-a><CR>") -- open URL under cursor

-- Split window management
keymap.set("n", "<leader>s", "<C-w>") -- split window leader
-- Window split keys commands (enter command after shortcut)...
-- split horizontally: v
-- split vertically: s
-- equal width: =
-- increase height: +
-- decreas height: -
-- increase width: >
-- decrease width: <

-- Tab management
keymap.set("n", "<leader>to", ":tabnew<CR>")             -- open a new tab
keymap.set("n", "<leader>tx", "<Cmd>BufferClose<CR>")    -- close a tab
keymap.set("n", "<leader>tj", "<Cmd>BufferNext<CR>")     -- next tab
keymap.set("n", "<leader>tk", "<Cmd>BufferPrevious<CR>") -- previous tab
keymap.set("n", "<leader>t1", "<Cmd>BufferGoto 1<CR>")
keymap.set("n", "<leader>t2", "<Cmd>BufferGoto 2<CR>")
keymap.set("n", "<leader>t3", "<Cmd>BufferGoto 3<CR>")
keymap.set("n", "<leader>t4", "<Cmd>BufferGoto 4<CR>")
keymap.set("n", "<leader>t5", "<Cmd>BufferGoto 5<CR>")
keymap.set("n", "<leader>t6", "<Cmd>BufferGoto 6<CR>")
keymap.set("n", "<leader>t7", "<Cmd>BufferGoto 7<CR>")
keymap.set("n", "<leader>t8", "<Cmd>BufferGoto 8<CR>")
keymap.set("n", "<leader>t9", "<Cmd>BufferGoto 9<CR>")
keymap.set("n", "<leader>t0", "<Cmd>BufferLast<CR>")       -- last tab
keymap.set("n", "<leader>tt", "<Cmd>BufferPick<CR>")       -- magic pick
keymap.set("n", "<leader>td", "<Cmd>BufferPickDelete<CR>") -- magic pick to delete

-- Quickfix keymaps
keymap.set("n", "<leader>qo", ":copen<CR>")  -- open quickfix list
keymap.set("n", "<leader>qf", ":cfirst<CR>") -- jump to first quickfix list item
keymap.set("n", "<leader>qn", ":cnext<CR>")  -- jump to next quickfix list item
keymap.set("n", "<leader>qp", ":cprev<CR>")  -- jump to prev quickfix list item
keymap.set("n", "<leader>ql", ":clast<CR>")  -- jump to last quickfix list item
keymap.set("n", "<leader>qc", ":cclose<CR>") -- close quickfix list

-- Nvim-tree
keymap.set("n", "<leader>ee", ":NvimTreeToggle<CR>")   -- toggle file explorer
keymap.set("n", "<leader>er", ":NvimTreeFocus<CR>")    -- toggle focus to file explorer
keymap.set("n", "<leader>ef", ":NvimTreeFindFile<CR>") -- find file in file explorer

-- Telescope
keymap.set('n', '<leader>ff', require('telescope.builtin').git_files, {})                 -- fuzzy find files in project
keymap.set('n', '<leader>fg', require('telescope.builtin').live_grep, {})                 -- grep file contents in project
keymap.set('n', '<leader>fb', require('telescope.builtin').buffers, {})                   -- fuzzy find open buffers
keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags, {})                 -- fuzzy find help tags
keymap.set('n', '<leader>fs', require('telescope.builtin').current_buffer_fuzzy_find, {}) -- fuzzy find in current file buffer
keymap.set('n', '<leader>fo', require('telescope.builtin').lsp_document_symbols, {})      -- fuzzy find LSP/class symbols
keymap.set('n', '<leader>fi', require('telescope.builtin').lsp_incoming_calls, {})        -- fuzzy find LSP/incoming calls
-- keymap.set('n', '<leader>fm', function() require('telescope.builtin').treesitter({default_text=":method:"}) end) -- fuzzy find methods in current class
keymap.set('n', '<leader>fm',
  function() require('telescope.builtin').treesitter({ symbols = { 'function', 'method' } }) end) -- fuzzy find methods in current class
keymap.set('n', '<leader>ft',
  function()                                                                                      -- grep file contents in current nvim-tree node
    local success, node = pcall(function() return require('nvim-tree.lib').get_node_at_cursor() end)
    if not success or not node then return end;
    require('telescope.builtin').live_grep({ search_dirs = { node.absolute_path } })
  end)

-- LSP
keymap.set('n', '<leader>gg', '<cmd>lua vim.lsp.buf.hover()<CR>')
keymap.set('n', '<leader>gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
keymap.set('n', '<leader>gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
keymap.set('n', '<leader>gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
keymap.set('n', '<leader>gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
keymap.set('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>')
keymap.set('n', '<leader>gs', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
keymap.set('n', '<leader>rr', '<cmd>lua vim.lsp.buf.rename()<CR>')
keymap.set('n', '<leader>gf', '<cmd>lua vim.lsp.buf.format({async = true})<CR>')
keymap.set('v', '<leader>gf', '<cmd>lua vim.lsp.buf.format({async = true})<CR>')
keymap.set('n', '<leader>ga', '<cmd>lua vim.lsp.buf.code_action()<CR>')
keymap.set('n', '<leader>gl', '<cmd>lua vim.diagnostic.open_float()<CR>')
keymap.set('n', '<leader>gp', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
keymap.set('n', '<leader>gn', '<cmd>lua vim.diagnostic.goto_next()<CR>')
keymap.set('n', '<leader>tr', '<cmd>lua vim.lsp.buf.document_symbol()<CR>')
keymap.set('i', '<C-Space>', '<cmd>lua vim.lsp.buf.completion()<CR>')
