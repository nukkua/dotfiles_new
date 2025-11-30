-- GENERAL
vim.opt.termguicolors = true


vim.o.shada = [[!,'20,<50,s10,h]]

vim.loader.enable() -- cache de módulos nativo
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider    = 0
vim.g.loaded_perl_provider    = 0
vim.g.loaded_node_provider    = 0

vim.g.zig_executable          = "/home/leverna/zig/"
vim.cmd("hi StatusLine guibg=none")
vim.opt.mouse = ""
vim.wo.signcolumn = 'no'
vim.opt.guicursor = "n-v-sm:block"
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

vim.cmd [[set background=dark]]
vim.cmd [[ hi Normal guibg=NONE ctermbg=NONE ]]
vim.cmd [[ hi NormalNC guibg=NONE ctermbg=NONE ]]
vim.cmd [[ hi VertSplit guibg=NONE ctermbg=NONE ]]
vim.cmd [[ hi EndOfBuffer guibg=NONE ctermbg=NONE ]]

vim.cmd [[highlight NvimTreeFolderIcon guifg=#FFC0CB]]
vim.cmd [[highlight NvimTreeFolderName guifg=#FFC0CB]]
vim.cmd [[highlight NvimTreeIndentMarker guifg=#FFC0CB]]
vim.cmd [[highlight NvimTreeFileRenamed guifg=#FFC0CB]]
vim.cmd [[highlight NvimTreeFileName guifg=#FFC0CB]]
vim.cmd [[highlight NvimTreeImageFile guifg=#FFC0CB]]
vim.cmd [[highlight NvimTreeSpecialFile guifg=#FFC0CB]]

vim.cmd('highlight NvimTreeNormal guibg=NONE')
vim.cmd('highlight NvimTreeNormalNC guibg=NONE')


-- LSP BASIC
local lsp_on_attach = function(_, bufnr)
    local opts = { buffer = bufnr, remap = false }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "(d", vim.diagnostic.goto_next, opts)
    vim.keymap.set("n", ")d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set('n', '<leader>le', function() vim.lsp.buf.format({ async = true }) end, opts)
end
_G.__nukkua_on_attach = lsp_on_attach



-- PACKER

local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.cmd('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
    vim.cmd 'packadd packer.nvim'
end

local config_path = vim.fn.stdpath('config')
package.path = config_path .. "/?.lua;" .. package.path
package.path = config_path .. "/?/init.lua;" .. package.path





require('packer').startup(function(use)
    use('wbthomason/packer.nvim')

    -- utilidades
    use('tpope/vim-commentary')
    use('nvim-tree/nvim-web-devicons')  -- actualizado org

    use {
        'nvim-telescope/telescope.nvim',
        requires = { 'nvim-lua/plenary.nvim' },
        config = function() require('plugins.telescope') end
    }

    use('folke/zen-mode.nvim')

    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        config = function() require('plugins.treesiter') end  -- <== corregido el nombre
    }
    use('nvim-treesitter/nvim-treesitter-context')

    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'nvim-tree/nvim-web-devicons', opt = true },
        config = function() require('plugins.lualine') end
    }

    use('theprimeagen/harpoon')

    -- LSP stack (lsp-zero v3)
    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        requires = {
            { 'williamboman/mason.nvim', config = function() require('mason').setup({}) end },
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason-lspconfig.nvim',
            config = function() require('plugins.lsp') end  
        },

        -- completion
        { 'hrsh7th/nvim-cmp' },
        { 'hrsh7th/cmp-nvim-lsp' },
        { 'hrsh7th/cmp-buffer' },
        { 'hrsh7th/cmp-path' },
        { 'saadparwaiz1/cmp_luasnip' },

        -- snippets
        { 'L3MON4D3/LuaSnip' },
        { 'rafamadriz/friendly-snippets' },
    }
}
end)




require 'colorsget'
require 'keymappings'
require 'plugins.lualine'
require 'plugins.harpoon'
require 'snippets.php'
require 'snippets.vue'
require 'snippets.react'
require 'snippets.astro'



local cmp = require 'cmp'
local cmp_select = { behavior = cmp.SelectBehavior.Select }

cmp.setup({
    snippet = {
        expand = function(args)
            require 'luasnip'.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-a>'] = cmp.mapping.abort(),
        ['<C-s>'] = cmp.mapping.confirm({ select = true }),
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'buffer' },
        { name = 'path' }
    })
})
