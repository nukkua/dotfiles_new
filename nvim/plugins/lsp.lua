local lsp = require('lsp-zero')

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
        'pyright',
    },
    handlers = {
        lsp.default_setup
    }
})

local lspconfig = require('lspconfig')

lspconfig.pyright.setup({
    on_attach = on_attach_common,
})

lspconfig.astro.setup({})
lspconfig.intelephense.setup {
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
lspconfig.astro.setup({})


