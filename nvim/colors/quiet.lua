vim.opt.termguicolors = true
vim.o.background = "dark"

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "quiet"


local set = vim.api.nvim_set_hl

set(0, "Normal", { fg = "#dddddd", bg = "NONE" })
set(0, "Identifier", { fg = "#dddddd" })
set(0, "Special", { fg = "#dddddd", bold = true })
set(0, "Statement", { fg = "#dddddd" })
set(0, "Type", { fg = "#dddddd" })
set(0, "Function", { fg = "#eeeeee" })
set(0, "String", { fg = "#dddddd" })
set(0, "Number", { fg = "#dddddd" })

set(0, "Keyword", { bold = true })
set(0, "Comment", { italic = true, fg = "#777777"})
set(0, "Constant", { fg = "#999999" })
set(0, "NormalFloat", { fg = "#dddddd", bg = "NONE" })
set(0, "FloatBorder", { fg = "#555555", bg = "NONE" })
set(0, "NormalNC", { bg = "NONE" })
set(0, "LineNr", { fg = "#555555", bg = "NONE" })
set(0, "CursorLineNr", { fg = "#dddddd", bg = "NONE" })
set(0, "SignColumn", { bg = "NONE" })
set(0, "FoldColumn", { bg = "NONE" })
set(0, "WinSeparator", { fg = "#333333", bg = "NONE" })
set(0, "StatusLineNC", { bg = "NONE" })

set(0, "@keyword", { bold = true })
set(0, "@keyword.function", { bold = true })
set(0, "@keyword.operator", { bold = true })

set(0, "@lsp.type.keyword", { fg = "#dddddd" })
set(0, "@lsp.type.keyword.zig", { fg = "#dddddd" })
set(0, "@lsp.type.keyword.zig.return", { fg = "#dddddd" })

set(0, "@comment", { italic = true, fg = "#777777" })

set(0, "@constant", { fg = "#999999" })
set(0, "@constant.builtin", { fg = "#999999" })
set(0, "@number", { fg = "#999999" })
set(0, "@boolean", { fg = "#999999" })
set(0, "@string", { fg = "#dddddd" })

set(0, "Pmenu", { bg = "NONE" })
set(0, "PmenuSel", { bg = "#222222" })
set(0, "PmenuSbar", { bg = "NONE" })
set(0, "PmenuThumb", { bg = "#555555" })

-- Quickfix: sakura filenames + subtle active-row cue inside qf window
set(0, "qfFileName", { fg = "#ffb6c1" })
set(0, "QuickFixLine", { fg = "#ffb6c1", bg = "NONE", bold = true })
set(0, "QuickFixCursorLine", { fg = "#ffb6c1", bg = "NONE" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.wo.cursorline = true
    vim.wo.winhl = "CursorLine:QuickFixCursorLine"
  end,
})

set(0, "Search",    { fg = "#d8d8d8", bg = "NONE", underline = true })
set(0, "ConflictMarker", { fg = "#d8d8d8", bg = "NONE", reverse = true })
set(0, "IncSearch", { fg = "#d8d8d8", bg = "NONE", reverse = true })
set(0, "CurSearch", { fg = "#d8d8d8", bg = "NONE", reverse = true })
set(0, "TelescopeResultsNormal", { fg = "#a8a8a8", bg = "NONE" })
set(0, "TelescopeMatching", { fg = "#ffffff", bg = "NONE", bold = true })
set(0, "TelescopeSelection", { bg = "#1a1a1a", fg = "#ffffff" })
set(0, "TelescopePromptNormal", { fg = "#ffffff", bg = "NONE" })

set(0, "CmpBorder", { bg = "NONE", fg = "#444444" })
set(0, "CmpDocBorder", { bg = "NONE", fg = "#444444" })
set(0, "CmpItemKind", { fg = "#b0b0b0", bg = "NONE" })
set(0, "CmpItemKindText", { fg = "#f0f0f0", bg = "NONE", bold = true })
set(0, "CmpItemAbbr", { fg = "#d0d0d0", bg = "NONE" })
set(0, "CmpItemAbbrMatch", { fg = "#ffffff", bg = "NONE", bold = true })
set(0, "CmpItemAbbrMatchFuzzy", { fg = "#ffffff", bg = "NONE", bold = true })

set(0, "Visual", { bg = "#2b2b2b" })
set(0, "VisualNOS", { bg = "#2b2b2b" })
set(0, "@markup.link", { fg = "#ffffff", underline = true })
set(0, "@markup.raw",  { fg = "#c8c8c8" })
set(0, "@markup.strong", { fg = "#ffffff", bold = true })
set(0, "@markup.italic", { fg = "#d0d0d0", italic = true })

set(0, "markdownLinkText", { fg = "#ffffff", underline = true })
set(0, "markdownUrl",      { fg = "#c8c8c8", underline = true })
set(0, "markdownCode",     { fg = "#c8c8c8" })

set(0, "FidgetNormal", { bg = "NONE" })
set(0, "FidgetTitle", { bg = "NONE" })
set(0, "FidgetTask", { bg = "NONE" })

-- Oil: sakura dirs only
set(0, "OilDir", { fg = "#ffb6c1" })
set(0, "OilDirIcon", { fg = "#ffb6c1" })

-- http auth manager (<leader>ku): sakura title/keys/ids, same green/red as Git for token status
set(0, "HttpAuthBorder", { fg = "#c49aa6" })
set(0, "HttpAuthTitle", { fg = "#ffb6c1", bold = true })
set(0, "HttpAuthKey", { fg = "#ffb6c1", bold = true })
set(0, "HttpAuthId", { fg = "#ffb6c1" })
set(0, "HttpAuthProject", { fg = "#c3a8d8" })
set(0, "HttpAuthValid", { fg = "#9ecfa8" })
set(0, "HttpAuthExpired", { fg = "#d98c8c" })
set(0, "HttpAuthCursor", { bg = "#1a1a1a" })

-- git status (lua/nkjda/git.lua): simple git colors (everything else stays quiet)
-- staged/unstaged/untracked entries link to these base groups, so this covers all three
set(0, "GitSectionHeader", { fg = "#ffb6c1", bold = true })
-- Head: branch you are on — bright sakura; Head variant gets dark pill so current pops in branch lists
set(0, "GitBranch", { fg = "#ffb6c1", bold = true })
set(0, "GitBranchHead", { fg = "#ffb6c1", bg = "#1a1a1a", bold = true, underline = true })
set(0, "GitObjectId", { fg = "#777777" })
-- commit graph: one palette color per column, commit dot sakura; remotes lilac, tags gold
set(0, "GitGraph1", { fg = "#ffb6c1" })
set(0, "GitGraph2", { fg = "#c3a8d8" })
set(0, "GitGraph3", { fg = "#8fc3c3" })
set(0, "GitGraph4", { fg = "#9ecfa8" })
set(0, "GitGraph5", { fg = "#d8b48f" })
set(0, "GitGraph6", { fg = "#c49aa6" })
set(0, "GitGraphCommit", { fg = "#ffb6c1", bold = true })
set(0, "GitGraphAuthor", { fg = "#c49aa6" })
set(0, "GitRemote", { fg = "#c3a8d8" })
set(0, "GitTagName", { fg = "#d8cf9e" })
-- commit kinds (logs, reflog, Head/Merge/Push): one meaning per color across the whole git UI
set(0, "GitKindNew", { fg = "#9ecfa8" })     -- commit, amend, feat
set(0, "GitKindFix", { fg = "#c49aa6" })     -- fix
set(0, "GitKindMerge", { fg = "#8fc3c3" })   -- merge, pull
set(0, "GitKindBranch", { fg = "#ffb6c1" })  -- checkout
set(0, "GitKindReset", { fg = "#d98c8c" })   -- reset
set(0, "GitKindRewrite", { fg = "#d8b48f" }) -- rebase, cherry-pick, revert
set(0, "GitKindChore", { fg = "#777777" })   -- chore, docs, refactor, test, style, perf, ci, build
-- conflicts: ours green, theirs lilac (status view); merge mode tints whole lines on a dark bg
set(0, "GitOurs", { fg = "#9ecfa8" })
set(0, "GitTheirs", { fg = "#c3a8d8" })
set(0, "GitMergeOurs", { bg = "#1e2a22" })
set(0, "GitMergeTheirs", { bg = "#26202e" })
set(0, "GitMergeBase", { bg = "#222222" })
set(0, "GitMergeMarker", { fg = "#777777", bold = true })
-- popup menus (? / b / c / etc): keys in sakura, rest stays quiet
set(0, "GitPopupActionKey", { fg = "#ffb6c1", bold = true })
set(0, "GitPopupSwitchKey", { fg = "#ffb6c1", bold = true })
set(0, "GitPopupOptionKey", { fg = "#ffb6c1", bold = true })
set(0, "GitPopupConfigKey", { fg = "#ffb6c1", bold = true })
-- selection: was light-grey block, now matches TelescopeSelection + sakura
set(0, "GitActiveItem", { bg = "#1a1a1a", fg = "#ffb6c1", bold = true })
set(0, "GitCursorLine", { bg = "#1a1a1a" })
set(0, "GitChangeAdded", { fg = "#9ecfa8" })
set(0, "GitChangeNewFile", { fg = "#9ecfa8" })
set(0, "GitChangeModified", { fg = "#c49aa6" })
set(0, "GitChangeDeleted", { fg = "#d98c8c" })
set(0, "GitChangeRenamed", { fg = "#c3a8d8" })
set(0, "GitChangeUpdated", { fg = "#d8b48f" })
set(0, "GitChangeCopied", { fg = "#8fc3c3" })
set(0, "GitChangeUnmerged", { fg = "#d8cf9e" })


vim.cmd("hi StatusLine guibg=none")
vim.cmd [[ hi Normal guibg=NONE ctermbg=NONE ]]
vim.cmd [[ hi NormalNC guibg=NONE ctermbg=NONE ]]
vim.cmd [[ hi VertSplit guibg=NONE ctermbg=NONE ]]
vim.cmd [[ hi EndOfBuffer guibg=NONE ctermbg=NONE ]]
vim.cmd [[highlight NvimTreeFolderIcon guifg=#FFC0CB]]
vim.cmd [[highlight NvimTreeFolderName guifg=#FFC0CB]]
vim.cmd [[highlight NvimTreeIndentMarker guifg=#FFC0CB]]
vim.cmd [[highlight NvimTreeFileRenamed guifg=#FFC0CB]]
vim.cmd [[highlight NvimTreeFileName guifg=#FFC0CB]]
vim.cmd [[highlight NvimTreeImageFile guifg=#FFC0CB]]
vim.cmd [[highlight NvimTreeSpecialFile guifg=#FFC0CB]]
vim.cmd('highlight NvimTreeNormal guibg=NONE')
vim.cmd('highlight NvimTreeNormalNC guibg=NONE')
