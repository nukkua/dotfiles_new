-- nkjda/keymaps.lua — ALL global keymaps (central file)
-- LSP buffer-local maps stay in lsp.lua (LspAttach).

-- helpers (loaded after plugins)
local harpoon = _G._nkjda_harpoon or require("harpoon")
local load_competitest = _G._nkjda_load_competitest

-- console.log / print helper
vim.keymap.set("n", "<leader>ca", function()
    local word = vim.fn.expand("<cword>")
    local ft = vim.bo.filetype
    local templates = {
        javascript = "console.log('%s:', %s);",
        typescript = "console.log('%s:', %s);",
        astro = "console.log('%s:', %s);",
        vue = "console.log('%s:', %s);",
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
-- normal mode only: a terminal-mode <leader> map would delay every space typed into claude (<C-c><C-c> first)
vim.keymap.set("n", "<leader>tc", function() require("nkjda.claude").toggle() end, { desc = "Toggle claude code split" })
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



-- neogit replaces current buffer -> <leader>gg
vim.keymap.set("n", "<leader>gg", function() require("neogit").open() end, { desc = "Neogit status" })

-- :Pr — PR + merge status for the current branch, lazygit-style (needs `gh` auth)
local function _str(v, fb)
  if v == nil or v == vim.NIL then return fb or "" end
  return tostring(v)
end

local function _ci_summary(rollup)
  if type(rollup) ~= "table" then rollup = {} end
  local fail, pending = 0, 0
  for _, c in ipairs(rollup) do
    if c.conclusion == "FAILURE" or c.conclusion == "TIMED_OUT" or c.conclusion == "CANCELLED"
      or c.state == "FAILURE" or c.state == "ERROR" then
      fail = fail + 1
    elseif c.status ~= "COMPLETED" and c.state ~= "SUCCESS" then
      pending = pending + 1
    end
  end
  if fail > 0 then return fail .. " failing", "PrClosed" end
  if pending > 0 then return pending .. " running", "PrWarn" end
  return "passing", "PrOpen"
end

-- GitHub web (Primer): open green, merged purple, closed red, draft gray
for name, fg in pairs({ PrOpen = "#9ecfa8", PrMerged = "#c3a8d8", PrClosed = "#d98c8c", PrDraft = "#8a8a8a", PrWarn = "#d8b48f", PrBranch = "#ffb6c1" }) do
  vim.api.nvim_set_hl(0, name, { fg = fg })
end
local _pr_state_hl = { OPEN = "PrOpen", MERGED = "PrMerged", CLOSED = "PrClosed", DRAFT = "PrDraft" }

local function run(cmd, cb)
  vim.system(cmd, { text = true }, vim.schedule_wrap(cb))
end

-- finds the integration base branch, then calls cb(base)
local function find_base(cb)
  local candidates = { "origin/develop", "origin/main" }
  local function try(i)
    if i > #candidates then
      run({ "git", "rev-parse", "--abbrev-ref", "origin/HEAD" }, function(r)
        local b = vim.trim(r.stdout or "")
        cb((r.code == 0 and b ~= "") and b or "origin/develop")
      end)
      return
    end
    run({ "git", "rev-parse", "--verify", "--quiet", candidates[i] }, function(r)
      if r.code == 0 then cb(candidates[i]) else try(i + 1) end
    end)
  end
  try(1)
end

vim.api.nvim_create_user_command("Pr", function()
  local branch, pr_res
  local pending = 2
  local function finish()
    pending = pending - 1
    if pending > 0 then return end
    branch = branch or "?"
    local ok, pr = pcall(vim.json.decode, pr_res.stdout or "")

    if not ok or type(pr) ~= "table" or not pr.number then
      return find_base(function(base)
        run({ "git", "merge-base", "--is-ancestor", "HEAD", base }, function(r)
          local merged = r.code == 0
          vim.api.nvim_echo({
            { branch .. ": no PR · ", "Comment" },
            { (merged and "merged into " or "not merged into ") .. base,
              merged and "PrOpen" or "PrWarn" },
          }, true, {})
        end)
      end)
    end

    local state = pr.isDraft == true and "DRAFT" or _str(pr.state, "?")
    local ci, ci_hl = _ci_summary(pr.statusCheckRollup)
    vim.api.nvim_echo({
      { "#" .. _str(pr.number, "?") .. " ", "Comment" },
      { _str(state, "?"), _str(_pr_state_hl[state], "Normal") },
      { "  " .. _str(pr.title), "Normal" },
      { "  " .. _str(branch, "?"), "PrBranch" },
      { "\n" .. _str(pr.mergeable, "?") .. " · review "
        .. _str(pr.reviewDecision, "none") .. " · CI ", "Comment" },
      { _str(ci), _str(ci_hl, "Normal") },
    }, true, {})
  end
  run({ "git", "rev-parse", "--abbrev-ref", "HEAD" }, function(r)
    branch = vim.trim(r.stdout or "")
    if branch == "" then branch = nil end
    finish()
  end)
  run({ "gh", "pr", "view", "--json",
    "number,state,title,isDraft,mergeable,reviewDecision,statusCheckRollup" },
    function(r)
      pr_res = r
      finish()
    end)
end, { desc = "PR status for current branch" })

vim.api.nvim_create_user_command("Prs", function(opts)
  run({ "gh", "pr", "list", "--json",
    "number,title,author,headRefName,isDraft,reviewDecision,statusCheckRollup",
    "--limit", opts.args ~= "" and opts.args or "30" },
    function(r)
      local ok, prs = pcall(vim.json.decode, r.stdout or "")
      if not ok or type(prs) ~= "table" or #prs == 0 then
        return vim.api.nvim_echo({ { "no PRs", "Comment" } }, true, {})
      end
      local chunks = {}
      for i, pr in ipairs(prs) do
        local state = pr.isDraft == true and "DRAFT" or _str(pr.state, "?")
        local ci, ci_hl = _ci_summary(pr.statusCheckRollup)
        local nl = i > 1 and "\n" or ""
        local login = type(pr.author) == "table" and _str(pr.author.login, "?") or "?"
        table.insert(chunks, { nl .. "#" .. _str(pr.number, "?") .. " ", "Comment" })
        table.insert(chunks, { _str(state, "?"), _str(_pr_state_hl[state], "Normal") })
        table.insert(chunks, { "  " .. _str(pr.title), "Normal" })
        table.insert(chunks, { "  " .. _str(pr.headRefName), "PrBranch" })
        table.insert(chunks, { "  @" .. login, "Comment" })
        table.insert(chunks, { " · " .. _str(pr.reviewDecision, "no review"), "Comment" })
        table.insert(chunks, { " · " .. _str(ci), _str(ci_hl, "Normal") })
      end
      vim.api.nvim_echo(chunks, true, {})
    end)
end, { nargs = "?", desc = "List PRs with status" })

-- neogit status: PR/merge state as a virtual line under Push:
-- neogit redraws the whole buffer on refresh (wiping extmarks), so redraw from cache, then refetch
local _pr_ns = vim.api.nvim_create_namespace("neogit_pr_state")
local _pr_cache = {} -- branch -> chunks
local function _pr_draw(buf, chunks)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_buf_clear_namespace(buf, _pr_ns, 0, -1)
  local row -- under Push:, or Head: when the branch has no upstream
  for i, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, 10, false)) do
    if l:match("^%s*Push:") then row = i - 1 break end
    if l:match("^%s*Head:") then row = i - 1 end
  end
  if row then vim.api.nvim_buf_set_extmark(buf, _pr_ns, row, 0, { virt_lines = { chunks } }) end
end
vim.api.nvim_create_autocmd("User", {
  pattern = "NeogitStatusRefreshed",
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].filetype ~= "NeogitStatus" then
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].filetype == "NeogitStatus" then buf = b end
      end
    end
    run({ "git", "rev-parse", "--abbrev-ref", "HEAD" }, function(br)
      local branch = vim.trim(br.stdout or "")
      if _pr_cache[branch] then _pr_draw(buf, _pr_cache[branch]) end
      local label = { "PR:       ", "NeogitSubtleText" }
      local function show(chunks)
        table.insert(chunks, 1, label)
        _pr_cache[branch] = chunks
        _pr_draw(buf, chunks)
      end
      run({ "gh", "pr", "view", "--json", "number,state,isDraft,title" }, function(r)
        local ok, pr = pcall(vim.json.decode, r.stdout or "")
        if ok and type(pr) == "table" and pr.number then
          local state = pr.isDraft == true and "DRAFT" or _str(pr.state, "?")
          return show({
            { "#" .. _str(pr.number, "?") .. " ", "Comment" },
            { state, _str(_pr_state_hl[state], "Normal") },
            { "  " .. _str(pr.title), "Comment" },
          })
        end
        find_base(function(base)
          run({ "git", "merge-base", "--is-ancestor", "HEAD", base }, function(m)
            local merged = m.code == 0
            show({
              { "no PR · ", "Comment" },
              { (merged and "merged into " or "not merged into ") .. base, merged and "PrMerged" or "PrWarn" },
            })
          end)
        end)
      end)
    end)
  end,
})

vim.keymap.set("n", "<leader>gp", "<cmd>Pr<CR>", { desc = "PR status" })
vim.keymap.set("n", "<leader>gl", "<cmd>Prs<CR>", { desc = "List PRs" })

vim.keymap.set("n", "<leader>gn", function()
  vim.ui.input({ prompt = "Reviewer: ", default = "juanrdlo" }, function(reviewer)
    if not reviewer or reviewer == "" then return end
    vim.notify("creating PR…") -- gh is network-bound; show it's working
    vim.system(
      { "gh", "pr", "create", "--fill", "--reviewer", reviewer },
      { text = true },
      vim.schedule_wrap(function(res)
        -- gh fails with "a pull request for branch ... already exists:\n<url>"
        local existing = res.code ~= 0 and (res.stderr or ""):match("already exists:%s*(https://%S+)")
        if res.code ~= 0 and not existing then
          vim.notify(res.stderr, vim.log.levels.ERROR)
          return
        end
        local url = existing or vim.trim(res.stdout)
        vim.fn.setreg("+", url)
        vim.notify((existing and "PR already exists" or "PR created") .. ", URL copied:\n" .. url)
      end)
    )
  end)
end, { desc = "Create PR and copy URL" })
vim.keymap.set("n", "<leader>gs", function()
  vim.system(
    { "gh", "pr", "view", "--json", "url", "--jq", ".url" },
    { text = true },
    vim.schedule_wrap(function(res)
      if res.code ~= 0 then
        vim.notify(res.stderr, vim.log.levels.ERROR)
        return
      end
      local url = vim.trim(res.stdout)
      vim.fn.setreg("+", url)
      vim.ui.open(url)
      vim.notify("PR URL copied:\n" .. url)
    end)
  )
end, { desc = "See PR and copy URL" })
vim.keymap.set("n", "<leader>gc", function()
  if vim.fn.confirm("Close the PR for this branch?", "&Yes\n&No", 2) ~= 1 then
    return
  end
  vim.system(
    { "gh", "pr", "close" },
    { text = true },
    vim.schedule_wrap(function(res)
      if res.code ~= 0 then
        vim.notify(res.stderr, vim.log.levels.ERROR)
        return
      end
      vim.notify("PR closed")
    end)
  )
end, { desc = "Close PR" })
