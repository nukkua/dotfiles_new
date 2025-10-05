vim.opt.clipboard:append("unnamedplus")

-- Spliting windows
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.keymap.set('i', '<C-c>', '<Esc>', { noremap = true })
vim.keymap.set('n', '<C-c>', '<Esc>', { noremap = true })
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
-- New ctrl d and ctrl u
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.g.mapleader = " "
vim.keymap.set('n', '<leader>s', ':e #<CR>')

-- vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })      -- split window vertically
-- vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })    -- split window horizontally
-- vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })       -- make split windows equal width & height
-- vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })  -- close current split window

-- vim.keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })        -- open new tab
-- vim.keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
-- vim.keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })                     --  go to next tab
-- vim.keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })                 --  go to previous tab
vim.keymap.set("n", "<leader>tn", "<C-w>j", { desc = "Go to next tab" })                            --  go to next tab
vim.keymap.set("n", "<leader>tp", "<C-w>k", { desc = "Go to previous tab" })                        --  go to previous tab
vim.keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

vim.keymap.set("n", "<leader>e", vim.cmd.Ex)

vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

vim.g.nvim_tree_highlight_opened_files = 1


vim.api.nvim_set_keymap('n', '<Space>w', ':w<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<Space>q', ':q<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<Space>y', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<Space>y', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('x', '<Space>y', '"+y', { noremap = true, silent = true })



vim.api.nvim_set_keymap('n', '<Space>f', "<CMD>Telescope find_files<CR>",
    { noremap = true, silent = true })

-- Buscar texto en el proyecto
vim.api.nvim_set_keymap('n', '<Space>g', "<CMD>Telescope live_grep<CR>",
    { noremap = true, silent = true })

-- Cambiar entre buffers abiertos
vim.api.nvim_set_keymap('n', '<Space>b', "<CMD>Telescope buffers<CR>",
    { noremap = true, silent = true })

-- Buscar en la ayuda de Neovim
vim.api.nvim_set_keymap('n', '<Space>h', "<CMD>Telescope help_tags<CR>",
    { noremap = true, silent = true })

-- Buscar comandos recientes
vim.api.nvim_set_keymap('n', '<Space>r', "<CMD>Telescope command_history<CR>",
    { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<Space>o', "<CMD>Telescope oldfiles<CR>",
    { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<Space>i', "<CMD>Telescope git_branches<CR>",
    { noremap = true, silent = true })

-- commentary
vim.api.nvim_set_keymap('n', '<Space>/', ':Commentary<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<Space>/', ':Commentary<CR>', { noremap = true, silent = true })


local options = { noremap = true, silent = true }


-- harpoon

vim.keymap.set("n", ",,", ':lua require("harpoon.mark").add_file()<CR>')
vim.keymap.set("n", ",e", ':lua require("harpoon.ui").toggle_quick_menu()<CR>')

vim.keymap.set("n", ",s", ':lua require("harpoon.ui").nav_file(1)<CR>')
vim.keymap.set("n", ",n", ':lua require("harpoon.ui").nav_file(2)<CR>')
vim.keymap.set("n", ",t", ':lua require("harpoon.ui").nav_file(3)<CR>')
vim.keymap.set("n", ",r", ':lua require("harpoon.ui").nav_file(4)<CR>')
vim.keymap.set("n", ",w", ':lua require("harpoon.ui").nav_file(5)<CR>')

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
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { noremap = true, silent = true })

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



local function format_with_black()
    local bufnr = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(bufnr)
    if not file:match('%.py$') then return end

    local black = vim.fn.getcwd() .. '/venv/bin/black'
    -- local black = '/usr/bin/black'

    if vim.fn.executable(black) == 0 then
        vim.notify("black no encontrado en " .. black, vim.log.levels.ERROR)
        return
    end

    -- guardar antes
    vim.cmd('write')

    vim.fn.jobstart({ black, file }, {
        on_exit = function(_, code)
            if code == 0 then
                local view = vim.fn.winsaveview()
                vim.cmd('edit')
                vim.fn.winrestview(view)
                vim.notify("Formatted with Black!", vim.log.levels.INFO)
            else
                vim.notify("Black Error!" .. tostring(code), vim.log.levels.ERROR)
            end
        end,
    })
end

vim.keymap.set('n', '<leader>bl', format_with_black, { desc = "Formatear Python con black manual" })
