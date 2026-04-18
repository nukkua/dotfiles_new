-- Themes
vim.cmd.colorscheme("quiet")
vim.opt.background = 'dark'

-- vim ui2
require('vim._core.ui2').enable({})

-- Config
vim.loader.enable()
vim.opt.mouse         = ""
vim.wo.signcolumn     = 'no'
vim.opt.guicursor     = "n-v-sm:block"
vim.g.netrw_banner    = 0
vim.g.netrw_winsize   = 25
vim.o.shada           = [[!,'20,<50,s10,h]]
vim.opt.termguicolors = true
vim.g.mapleader       = " "

vim.g.zig_executable  = "/home/leverna/zig/"

-- pack
vim.pack.add({
    { src = "https://github.com/j-hui/fidget.nvim" },
    { src = "https://github.com/AndrewRadev/tagalong.vim" },
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/xeluxee/competitest.nvim" },
    { src = "https://github.com/MunifTanjim/nui.nvim" },
    { src = "https://github.com/ThePrimeagen/harpoon" },
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter",            version = "main" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects" },
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
    { src = "https://github.com/hrsh7th/nvim-cmp" },
    { src = "https://github.com/hrsh7th/cmp-nvim-lsp" },
    { src = "https://github.com/hrsh7th/cmp-buffer" },
    { src = "https://github.com/hrsh7th/cmp-path" },
    { src = "https://github.com/saadparwaiz1/cmp_luasnip" },
    { src = "https://github.com/L3MON4D3/LuaSnip" },
    { src = "https://github.com/tpope/vim-commentary" },
    { src = "https://github.com/dmtrKovalenko/fff.nvim" },
})

vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
        local name, kind = ev.data.spec.name, ev.data.kind
        if name == 'fff.nvim' and (kind == 'install' or kind == 'update') then
            if not ev.data.active then
                vim.cmd.packadd('fff.nvim')
            end
            require('fff.download').download_or_build_binary()
        end
    end,
})

vim.g.fff = {
    title = 'fff',
    prompt = '> ',
    lazy_sync = true,
    debug = {
        enabled = false,
        show_scores = false,
    },
    layout = {
        show_scrollbar = false,
    },
    preview = {
        enabled = false,
    },
    keymaps = {
        close = '<C-c>',
        cycle_grep_modes = '<C-s>',
    },
    git = {
        enabled = false,
        show_status = false,
    }
}

do
    local git_utils = require('fff.git_utils')
    git_utils.should_show_border = function(_)
        return false
    end
end

local competitest_loaded = false
local function load_competitest()
    if competitest_loaded then
        return
    end

    vim.cmd("packadd competitest.nvim")

    require("competitest").setup({
        companion_port = 27121,
        evaluate_template_modifiers = true,
        template_file = {
            cpp = "~/cf/templates/template.cpp",
        },
    })

    competitest_loaded = true
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "cpp",
    callback = function()
        load_competitest()
    end,
})


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
    cleanup_delay_ms = 0,
    watch_for_changes = false,
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
    progress = {
        suppress_on_insert = true,
        poll_rate = 0,
    },
    notification = {
        pool_rate = 5,
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

vim.keymap.set(
    'n',
    '<Space>f',
    function() require('fff').find_files() end,
    { desc = 'FFFind files' }
)

vim.keymap.set(
    'n',
    '<Space>g',
    function() require('fff').live_grep() end,
    { desc = 'Live grep' }
)

vim.keymap.set(
    'n',
    '<Space>ba',
    function() require('fff').find_files({ query = 'git:modified'}) end,
    { desc = 'Git status' }
)

vim.keymap.set(
    'n',
    '<Space>be',
    function() require('fff').find_files({ query = 'git:staged'}) end,
    { desc = 'Git status' }
)


vim.api.nvim_set_keymap('n', '<Space>j', "<CMD>noh<CR>", { noremap = true, silent = true })
vim.keymap.set('n', '<Space>u', function()
    vim.cmd.packadd("nvim.undotree")
    require("undotree").open()
end, {desc = "Toggle builtin undotree"})

vim.api.nvim_set_keymap('n', '<Space>r', ":edit!<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>cc', ':Commentary<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<Space>cc', ':Commentary<CR>', { noremap = true, silent = true })

vim.keymap.set("n", ",,", ':lua require("harpoon.mark").add_file()<CR>')
vim.keymap.set("n", ",e", ':lua require("harpoon.ui").toggle_quick_menu()<CR>')
vim.keymap.set("n", ",s", ':lua require("harpoon.ui").nav_file(1)<CR>')
vim.keymap.set("n", ",n", ':lua require("harpoon.ui").nav_file(2)<CR>')
vim.keymap.set("n", ",t", ':lua require("harpoon.ui").nav_file(3)<CR>')
vim.keymap.set("n", ",r", ':lua require("harpoon.ui").nav_file(4)<CR>')
vim.keymap.set("n", ",w", ':lua require("harpoon.ui").nav_file(5)<CR>')

vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>ap", function()
    load_competitest()
    vim.cmd("CompetiTest receive problem")
end, { desc = "Receive problem" })
vim.keymap.set("n", "<leader>ar", "<cmd>CompetiTest run<CR>", { desc = "run the problem" })
vim.keymap.set("n", "<leader>as", "<cmd>CompetiTest add_testcase<CR>", { desc = "run the problem" })
vim.opt.cursorline = false
vim.g.UltiSnipsExpandTrigger = '<tab>'
vim.g.UltiSnipsJumpForwardTrigger = '<tab>'
vim.g.UltiSnipsJumpBackwardTrigger = '<s-tab>'
vim.g.UltiSnipsEditSplit = 'vertical'

local capabilities = require("cmp_nvim_lsp").default_capabilities()
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local bufnr = args.buf
        local opts = { buffer = bufnr, remap = false }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)

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
            vim.lsp.buf.format({
                async = true,
                filter = function(client)
                    if ft == "astro" then
                        return client.name == "astro"
                    end
                    if client.name == "vtsls" then
                        return false
                    end
                    return true
                end,
            })
        end, opts)
    end,
})

require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = {
        "clangd",
        "lua_ls",
        "eslint",
        "rust_analyzer",
        "zls",
        "vtsls",
        "vue_ls",
        "astro",
        "svelte",
        "tailwindcss",
    },
    automatic_enable = false,
})

vim.lsp.config("clangd", {
    capabilities = capabilities,
    filetypes = { "c", "cpp" },
    fallbackFlags = { "--std=c++26" },
})

vim.lsp.config("lua_ls", {
    capabilities = capabilities,
})

vim.lsp.config("rust_analyzer", {
    capabilities = capabilities,
})

vim.lsp.config("zls", {
    capabilities = capabilities,
})

vim.lsp.config("astro", {
    capabilities = capabilities,
})

vim.lsp.config("svelte", {
    capabilities = capabilities,
})

vim.lsp.config("vue_ls", {
    capabilities = capabilities,
})

vim.lsp.config("tailwindcss", {
    capabilities = capabilities,
})

vim.lsp.config("vtsls", {
    capabilities = capabilities,
    filetypes = {
        "typescript",
        "javascript",
        "javascriptreact",
        "typescriptreact",
        "vue",
    },
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

vim.lsp.enable({
    "clangd",
    "lua_ls",
    "rust_analyzer",
    "zls",
    "vtsls",
    "vue_ls",
    "astro",
    "svelte",
    "tailwindcss",
    "eslint",
})

require('mason').setup({})
local cmp = require 'cmp'
local cmp_select = { behavior = cmp.SelectBehavior.Select }
cmp.setup({
    performance = {
        debounce = 0,
        throttle = 0,
        fetching_timeout = 120,
        async_budget = 8,
        max_view_entries = 20,
    },
    completion = {
        keyword_length = 2,
        autocomplete = false,
    },
    snippet = {
        expand = function(args)
            require 'luasnip'.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-e>'] = cmp.mapping.complete(),
        ['<C-a>'] = cmp.mapping.abort(),
        ['<C-s>'] = cmp.mapping.confirm({ select = false }),
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
    }),
    sources = cmp.config.sources({
        { name = "nvim_lsp", keyword_length = 2 },
        { name = "path" },
        { name = "luasnip" },
        {
            name = "buffer",
            keyword_length = 5,
            option = {
                get_bufnrs = function()
                    return { vim.api.nvim_get_current_buf() }
                end,
            },
        },
    }),
})


require("luasnip").setup({ enable_autosnippets = true })
require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/snippets/" })
