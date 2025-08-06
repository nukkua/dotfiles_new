-- Asegúrate de que packer esté instalado
local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.cmd('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
    vim.cmd 'packadd packer.nvim'
end

vim.g.copilot_proxy = 'https://localhost:11435'
vim.g.copilot_proxy_strict_ssl = false


-- Tabbing
local config_path = vim.fn.stdpath('config')
package.path = config_path .. "/?.lua;" .. package.path
package.path = config_path .. "/?/init.lua;" .. package.path


vim.opt.termguicolors = true

require('packer').startup(function(use)
    use('wbthomason/packer.nvim')
    use {
        'xeluxee/competitest.nvim',
        requires = 'MunifTanjim/nui.nvim',
        config = function() require('competitest').setup() end
    }
    -- use('jwalton512/vim-blade')
    use("Djancyp/better-comments.nvim")
    use('sbdchd/neoformat')
    use('tpope/vim-commentary')
    use('kyazdani42/nvim-web-devicons')
    use('MaxMEllon/vim-jsx-pretty')
    use('mattn/emmet-vim')
    use('machakann/vim-sandwich')
    use {
        'nvim-telescope/telescope.nvim',
        requires = { 'nvim-lua/plenary.nvim' }
    }
    use("folke/zen-mode.nvim")
    use('nvim-treesitter/nvim-treesitter', { run = ':TSUpdate' })
    use('nvim-treesitter/playground')
    use('theprimeagen/harpoon')
    use('mbbill/undotree')
    use('tpope/vim-fugitive')
    use('nvim-treesitter/nvim-treesitter-context')
    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'nvim-tree/nvim-web-devicons', opt = true }
    }

    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        requires = {
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },
            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },
        }
    }

    use {
        "windwp/nvim-autopairs",
        config = function() require("nvim-autopairs").setup {} end
    }
end)
-- Para no tener scrollbar
vim.wo.signcolumn = 'no'
-- Cursor
vim.opt.guicursor = "n-v-sm:block"
-- netrw
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
-- vim.cmd[[colorscheme tokyonight]]
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
vim.cmd([[
  autocmd BufNewFile,BufRead *.blade.php set filetype=php
]])

vim.cmd('highlight NvimTreeNormal guibg=NONE')
vim.cmd('highlight NvimTreeNormalNC guibg=NONE')
vim.cmd [[let g:user_emmet_leader_key='<C-y>']]

require 'colorsget'
require 'keymappings'
require 'plugins.lualine'
require 'plugins.undotree'
require 'plugins.webdevicons'
require 'plugins.treesiter'
require 'plugins.lsp'
require 'plugins.better-comments'
require 'plugins.harpoon'
require 'snippets.php'
require 'snippets.vue'
require 'snippets.react'
require 'snippets.astro'
require 'plugins.telescope'



local cmp = require 'cmp'

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
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Acepta la selección con Enter
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'buffer' },
        { name = 'path' }
    })
})

-- Configuración de autopairs para trabajar con nvim-cmp
local autopairs = require('nvim-autopairs')
autopairs.setup({
    check_ts = true,
    ts_config = {
        -- lista de lenguajes que quieres soportar
    },
    disable_filetype = { "TelescopePrompt" },
    fast_wrap = {
        map = '<M-e>',
        chars = { '{', '[', '(', '"', "'" },
        pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], '%s+', ''),
        offset = 0, -- Desplazamiento desde el carácter actual
        end_key = '$',
        keys = 'qwertyuiopzxcvbnmasdfghjkl',
        check_comma = true,
        highlight = 'Search',
        highlight_grey = 'Comment'
    },
})

-- Zig
vim.g.zig_executable = "/home/leverna/zig/"

-- Integrar nvim-autopairs con nvim-cmp
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
cmp.event:on(
    'confirm_done',
    cmp_autopairs.on_confirm_done({ map_char = { tex = '' } })
)
require('competitest').setup() -- to use default configuration

vim.cmd("hi StatusLine guibg=none")
vim.opt.mouse = ""
