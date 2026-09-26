-- nkjda/completion.lua — blink.cmp + luasnip

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
    ["<C-g>"] = { "show_signature", "hide_signature", "fallback" },
    ["<Tab>"] = { "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "snippet_backward", "fallback" },
  },
  completion = {
    menu = { auto_show = false },
    documentation = { auto_show = false },
    list = { selection = { preselect = true, auto_insert = false } },
  },
  signature = { enabled = true, trigger = { enabled = false } },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
  snippets = { preset = "luasnip" },
  fuzzy = { implementation = "prefer_rust_with_warning" },
})

require("luasnip").setup({ enable_autosnippets = true })
require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/snippets/" })
