-- Themes
vim.cmd.colorscheme("quiet")
vim.opt.background = 'dark'

-- Config
vim.opt.mouse = ""
vim.wo.signcolumn = 'no'
vim.opt.guicursor = "n-v-sm:block"
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
vim.o.shada = [[!,'20,<50,s10,h]]
vim.opt.termguicolors = true
vim.opt.iskeyword:remove("-")

-- Zig
vim.g.zig_executable          = "/home/leverna/zig/"

-- Packer
local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.cmd('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
    vim.cmd 'packadd packer.nvim'
end

local config_path = vim.fn.stdpath('config')
package.path = config_path .. "/?.lua;" .. package.path
package.path = config_path .. "/?/init.lua;" .. package.path


-- Plugins
require('packer').startup(function(use)
    use('wbthomason/packer.nvim')
    use('j-hui/fidget.nvim')
    use 'AndrewRadev/tagalong.vim'
    use '0x100101/lab.nvim'
    use('tpope/vim-fugitive')
    use('tpope/vim-commentary')
    use ('stevearc/oil.nvim')
    use('nvim-tree/nvim-web-devicons')
    use "lifepillar/vim-solarized8"
    use {
        'nvim-telescope/telescope.nvim',
        requires = { 'nvim-lua/plenary.nvim' },
        config = function() require('plugins.telescope') end
    }
    use {
        'xeluxee/competitest.nvim',
        requires = 'MunifTanjim/nui.nvim',
        config = function() require('competitest').setup() end
    }
    use('folke/zen-mode.nvim')
    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'nvim-tree/nvim-web-devicons', opt = true },
    }
    use('theprimeagen/harpoon')
    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        requires = {
            { 'williamboman/mason.nvim', config = function() require('mason').setup({}) end },
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason-lspconfig.nvim',
            config = function() require('plugins.lsp') end
        },
        { 'hrsh7th/nvim-cmp' },
        { 'hrsh7th/cmp-nvim-lsp' },
        { 'hrsh7th/cmp-buffer' },
        { 'hrsh7th/cmp-path' },
        { 'saadparwaiz1/cmp_luasnip' },
        { 'L3MON4D3/LuaSnip' },
        { 'rafamadriz/friendly-snippets' },
    }
}
end)

-- requires
require 'keymappings'
require 'plugins.harpoon'
require 'plugins.cmp'
require 'plugins.competitest'

require("oil").setup({
    view_options = {
        show_hidden = true,
        natural_order = "fast",
    },
    columns = {},
    delete_to_trash = false,
    skip_confirm_for_simple_edits = true,
    prompt_save_on_select_new_entry = false,
    default_file_explorer = true,
    cleanup_delay_ms = 1000,
    watch_for_changes = true,
    confirmation = {
        max_width = 0.4,
        max_height = 0.2,
        border = "rounded",
        win_options = {
            winblend = 0,
        },
    },
})

require("fidget").setup {
    notification = {
        window = {
            winblend = 0,
            normal_hl = "NormalFloat",
        }
    }
}
vim.g.tagalong_filetypes = {
    'html',
    'xml',
    'javascriptreact',
    'typescriptreact',
    'astro',
    'vue',
}

vim.api.nvim_create_autocmd("FileType", {
    pattern = "astro",
    callback = function()
        vim.opt_local.iskeyword:remove("-")
    end,
})

vim.keymap.set("n", "<leader>d", function()
    local word = vim.fn.expand("<cword>")
    local ft = vim.bo.filetype

    local templates = {
        javascript = "console.log('%s:', %s);",
        typescript = "console.log('%s:', %s);",
        astro = "console.log('%s:', %s);",
        python = "print('%s:', %s)",
        lua = "print('%s:', %s)",
        rust = "println!(\"%s: {:?}\", %s);",
    }

    local template = templates[ft]
    if template then
        local line = string.format(template, word, word)
        vim.api.nvim_put({ line }, "l", true, true)
    else
        print("No template for filetype: " .. ft)
    end
end)


