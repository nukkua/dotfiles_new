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

vim.lsp.config('ts_ls', {
  init_options = {
    plugins = { 
      {
        name = "@vue/typescript-plugin",
        location = "/usr/local/lib/node_modules/@vue/language-server",
        languages = { "vue" },
      },
    },
  },
  filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
})

vim.lsp.enable({'astro', 'clangd', 'zls', 'vtsls', 'ts_ls'})

