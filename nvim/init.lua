-- Themes
vim.cmd.colorscheme("quiet")
vim.opt.background = 'dark'

-- vim ui2
require('vim._core.ui2').enable({})

-- Config
vim.opt.lazyredraw = true
vim.opt.synmaxcol = 200

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
    { src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/xeluxee/competitest.nvim" },
    { src = "https://github.com/MunifTanjim/nui.nvim" },
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter",            version = "main" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects" },
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
    { src = "https://github.com/L3MON4D3/LuaSnip" },
    { src = "https://github.com/Saghen/blink.cmp",                           version = vim.version.range("*") },
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

local harpoon = require("harpoon")
harpoon:setup()

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
    function() require('fff').find_files({ query = 'git:modified' }) end,
    { desc = 'Git status' }
)

vim.keymap.set(
    'n',
    '<Space>be',
    function() require('fff').find_files({ query = 'git:staged' }) end,
    { desc = 'Git status' }
)


vim.api.nvim_set_keymap('n', '<Space>j', "<CMD>noh<CR>", { noremap = true, silent = true })
vim.keymap.set('n', '<Space>u', function()
    vim.cmd.packadd("nvim.undotree")
    require("undotree").open()
end, { desc = "Toggle builtin undotree" })

vim.api.nvim_set_keymap('n', '<Space>r', ":edit!<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>cc', ':Commentary<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<Space>cc', ':Commentary<CR>', { noremap = true, silent = true })

vim.keymap.set('n', 'n', 'nzz', { silent = true })
vim.keymap.set('n', 'N', 'Nzz', { silent = true })
vim.keymap.set('n', '*', '*zz', { silent = true })
vim.keymap.set('n', '#', '#zz', { silent = true })
vim.keymap.set('n', 'g*', 'g*zz', { silent = true })
vim.keymap.set('n', 'g#', 'g#zz', { silent = true })
vim.cmd([[cnoremap <CR> <CR><C-c>zz]])

vim.keymap.set("n", ",,", function() harpoon:list():add() end)
vim.keymap.set("n", ",e", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
vim.keymap.set("n", ",s", function() harpoon:list():select(1) end)
vim.keymap.set("n", ",n", function() harpoon:list():select(2) end)
vim.keymap.set("n", ",t", function() harpoon:list():select(3) end)
vim.keymap.set("n", ",r", function() harpoon:list():select(4) end)
vim.keymap.set("n", ",w", function() harpoon:list():select(5) end)
vim.keymap.set("n", ",m", function() harpoon:list():prev() end)
vim.keymap.set("n", ",h", function() harpoon:list():next() end)

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

local capabilities = require("blink.cmp").get_lsp_capabilities()
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
    root_markers = {
        ".luarc.json",
        ".luarc.jsonc",
        ".stylua.toml",
        "stylua.toml",
        "selene.toml",
        "selene.yml",
        ".git",
    },

    settings = {
        Lua = {
            workspace = {
                checkThirdParty = false,
            },
        },
    },
})

vim.lsp.config("rust_analyzer", {
    capabilities = capabilities,
    settings = {
        ["rust-analyzer"] = {
            checkOnSave = false,

            cargo = {
                allFeatures = false,
                loadOutDirsFromCheck = false,
            },
            files = {
                excludeDirs = {
                    ".git",
                    "target",
                    "node_modules",
                },
            },
            diagnostics = {
                enable = true,
            },
        },
    },
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

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp" },
    callback = function()
        vim.lsp.enable("clangd")
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "lua",
    callback = function()
        vim.lsp.enable("lua_ls")
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "rust",
    callback = function()
        vim.lsp.enable("rust_analyzer")
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "zig", "zir" },
    callback = function()
        vim.lsp.enable("zls")
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "astro",
    callback = function()
        vim.lsp.enable("astro")
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "svelte",
    callback = function()
        vim.lsp.enable("svelte")
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "vue" },
    callback = function()
        vim.lsp.enable("vue_ls")
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "html",
        "css",
        "scss",
        "javascriptreact",
        "typescriptreact",
        "vue",
        "astro",
        "svelte",
    },
    callback = function()
        vim.lsp.enable("tailwindcss")
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "javascript",
        "typescript",
        "javascriptreact",
        "typescriptreact",
        "vue",
    },
    callback = function()
        vim.lsp.enable("vtsls")
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "javascript",
        "typescript",
        "javascriptreact",
        "typescriptreact",
        "vue",
        "svelte",
        "astro",
    },
    callback = function()
        vim.lsp.enable("eslint")
    end,
})


require("blink.cmp").setup({
    keymap = {
        preset = "none",
        ["<C-e>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-a>"] = { "hide" },
        ["<C-s>"] = { "accept" },

        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },

        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
    },

    completion = {
        menu = {
            auto_show = false,
        },
        documentation = {
            auto_show = false,
        },
        list = {
            selection = {
                preselect = true,
                auto_insert = false,
            },
        },
    },

    sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
            buffer = {
                opts = {
                    get_bufnrs = function()
                        return { vim.api.nvim_get_current_buf() }
                    end,
                },
            },
        },
    },

    snippets = {
        preset = "luasnip",
    },

    fuzzy = {
        implementation = "prefer_rust_with_warning",
    },
})

require("luasnip").setup({ enable_autosnippets = true })
require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/snippets/" })

vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.md",
    callback = function()
        local file = vim.fn.expand("%:p")
        local pdf = vim.fn.expand("%:p:r") .. ".pdf"

        vim.fn.jobstart({ "pandoc", file, "-o", pdf }, { detach = true })
    end,
})

vim.keymap.set("n", "<leader>mp", function()
    local pdf = vim.fn.expand("%:p:r") .. ".pdf"
    vim.fn.jobstart({ "zathura", pdf }, { detach = true })
end, { desc = "Open Markdown PDF in Zathura" })


vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "VimEnter" }, {
    callback = function()
        if vim.w.git_conflict_matches then
            return
        end

        vim.w.git_conflict_matches = {
            vim.fn.matchadd("ConflictMarker", [[^<<<<<<< .*$]]),
            vim.fn.matchadd("ConflictMarker", [[^=======$]]),
            vim.fn.matchadd("ConflictMarker", [[^>>>>>>> .*$]]),
        }
    end,
})

vim.api.nvim_create_user_command("JsonToTs", function()
    local name = vim.fn.input("Type name: ")
    if name == "" then name = "Root" end

    local cmd = "xclip -selection clipboard -o | quicktype --lang ts --top-level " .. vim.fn.shellescape(name)
    local output = vim.fn.systemlist(cmd)

    if vim.v.shell_error ~= 0 then
        vim.notify(table.concat(output, "\n"), vim.log.levels.ERROR)
        return
    end

    vim.api.nvim_put(output, "l", true, true)
end, {})

require("intro");
require("lsp_idle").setup()
local disabled_built_ins = {
    "gzip",
    "zip",
    "zipPlugin",
    "tar",
    "tarPlugin",
    "getscript",
    "getscriptPlugin",
    "vimball",
    "vimballPlugin",
    "2html_plugin",
    "logipat",
    "rrhelper",
    "spellfile_plugin",
}

for _, plugin in pairs(disabled_built_ins) do
    vim.g["loaded_" .. plugin] = 1
end
