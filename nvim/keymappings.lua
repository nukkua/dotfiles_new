vim.opt.clipboard:append("unnamedplus")

-- Spliting windows
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
-- New ctrl d and ctrl u
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.g.mapleader = " "

vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })                   -- split window vertically
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })                 -- split window horizontally
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })                    -- make split windows equal width & height
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })               -- close current split window

vim.keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })                     -- open new tab
vim.keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })              -- close current tab
vim.keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })                     --  go to next tab
vim.keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })                 --  go to previous tab
vim.keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

vim.g.nvim_tree_highlight_opened_files = 1


vim.api.nvim_set_keymap('n', '<Space>w', ':w<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<Space>q', ':q<CR>', { noremap = true, silent = true })

-- vim.api.nvim_set_keymap('n', '<Space>e', ':Neoformat<CR>', { noremap = true, silent = true })

-- vim.api.nvim_set_keymap('n', '<Space>f', ':Files<CR>', { noremap = true, silent = true })

-- vim.api.nvim_set_keymap('n', '<Space>g', ':Ag<CR>', { noremap = true, silent = true })


vim.api.nvim_set_keymap('n', '<Space>f', ":lua require('telescope.builtin').find_files()<CR>",
    { noremap = true, silent = true })

-- Buscar texto en el proyecto
vim.api.nvim_set_keymap('n', '<Space>g', ":lua require('telescope.builtin').live_grep()<CR>",
    { noremap = true, silent = true })

-- Cambiar entre buffers abiertos
vim.api.nvim_set_keymap('n', '<Space>b', ":lua require('telescope.builtin').buffers()<CR>",
    { noremap = true, silent = true })

-- Buscar en la ayuda de Neovim
vim.api.nvim_set_keymap('n', '<Space>h', ":lua require('telescope.builtin').help_tags()<CR>",
    { noremap = true, silent = true })

-- Buscar comandos recientes
vim.api.nvim_set_keymap('n', '<Space>r', ":lua require('telescope.builtin').command_history()<CR>",
    { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<Space>o', ":lua require('telescope.builtin').oldfiles()<CR>",
    { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<Space>i', ":lua require('telescope.builtin').git_branches()<CR>",
    { noremap = true, silent = true })

-- commentary
vim.api.nvim_set_keymap('n', '<Space>/', ':Commentary<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<Space>/', ':Commentary<CR>', { noremap = true, silent = true })


local options = { noremap = true, silent = true }


-- Mover líneas en modo normal
vim.api.nvim_set_keymap('n', '<C-j>', ':m .+1<CR>==', options)
vim.api.nvim_set_keymap('n', '<C-k>', ':m .-2<CR>==', options)

-- Mover líneas en modo insertar
vim.api.nvim_set_keymap('i', '<C-j>', '<Esc>:m .+1<CR>==gi', options)
vim.api.nvim_set_keymap('i', '<C-k>', '<Esc>:m .-2<CR>==gi', options)

-- Mover líneas en modo visual
vim.api.nvim_set_keymap('v', '<C-j>', ':m \'>+1<CR>gv=gv', options)
vim.api.nvim_set_keymap('v', '<C-k>', ':m \'<-2<CR>gv=gv', options)

-- harpoon

vim.keymap.set("n", ",,", ':lua require("harpoon.mark").add_file()<CR>')
vim.keymap.set("n", ",e", ':lua require("harpoon.ui").toggle_quick_menu()<CR>')

vim.keymap.set("n", ",a", ':lua require("harpoon.ui").nav_file(1)<CR>')
vim.keymap.set("n", ",s", ':lua require("harpoon.ui").nav_file(2)<CR>')
vim.keymap.set("n", ",d", ':lua require("harpoon.ui").nav_file(3)<CR>')
vim.keymap.set("n", ",f", ':lua require("harpoon.ui").nav_file(4)<CR>')

-- ':lua require("harpoon.ui").nav_next()'
-- ':lua require("harpoon.ui").nav_prev()'
-- vim.keymap.set("n", "<C-t>",)
-- vim.keymap.set("n", "<C-n>",)
-- vim.keymap.set("n", "<C-s>",)
-- vim.keymap.set("n", "<leader><C-h>",)
-- vim.keymap.set("n", "<leader><C-t>",)
-- vim.keymap.set("n", "<leader><C-n>",)
-- vim.keymap.set("n", "<leader><C-s>",)
-- others

vim.opt.relativenumber = true
vim.opt.number = true

-- Indentación
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

vim.opt.autoindent = true
vim.opt.smartindent = false


-- More info about diagnostic
vim.keymap.set('n', '<leader>pe', vim.diagnostic.open_float, { noremap = true, silent = true })

-- highlight line
vim.opt.cursorline = false

vim.g.UltiSnipsExpandTrigger = '<tab>'
vim.g.UltiSnipsJumpForwardTrigger = '<tab>'
vim.g.UltiSnipsJumpBackwardTrigger = '<s-tab>'
vim.g.UltiSnipsEditSplit = 'vertical'


-- laravel

vim.api.nvim_set_keymap(
    'n',
    '<leader>.q',
    ":lua vim.fn.system(\"xdg-open 'https://laravel.com/docs/10.x/queries'\")<CR>",
    { noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
    'n',
    '<leader>.v',
    ":lua vim.fn.system(\"xdg-open 'https://laravel.com/docs/11.x/validation'\")<CR>",
    { noremap = true, silent = true }
)
