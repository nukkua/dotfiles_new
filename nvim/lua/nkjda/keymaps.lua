-- nkjda/keymaps.lua — ALL global keymaps (central file)
-- LSP buffer-local maps stay in lsp.lua (LspAttach).

-- helpers (loaded after plugins)
local harpoon = _G._nkjda_harpoon or require("harpoon")
local load_competitest = _G._nkjda_load_competitest or function() end

-- console.log / print helper
vim.keymap.set("n", "<leader>ca", function()
    local word = vim.fn.expand("<cword>")
    local ft = vim.bo.filetype
    local templates = {
        javascript = "console.log('%s:', %s);",
        typescript = "console.log('%s:', %s);",
        astro = "console.log('%s:', %s);",
        vue = "console.log('%s:', %s);",
        python = "print('%s:', %s)",
        lua = "print('%s:', %s)",
        rust = "println!(\"%s: {:?}\", %s);",
    }
    local template = templates[ft]
    if template then
        local line = string.format(template, word, word)
        vim.api.nvim_put({ line }, "l", true, true)
    else
        print("No template for filetype: " .. ft)
    end
end)

-- general editing / navigation
vim.keymap.set({ "n", "v", "x" }, "<leader>n", ":norm ", { desc = "ENTER NORM COMMAND." })
vim.keymap.set('i', '<C-c>', '<Esc>', { noremap = true })
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set('n', '<leader>s', ':e #<CR>')
vim.keymap.set("n", "<C-j>a", function()
    local qf_win = vim.fn.getqflist({ winid = 0 }).winid

    if qf_win ~= 0 then
        vim.cmd("cclose")
    else
        vim.cmd("copen")
    end
end, { desc = "Toggle quickfix list" })
vim.keymap.set('n', '<C-j>s', '<cmd>cprev<CR>')
vim.keymap.set('n', '<C-j>n', '<cmd>cnext<CR>')
vim.keymap.set("n", "<leader>tt", ":bot 12split +term<CR>")
vim.keymap.set("n", "<leader>td", function()
    local cwd = vim.fn.getcwd()
    local file = vim.fn.expand("~/todos/" .. os.date("%Y-%m-%d") .. ".md")
    vim.fn.mkdir(vim.fn.expand("~/todos"), "p")

    local buf = vim.api.nvim_create_buf(false, true)
    local width, height = 60, 5

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = {
            { "╭", "FloatBorder" },
            { "─", "FloatBorder" },
            { "╮", "FloatBorder" },
            { "│", "FloatBorder" },
            { "╯", "FloatBorder" },
            { "─", "FloatBorder" },
            { "╰", "FloatBorder" },
            { "│", "FloatBorder" },
        },
        title = " Add Todo · " .. cwd .. " ",
        title_pos = "center",
    })

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
    vim.cmd("startinsert")

    local function capture()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local text = table.concat(lines, " "):gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" then return end

        local f = io.open(file, "a+")
        if not f then return end

        f:seek("set")
        local content = f:read("*a") or ""

        if not content:match("## " .. vim.pesc(cwd) .. "\n$") then
            f:write("\n## " .. cwd .. "\n")
        end

        f:write("[" .. os.date("%H:%M") .. "] " .. text .. "\n")
        f:close()

        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
    end

    vim.keymap.set("i", "<CR>", capture, { buffer = buf })
    vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf })
    vim.keymap.set("i", "<Esc>", "<cmd>stopinsert<CR>", { buffer = buf })
end, { desc = "Quick TODO capture" })
-- double <C-c> in terminal: exit to normal mode (then :q, yank, search...)
-- ponytail: first <C-c> waits timeoutlen before sending a lone <C-c> to the shell
vim.keymap.set("t", "<C-c><C-c>", "<C-\\><C-n>")
vim.keymap.set("n", "-", "<CMD>Oil<CR>")
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without yank" })
vim.api.nvim_set_keymap('n', '<Space>w', ':w<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Space>q', ':q<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-c>', ":nohl<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>r', ":edit!<CR>", { noremap = true, silent = true })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "moves lines down in visual selection" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "moves lines up in visual selection" })
vim.keymap.set("v", "<", "<gv", { desc = "Unindent and keep selection" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent and keep selection" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })
vim.keymap.set('n', '*', '*zz', { silent = true })
vim.keymap.set('n', '#', '#zz', { silent = true })
vim.keymap.set('n', 'g*', 'g*zz', { silent = true })
vim.keymap.set('n', 'g#', 'g#zz', { silent = true })
vim.cmd([[cnoremap <CR> <CR><C-c>zz]])

-- fff
vim.keymap.set('n', '<Space>f', function() require('fff').find_files() end, { desc = 'FFFind files' })
vim.keymap.set('n', '<Space>ga', function() require('fff').live_grep() end, { desc = 'Live grep' })
vim.keymap.set('n', '<Space>ba', function() require('fff').find_files({ query = 'git:modified' }) end,
    { desc = 'Git status' })
vim.keymap.set('n', '<Space>be', function() require('fff').find_files({ query = 'git:staged' }) end,
    { desc = 'Git status' })
vim.keymap.set("n", "<leader>gw", function() require("fff").live_grep({ query = vim.fn.expand("<cword>") }) end)

vim.keymap.set('n', '<Space>u', function()
    vim.cmd.packadd("nvim.undotree")
    require("undotree").open()
end, { desc = "Toggle builtin undotree" })

local function run_make(raw_cmd)
    local makeprg = vim.fn.expandcmd(raw_cmd)

    local output = {}
    local ft = vim.bo.filetype
    local file = vim.fn.expand("%:t")

    local labels = {
        c = "C",
        cpp = "C++",
        rust = "Rust",
        javascript = "JavaScript",
        typescript = "TypeScript",
        vue = "Vue",
    }

    local progress = require("fidget.progress")
    local handle = progress.handle.create({
        title = labels[ft] or ft,
        message = "Checking " .. file,
        lsp_client = { name = "make" },
    })

    vim.fn.jobstart(makeprg, {
        stdout_buffered = true,
        stderr_buffered = true,

        on_stdout = function(_, data)
            if data then vim.list_extend(output, data) end
        end,

        on_stderr = function(_, data)
            if data then vim.list_extend(output, data) end
        end,

        on_exit = function(_, code)
            vim.schedule(function()
                vim.fn.setqflist({}, "r", {
                    title = makeprg,
                    lines = output,
                    efm = vim.bo.errorformat,
                })

                if code ~= 0 then
                    handle.message = "Failed"
                    handle:finish()
                    vim.cmd("cwindow")
                else
                    handle.message = "Passed"
                    handle:finish()
                    vim.cmd("cclose")
                end
            end)
        end,
    })
end

local function default_makeprg()
    return vim.bo.makeprg ~= "" and vim.bo.makeprg or vim.o.makeprg
end

-- ponytail: rust file-check is same as project; rustc on one file fails on crate imports
local project_cmds = {
    rust = "cargo check --message-format short",
    c = "make",
    cpp = "make",
    javascript = "npx --loglevel=error eslint -f unix --quiet .",
    typescript = "npx --loglevel=error eslint -f unix --quiet .",
    vue = "npx --loglevel=error eslint -f unix --quiet .",
}
local file_cmds = {
    rust = "cargo check --message-format short",
    c = "g++ -std=c++23 -Wall -Wextra -Wshadow %:p:S -o %:p:r:S",
    cpp = "g++ -std=c++23 -Wall -Wextra -Wshadow %:p:S -o %:p:r:S",
    javascript = "npx --loglevel=error eslint -f unix --quiet %:p:S",
    typescript = "npx --loglevel=error eslint -f unix --quiet %:p:S",
    vue = "npx --loglevel=error eslint -f unix --quiet %:p:S",
}

vim.keymap.set("n", "<leader>cr", function()
    run_make(default_makeprg())
end, { desc = "Check (makeprg)" })
vim.keymap.set("n", "<leader>cp", function()
    run_make(project_cmds[vim.bo.filetype] or default_makeprg())
end, { desc = "Check project" })
vim.keymap.set("n", "<leader>cf", function()
    run_make(file_cmds[vim.bo.filetype] or default_makeprg())
end, { desc = "Check file" })

-- harpoon
vim.keymap.set("n", ",,", function() harpoon:list():add() end)
vim.keymap.set("n", ",e", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
vim.keymap.set("n", ",s", function() harpoon:list():select(1) end)
vim.keymap.set("n", ",n", function() harpoon:list():select(2) end)
vim.keymap.set("n", ",t", function() harpoon:list():select(3) end)
vim.keymap.set("n", ",r", function() harpoon:list():select(4) end)
vim.keymap.set("n", ",w", function() harpoon:list():select(5) end)
vim.keymap.set("n", ",m", function() harpoon:list():prev() end)
vim.keymap.set("n", ",h", function() harpoon:list():next() end)

-- diagnostics / competitest
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>ap", function()
    load_competitest(); vim.cmd("CompetiTest receive problem")
end, { desc = "Receive problem" })
vim.keymap.set("n", "<leader>ac", function()
    load_competitest(); vim.cmd("CompetiTest receive contest")
end, { desc = "Receive contest" })
vim.keymap.set("n", "<leader>ar", "<cmd>CompetiTest run<CR>", { desc = "run the problem" })
vim.keymap.set("n", "<leader>as", "<cmd>CompetiTest add_testcase<CR>", { desc = "run the problem" })

-- dial increment/decrement (numbers, dates, bools, ...)
vim.keymap.set("n", "<C-a>", function() require("dial.map").manipulate("increment", "normal") end)
vim.keymap.set("n", "<C-x>", function() require("dial.map").manipulate("decrement", "normal") end)
vim.keymap.set("v", "<C-a>", function() require("dial.map").manipulate("increment", "visual") end)
vim.keymap.set("v", "<C-x>", function() require("dial.map").manipulate("decrement", "visual") end)

-- neogit replaces current buffer -> <leader>gg
vim.keymap.set("n", "<leader>gg", function() require("neogit").open() end, { desc = "Neogit status" })
