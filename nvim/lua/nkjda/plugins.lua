-- nkjda/plugins.lua — plugin list (vim.pack) + plugin setups

vim.pack.add({
    { src = "https://github.com/j-hui/fidget.nvim" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main" },
    { src = "https://github.com/windwp/nvim-ts-autotag" },

    { src = "https://github.com/echasnovski/mini.nvim" },
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/ThePrimeagen/harpoon",                       version = "harpoon2" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/xeluxee/competitest.nvim" },
    { src = "https://github.com/MunifTanjim/nui.nvim" },
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
    { src = "https://github.com/L3MON4D3/LuaSnip" },
    { src = "https://github.com/Saghen/blink.cmp",                           version = vim.version.range("*") },
    { src = "https://github.com/dmtrKovalenko/fff" },
})

-- fff binary build on install/update
vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
        local name, kind = ev.data.spec.name, ev.data.kind
        if name == 'fff' and (kind == 'install' or kind == 'update') then
            if not ev.data.active then vim.cmd.packadd('fff') end
            require('fff.download').download_or_build_binary()
        end
    end,
})

vim.g.fff = {
    title = 'fff',
    prompt_vim_mode = false,
    prompt = '> ',
    lazy_sync = true,
    keymaps = { close = '<C-a>', cycle_grep_modes = '<C-s>' },
    git = { enabled = false, show_status = false, status_text_color = false },
    file_picker = {
        current_file_label = '(current)',
        fuzzy_query_highlighting = false,
    },
}

-- competitest (lazy-loaded on cpp FileType)
local competitest_loaded = false
local function load_competitest()
    if competitest_loaded then return end
    vim.cmd("packadd competitest.nvim")
    require("competitest").setup({
        companion_port = 27121,
        evaluate_template_modifiers = true,
        template_file = { cpp = "~/cf/templates/template.cpp" },
        received_contests_problems_path = "$(PROBLEM)/main.$(FEXT)",
    })
    competitest_loaded = true
end

-- expose for keymaps.lua
_G._nkjda_load_competitest = load_competitest

vim.api.nvim_create_autocmd("FileType", {
    pattern = "cpp",
    callback = function() load_competitest() end,
})

-- oil / fidget (harpoon is set up on first use, see keymaps.lua)

require("oil").setup({
    view_options = { show_hidden = true, natural_order = "fast" },
    columns = {},
    delete_to_trash = false,
    skip_confirm_for_simple_edits = true,
    prompt_save_on_select_new_entry = false,
    default_file_explorer = true,
    cleanup_delay_ms = 0,
    watch_for_changes = false,
    confirmation = { max_width = 0.4, max_height = 0.2, border = "rounded", win_options = { winblend = 0 } },
})

require("fidget").setup {
    progress = { suppress_on_insert = true, poll_rate = 0 },
    notification = {
        poll_rate = 5,
        window = { winblend = 0, normal_hl = "NormalFloat" },
    }
}

-- treesitter parsers (incl. html/xml for autotag) + highlight
-- install check is off the startup path; parsers already on disk are a no-op
vim.schedule(function() require("nvim-treesitter").install({
    "c", "cpp", "lua", "rust", "html", "xml",
    "javascript", "typescript", "vue", "astro", "svelte", "go", "http",
}) end)
vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "c", "cpp", "lua", "rust", "html", "xml",
        "javascript", "typescript", "javascriptreact", "typescriptreact",
        "vue", "astro", "svelte", "go", "http",
    },
    -- minified bundles (dist/*.js) block the editor ~0.5s per 800KB in the parser; skip them
    callback = function(ev)
        if vim.fn.getfsize(ev.file) > 512 * 1024 then return end
        vim.treesitter.start()
    end,
})

-- tag rename/close via treesitter
require("nvim-ts-autotag").setup()



-- mini.surround only (monorepo, don't setup other mini modules)
-- sa add, sd delete, sr replace (e.g. sr t div<CR> swaps both tags), sF/sf jump
require("mini.surround").setup()


