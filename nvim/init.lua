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
vim.g.mapleader      = " "

-- Zig
vim.g.zig_executable = "/home/leverna/zig/"

-- pack
vim.pack.add({
    { src = "https://github.com/j-hui/fidget.nvim" },
    { src = "https://github.com/AndrewRadev/tagalong.vim" },
    { src = "https://github.com/0x100101/lab.nvim" },
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
    { src = "https://github.com/nvim-telescope/telescope.nvim" },
    { src = "https://github.com/nvim-telescope/telescope-ui-select.nvim" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/xeluxee/competitest.nvim" },
    { src = "https://github.com/MunifTanjim/nui.nvim" },
    { src = "https://github.com/nvim-lualine/lualine.nvim" },
    { src = "https://github.com/ThePrimeagen/harpoon" },
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter",            version = "main" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects" },
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/L3MON4D3/LuaSnip" },
    { src = "https://github.com/VonHeikemen/lsp-zero.nvim" },
    { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
    { src = "https://github.com/hrsh7th/nvim-cmp" },
    { src = "https://github.com/hrsh7th/cmp-nvim-lsp" },
    { src = "https://github.com/hrsh7th/cmp-buffer" },
    { src = "https://github.com/hrsh7th/cmp-path" },
    { src = "https://github.com/saadparwaiz1/cmp_luasnip" },
    { src = "https://github.com/tpope/vim-commentary" },
})


local ok, telescope = pcall(require, "telescope")
if not ok then return end
local actions = require("telescope.actions");

telescope.setup({
    defaults = {
        layout_config = { vertical = { width = 0.5, preview_cutoff = 0 } },
        file_ignore_patterns = { "node_modules", "dist" },
        mappings = {
            i = {
                ["<C-c>"] = function(prompt_bufnr)
                    vim.cmd("stopinsert")
                end,
            },
            n = {
                ["<C-c>"] = actions.close,
                ["go"] = actions.move_to_top,
            }
        }
    },
    pickers = {
        find_files = { previewer = true },
        live_grep = { previewer = true },
    }
})

require('competitest').setup {
    companion_port = 27121,
    evaluate_template_modifiers = true,
    template_file = {
        cpp = "~/cf/templates/template.cpp"
    },
}

require("harpoon").setup({
    global_settings = {
        save_on_toggle = false,
        save_on_change = true,
        enter_on_sendcmd = false,
        tmux_autoclose_windows = false,
        excluded_filetypes = { "harpoon" },
        mark_branch = false,
        tabline = false,
        tabline_prefix = "   ",
        tabline_suffix = "   ",
    }
})

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

vim.keymap.set("n", "<leader>tt", function()
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




vim.opt.clipboard:append("unnamedplus")
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


vim.keymap.set({ "n", "v", "x" }, "<CR>", ":", { desc = "Self explanatory" })
vim.keymap.set({ "n", "v", "x" }, "<leader>n", ":norm ", { desc = "ENTER NORM COMMAND." })
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

vim.api.nvim_set_keymap('n', '<Space>f', "<CMD>Telescope find_files<CR>",
    { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>g', "<CMD>Telescope live_grep<CR>",
    { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>b', "<CMD>Telescope buffers<CR>",
    { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>j', "<CMD>noh<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>r', ":edit!<CR>", { noremap = true, silent = true })
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


local lsp = require('lsp-zero')
local cmp_lsp = require('cmp_nvim_lsp')

lsp.on_attach(function(_, bufnr)
    local opts = { buffer = bufnr, remap = false }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, opts)

    vim.keymap.set("n", ")d", function()
        vim.diagnostic.jump({
            count = 1,
            on_jump = function()
                vim.diagnostic.open_float(nil, { focus = false })
            end,
        })
    end, opts)

    vim.keymap.set("n", "(d", function()
        vim.diagnostic.jump({
            count = -1,
            on_jump = function()
                vim.diagnostic.open_float(nil, { focus = false })
            end,
        })
    end, opts)

    vim.keymap.set("n", "<leader>le", function()
        local ft = vim.bo[bufnr].filetype

        if ft == "astro" then
            vim.lsp.buf.format({
                async = true,
                filter = function(c)
                    return c.name == "astro"
                end,
            })
        else
            vim.lsp.buf.format({
                async = true,
                filter = function(c)
                    return c.name ~= "vtsls"
                end,
            })
        end
    end, opts)
end)

lsp.extend_lspconfig({
    capabilities = cmp_lsp.default_capabilities(),
})

require('mason').setup({})
require('mason-lspconfig').setup({
    ensure_installed = {
        'kotlin_language_server',
        'asm_lsp',
        'ltex',
        'htmx',
        'bashls',
        'emmet_ls',
        'graphql',
        'astro',
        'svelte',
        'gopls',
        'lua_ls',
        'rust_analyzer',
        'omnisharp',
        'ansiblels',
        'cssls',
        'dockerls',
        'docker_compose_language_service',
        'eslint',
        'html',
        'jsonls',
        'marksman',
        'taplo',
        'yamlls',
        'tailwindcss',
        'prismals',
        'sqlls',
        'cmake',
        'zls',
        'jqls',
        'intelephense',
        'pyright',
        'vue_ls',
        'vtsls',
    },
    handlers = {
        lsp.default_setup
    }
})

vim.lsp.config('clangd', {
    filetypes = { 'c', 'cpp' },
    fallbackFlags = { '--std=c++26' }
})

vim.lsp.config("vtsls", {
    filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue", "astro", "svelte" },
    settings = {
        vtsls = {
            tsserver = {
                globalPlugins = {
                    {
                        name = "@vue/typescript-plugin",
                        location = vim.fn.stdpath("data")
                            .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
                        languages = { "vue" },
                        configNamespace = "typescript",
                    },
                },
            },
        },
    },
})

vim.lsp.config("vue_ls", {})
vim.lsp.config("lua_ls", {})
vim.lsp.config("astro", {})
vim.lsp.config("svelte", {})
vim.lsp.config("eslint", {})
vim.lsp.config("rust_analyzer", {})
vim.lsp.config("tailwindcss", {})



vim.lsp.enable({ 'astro', 'clangd', 'zls', 'vtsls', 'lua_ls', 'svelte', 'vue_ls', 'vtsls', 'eslint', 'rust_analyzer',
    'tailwindcss' })

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
