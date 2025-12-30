local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local M = {}

M.struct_snip = function(name)
	return s("dyn_struct", {
		t("struct " .. name .. " {"),
		t({ "", "    " }),
		i(0),
		t({ "", "}" })
	})
end

M.enum_snip = function(name)
	return s("dyn_enum", {
		t("enum " .. name .. " {"),
		t({ "", "    " }),
		i(0),
		t({ "", "}" })
	})
end

M.impl_snip = function(name)
	return s("dyn_impl", {
		t("impl " .. name .. " {"),
		t({ "", "    " }),
		i(0),
		t({ "", "}" })
	})
end

M.fn_snip = function(name)
	return s("dyn_fn", {
		t("fn " .. name .. "("),
		i(1),
		t({ ") {", "    " }),
		i(0),
		t({ "", "}" })
	})
end

return M
