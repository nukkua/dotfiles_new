require('competitest').setup {
	companion_port = 27121,
    evaluate_template_modifiers = true,
    template_file = {
        cpp = "~/cf/templates/template.cpp"
    },
}
