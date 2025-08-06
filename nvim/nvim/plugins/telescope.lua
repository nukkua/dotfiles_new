require('telescope').setup({
	defaults = {
		layout_config = {
			vertical = { width = 0.5, preview_cutoff = 0 },
		},
		file_ignore_patterns = { "node_modules" },
	},
	pickers = {
		find_files = {
			previewer = true,
		},
		live_grep = {
			previewer = true,
		},
	},
})
