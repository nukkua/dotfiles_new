require'nvim-web-devicons'.setup {
   default = '',
   symlink = '',
   git = {
      unstaged = "✗",
      staged = "✓",
      unmerged = "",
      renamed = "➜",
      untracked = "★",
      deleted = "",
      ignored = "◌"
   },
   folder = {
      arrow_open = "",
      arrow_closed = "",
      default = "",
      open = "",
      empty = "",
      empty_open = "",
      symlink = "",
      symlink_open = "",
   },
   lsp = {
      hint = "",
      info = "",
      warning = "",
      error = "",
  },
strict = true,
	override_by_extension = {
		astro = {
			icon = "",
			color = "#EF8547",
			name = "astro",
		},
	},
}


