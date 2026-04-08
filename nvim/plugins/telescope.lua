local ok, telescope = pcall(require, "telescope")
if not ok then return end
local actions = require("telescope.actions");
local actions_state = require("telescope.actions.state");

telescope.setup({
    defaults = {
        layout_config = { vertical = { width = 0.5, preview_cutoff = 0 } },
        file_ignore_patterns = { "node_modules", "dist" },
        mappings = {
            i = {
                ["<C-c>"] = function(prompt_bufnr)
                    vim.cmd("stopinsert")
                end,
            },
            n = {
                ["q"] = actions.close,
                ["go"] = actions.move_to_top,
            }
        }
    },
    pickers = {
        find_files = { previewer = true },
        live_grep = { previewer = true },
    }
})
