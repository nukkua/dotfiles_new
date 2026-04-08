vim.opt.clipboard:append("unnamedplus")
vim.g.mapleader = " "
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = false

vim.keymap.set('i', '<C-c>', '<Esc>', { noremap = true })
vim.keymap.set('n', '<C-c>', '<Esc>', { noremap = true })
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set('n', '<leader>s', ':e #<CR>')
vim.keymap.set("n", "<leader>tn", "<C-w>j", { desc = "Go to next tab" })
vim.keymap.set("n", "<leader>ts", "<C-w>k", { desc = "Go to previous tab" })                        --  go to previous tab
vim.keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

vim.keymap.set("n", "-", "<CMD>Oil<CR>")

vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Open current buffer in new tab" }) 

vim.g.nvim_tree_highlight_opened_files = 1
vim.api.nvim_set_keymap('n', '<Space>w', ':w<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>q', ':q<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<Space>y', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<Space>y', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('x', '<Space>y', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>f', "<CMD>Telescope find_files<CR>",
    { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>g', "<CMD>Telescope live_grep<CR>",
    { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>n', "<CMD>Telescope buffers<CR>",
    { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>j', "<CMD>noh<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>r', "<CMD>e<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>h', "<CMD>Telescope help_tags<CR>",
    { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>o', "<CMD>Telescope oldfiles<CR>",
    { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>i', "<CMD>Telescope git_branches<CR>",
    { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>c', ':Commentary<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<Space>c', ':Commentary<CR>', { noremap = true, silent = true })

vim.keymap.set("n", ",,", ':lua require("harpoon.mark").add_file()<CR>')
vim.keymap.set("n", ",e", ':lua require("harpoon.ui").toggle_quick_menu()<CR>')
vim.keymap.set("n", ",s", ':lua require("harpoon.ui").nav_file(1)<CR>')
vim.keymap.set("n", ",n", ':lua require("harpoon.ui").nav_file(2)<CR>')
vim.keymap.set("n", ",t", ':lua require("harpoon.ui").nav_file(3)<CR>')
vim.keymap.set("n", ",r", ':lua require("harpoon.ui").nav_file(4)<CR>')
vim.keymap.set("n", ",w", ':lua require("harpoon.ui").nav_file(5)<CR>')

vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>ap", "<cmd>CompetiTest receive problem<CR>", { desc = "Receiving everything" })
vim.keymap.set("n", "<leader>ar", "<cmd>CompetiTest run<CR>", { desc = "run the problem" })
vim.keymap.set("n", "<leader>as", "<cmd>CompetiTest add_testcase<CR>", { desc = "run the problem" })
vim.opt.cursorline = false
vim.g.UltiSnipsExpandTrigger = '<tab>'
vim.g.UltiSnipsJumpForwardTrigger = '<tab>'
vim.g.UltiSnipsJumpBackwardTrigger = '<s-tab>'
vim.g.UltiSnipsEditSplit = 'vertical'

