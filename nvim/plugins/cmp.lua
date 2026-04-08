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
