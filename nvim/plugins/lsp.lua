local lsp = require('lsp-zero')

lsp.on_attach(function(client, bufnr)
    local opts = { buffer = bufnr, remap = false }
    --lsp.default_keymaps({buffer = bufnr})

    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
    vim.keymap.set('n', '<leader>e', vim.lsp.buf.format, opts)

    vim.keymap.set('n', '<leader>vd', function()
    end, opts)

    vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)


    vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
    vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
end)

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
        'ts_ls',
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
    },
    handlers = {
        lsp.default_setup
    }
})

local lspconfig = require('lspconfig')
lspconfig.volar.setup({
    filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
    init_options = {
        vue = {
            hybridMode = false,
        },
    },
})

lspconfig.astro.setup({})
require 'lspconfig'.intelephense.setup {
    filetypes = { "php", "blade" },
    settings = {
        intelephense = {
            files = {
                associations = { "*.php", "*.blade.php" },
            },
        },
    },
}
lspconfig.omnisharp.setup({})
lspconfig.dartls.setup({})
lspconfig.clangd.setup({
    init_options = {
        fallbackFlags = { '--std=c++26' }
    },

})
lspconfig.ts_ls.setup({})

lspconfig.zls.setup {}

local cmp = require('cmp')
local cmp_action = lsp.cmp_action()
local cmp_select = { behavior = cmp.SelectBehavior.Select }
cmp.setup({
    --	sources = {
    --		{ name = 'nvim_lsp' }
    --	},
    mapping = cmp.mapping.preset.insert({
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
        ['<Tab>'] = cmp.mapping.confirm({ select = true }),
        ['<C-Space>'] = cmp.mapping.complete()
    })
})
