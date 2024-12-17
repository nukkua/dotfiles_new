local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("vue", {
	s("vss", {
		t({ "<template>", "\t<div>", "\t\t" }),
		i(0),
		t({ "", "\t</div>", "</template>", "", "<script setup lang=\"ts\">", "", "</script>", "",
			"<style scoped>", "", "</style>" })
	}),
})
ls.add_snippets("vue", {
	s("vdc", {
		t({ "import { defineComponent } from 'vue';", "export default defineComponent({", "\tprops: {", "\t\t" }),
		i(1, "value"), t({ ": { type: " }), i(2, "Number"), t({ ", default: " }), i(3, "0"), t({ ", required: " }),
		i(4, "true"), t({ " }", "", "\t},", "\tsetup(props) {", "", "\t\treturn {", "", "\t\t};", "", "\t},", "",
		"});" })
	}),
})
