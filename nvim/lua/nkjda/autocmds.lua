-- nkjda/autocmds.lua — all autocommands not tied to a single plugin's setup

-- highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking",
    callback = function() vim.hl.on_yank({ timeout = 55 }) end,
})

-- astro: allow '-' in keyword
vim.api.nvim_create_autocmd("FileType", {
    pattern = "astro",
    callback = function() vim.opt_local.iskeyword:remove("-") end,
})

-- git conflict markers highlight
vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "VimEnter" }, {
    callback = function()
        if vim.w.git_conflict_matches then return end
        vim.w.git_conflict_matches = {
            vim.fn.matchadd("ConflictMarker", [[^<<<<<<< .*$]]),
            vim.fn.matchadd("ConflictMarker", [[^=======$]]),
            vim.fn.matchadd("ConflictMarker", [[^>>>>>>> .*$]]),
        }
    end,
})

-- makeprg / compiler per filetype
local augroup = vim.api.nvim_create_augroup("MakeSettings", {})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "rust",
    callback = function()
        vim.cmd("compiler cargo")
        vim.opt_local.makeprg = "cargo check --message-format short"
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = { "c", "cpp" },
    callback = function()
        vim.cmd("compiler gcc")
        vim.opt_local.makeprg =
        "g++ -std=c++23 -Wall -Wextra -Wshadow %:p:S -o %:p:r:S"
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = { "javascript", "typescript", "vue" },
    callback = function()
        vim.opt_local.makeprg = "npx --loglevel=error eslint -f unix --quiet"
        vim.opt_local.errorformat = "%f:%l:%c: %m"
    end,
})

-- intro screen (requires lua/intro.lua)
require("intro")
