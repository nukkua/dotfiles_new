-- init.lua — thin loader (refactored hybrid lean)
-- all logic lives in lua/nkjda/*

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("nkjda.options")
require("nkjda.plugins")
require("nkjda.autocmds")
require("nkjda.lsp")
require("nkjda.completion")
require("nkjda.keymaps")
