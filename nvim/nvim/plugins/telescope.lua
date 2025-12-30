local ok, telescope = pcall(require, "telescope")
if not ok then return end

telescope.setup({
    defaults = {
        layout_config = { vertical = { width = 0.5, preview_cutoff = 0 } },
        file_ignore_patterns = { "node_modules" },
    },
    pickers = {
        find_files = { previewer = true },
        live_grep = { previewer = true },
    }
})
