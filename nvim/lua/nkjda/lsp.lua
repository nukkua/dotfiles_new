-- nkjda/lsp.lua — LSP, mason, diagnostics keymaps (buffer-local stays here)

local capabilities = require("blink.cmp").get_lsp_capabilities()
vim.lsp.config("*", { capabilities = capabilities })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local opts = { buffer = bufnr, remap = false }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", ")d", function()
      vim.diagnostic.jump({ count = 1, on_jump = function() vim.diagnostic.open_float(nil, { focus = false }) end })
    end, opts)
    vim.keymap.set("n", "(d", function()
      vim.diagnostic.jump({ count = -1, on_jump = function() vim.diagnostic.open_float(nil, { focus = false }) end })
    end, opts)
    vim.keymap.set("n", "<leader>ci", vim.lsp.buf.incoming_calls, opts)
    -- gO default opens a location list; force quickfix so <C-j>n/s work on it
    vim.keymap.set("n", "gO", function() vim.lsp.buf.document_symbol({ loclist = false }) end, opts)
    vim.keymap.set("n", "<leader>le", function()
      local ft = vim.bo[bufnr].filetype
      vim.lsp.buf.format({
        async = true,
        filter = function(client)
          if ft == "astro" then return client.name == "astro" end
          if client.name == "vtsls" then return false end
          return true
        end,
      })
    end, opts)
  end,
})

require("mason").setup()
-- ensure_installed walks the registry; do it after the first screen
vim.schedule(function() require("mason-lspconfig").setup({
  ensure_installed = {
    "clangd", "lua_ls", "eslint", "rust_analyzer", "zls",
    "vtsls", "vue_ls", "tailwindcss", "gopls",
  },
  automatic_enable = false,
}) end)

-- lspconfig's tailwindcss turns on file watching; without inotifywait nvim falls back to a
-- synchronous recursive scan (node_modules included) that freezes the editor for ~1.3s per open
-- with inotify-tools installed the watch runs in a separate process, so keep it on
if vim.fn.executable("inotifywait") == 0 then
  vim.lsp.config("tailwindcss", {
    capabilities = { workspace = { didChangeWatchedFiles = { dynamicRegistration = false } } },
  })
end

vim.lsp.config("clangd", { init_options = { fallbackFlags = { "-std=c++23" } } })

vim.lsp.config("lua_ls", {
  root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml", ".git" },
  settings = { Lua = { workspace = { checkThirdParty = false } } },
})

vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = false,
      cargo = { allFeatures = false, loadOutDirsFromCheck = false },
      files = { excludeDirs = { ".git", "target", "node_modules" } },
      diagnostics = { enable = true },
    },
  },
})

vim.lsp.config("vtsls", {
  filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
  settings = {
    typescript = {
      -- no second "syntax" tsserver (~240MB) and no typingsInstaller (~100MB, npm fetches @types)
      tsserver = { useSyntaxServer = "never" },
      disableAutomaticTypeAcquisition = true,
    },
    vtsls = {
      tsserver = {
        globalPlugins = {
          {
            name = "@vue/typescript-plugin",
            location = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
            languages = { "vue" },
            configNamespace = "typescript",
          },
        },
      },
    },
  },
})

vim.lsp.enable({
  "clangd", "lua_ls", "eslint", "rust_analyzer", "zls",
  "vtsls", "vue_ls", "tailwindcss", "gopls",
})

