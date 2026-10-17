-- nkjda/options.lua — global options, UI, theme, disabled built-ins
require('vim._core.ui2').enable({})

vim.loader.enable()

-- interactive latency: snappier mapped-sequence + CursorHold response
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.ttimeoutlen = 10
vim.opt.synmaxcol = 200
vim.opt.inccommand = "split"
vim.opt.isfname:append("@-@")
vim.opt.autoread = true
vim.opt.mouse = ""
vim.wo.signcolumn = 'no'
vim.opt.guicursor = "n-v-sm:block"
vim.opt.laststatus = 3
vim.opt.sessionoptions:append("globals")
vim.o.shada = [[!,'20,<50,s10,h]]
vim.opt.termguicolors = true
vim.opt.background = "dark"

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.o.cmdheight = 0

vim.opt.clipboard:append("unnamedplus")
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = false
vim.opt.cursorline = false

vim.cmd.colorscheme("quiet")

-- disable unused built-in plugins
local disabled_built_ins = {
  "gzip", "zip", "zipPlugin", "tar", "tarPlugin",
  "getscript", "getscriptPlugin", "vimball", "vimballPlugin",
  "2html_plugin", "logipat", "rrhelper", "spellfile_plugin",
}
for _, plugin in pairs(disabled_built_ins) do
  vim.g["loaded_" .. plugin] = 1
end
