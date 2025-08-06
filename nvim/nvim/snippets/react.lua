local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local rep = require("luasnip.extras").rep

local snippets = {
    s("rafce", {
        t({ "export const " }), i(1, "ComponentName"), t({ " = () => {", "\treturn (", "\t\t<div>", "\t\t\t" }),
        i(0),
        t({ "", "\t\t</div>", "\t);", "};" })
    }),
    s("rnfc", {
        t({ "import React from 'react';", "import { View, Text, StyleSheet } from 'react-native';", "", "const " }),
        i(1, "ComponentName"),
        t({ " = () => {", "\treturn (", "\t\t<View>", "\t\t\t" }),
        i(0),
        t({ "", "\t\t</View>", "\t);", "};", "", "export default " }),
        rep(1),
        t({ ";" })
    }),
}

-- Añadir snippets para JavaScript, JavaScript React y TypeScript React
ls.add_snippets("javascript", snippets)
ls.add_snippets("javascriptreact", snippets)
ls.add_snippets("typescriptreact", snippets)
