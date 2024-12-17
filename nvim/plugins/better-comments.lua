require('better-comment').Setup({
	tags = {
		{
			name = "TODO",
			fg = "white",
			bg = "#0a7aca",
			bold = true,
			virtual_text = "",
		},
		{
			name = "FIX",
			fg = "white",
			bg = "#f44747",
			bold = true,
			virtual_text = "This need a fix",
		},
		{
			name = "WARNING",
			fg = "#FFA500",
			bg = "",
			bold = false,
			virtual_text = "Warning",
		},
		{
			name = "!",
			fg = "#f44747",
			bg = "",
			bold = true,
			virtual_text = "",
		},

		{
			name = "NOTE",
			fg = "white",
			bg = "#800080",
			bold = true,
			virtual_text = "Notes!!",
		},
		{
			name = "REFS",
			fg = "white",
			bg = "#ff00ff",
			bold = true,
			virtual_text = "This is a reference",
		}

	}
})
