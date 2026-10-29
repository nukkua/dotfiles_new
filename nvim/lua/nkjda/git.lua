-- nkjda/git.lua — magit-style git status + popups on the git CLI (own magit-style client)
-- <leader>gg opens it, ? lists every key. Every git call is async (vim.system); a refresh is one
-- parallel batch of short processes, toggles re-render from cache, and only changed lines are redrawn.
-- ponytail: no worktree/submodule popups; no credential prompts (use ssh-agent or a credential
-- helper); a ' in a repo path breaks the $EDITOR bridge

local M = {}

local S = {
  root = nil, gitdir = nil, buf = nil, prev = nil,
  data = nil, diffs = {}, rows = {}, -- rows[buf][lnum] = item on that line
  fold = {}, open = {},              -- collapsed sections; expanded files ("section:path" -> file)
  switches = {}, history = {},
  fetch = { job = false, at = -math.huge, cbs = {} },
  pr = nil,                          -- "root\0branch" -> PR lines; gh takes seconds, so paint from this disk cache
  pr_at = {},                        -- "root\0branch" -> last gh call (ms); gh runs at most every PR_TTL
  queue = {},                        -- serialized index/worktree commands, head is running
  seq = 0,                           -- refresh generation: stale async results are dropped
}
local ns = vim.api.nvim_create_namespace("nkjda_git")
local RECENT = 10
local FETCH_TTL = 30000 -- ms: a fetch this fresh is reused instead of hitting the network again
local PR_TTL = 60000    -- ms: gh pr view is ~6s of network; refetched on open, after push/PR actions, else at most this often
local HISTORY_MAX = 100
local LOGFMT = "%h%x1f%D%x1f%s%x1f%an%x1f%at" -- %at: unix time, shown as a short age
local HAS_GH = vim.fn.executable("gh") == 1
local PR_CACHE = vim.fn.stdpath("cache") .. "/git_pr.json"

-- git asks this nvim to edit COMMIT_EDITMSG / git-rebase-todo / TAG_EDITMSG over RPC and waits
-- until M.edit drops the lock (or nvim is gone)
local EDITOR = [[f(){ case $1 in /*) p=$1;; *) p=$PWD/$1;; esac; touch "$p.nvlock"; "$NVIM_BIN" --server "$NVIM" --remote-expr "luaeval('require(\"nkjda.git\").edit(_A)', '$p')" >/dev/null; while [ -e "$p.nvlock" ] && [ -e "$NVIM" ]; do sleep 0.05; done; }; f]]

-- defaults only: colors/quiet.lua sets the real ones
local HL = {
  GitSectionHeader = "Title", GitBranch = "Identifier", GitBranchHead = "GitBranch",
  GitRemote = "Constant", GitTagName = "Special", GitObjectId = "Comment",
  GitSubtleText = "Comment", GitHunkHeader = "Special",
  GitChangeAdded = "Added", GitChangeNewFile = "Added", GitChangeModified = "Changed",
  GitChangeDeleted = "Removed", GitChangeRenamed = "Changed", GitChangeCopied = "Changed",
  GitChangeUpdated = "Changed", GitChangeUnmerged = "WarningMsg",
  GitDiffAdd = "GitChangeAdded", GitDiffDelete = "GitChangeDeleted",
  GitGraph1 = "Added", GitGraph2 = "Changed", GitGraph3 = "Removed", GitGraph4 = "Constant",
  GitGraph5 = "Identifier", GitGraph6 = "Special", GitGraphCommit = "GitBranch", GitGraphAuthor = "Constant",
  GitOurs = "GitChangeAdded", GitTheirs = "GitRemote", GitBase = "GitSubtleText",
  GitMergeOurs = "DiffAdd", GitMergeTheirs = "DiffChange", GitMergeBase = "DiffText", GitMergeMarker = "GitSubtleText",
  GitKindNew = "GitChangeAdded", GitKindFix = "GitChangeModified", GitKindMerge = "Special", GitKindBranch = "GitBranch",
  GitKindReset = "GitChangeDeleted", GitKindRewrite = "GitChangeUpdated", GitKindChore = "GitSubtleText",
  GitPopupActionKey = "Special", GitPopupSwitchKey = "Special", GitPopupSwitchEnabled = "String",
}
-- GitHub web (Primer): open green, merged purple, closed red, draft gray
local PR_HL = { PrOpen = "#9ecfa8", PrMerged = "#c3a8d8", PrClosed = "#d98c8c", PrDraft = "#8a8a8a", PrWarn = "#d8b48f", PrBranch = "#ffb6c1" }
local function hl()
  for k, v in pairs(HL) do vim.api.nvim_set_hl(0, k, { link = v, default = true }) end
  for k, fg in pairs(PR_HL) do vim.api.nvim_set_hl(0, k, { fg = fg }) end
end
hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = hl })

---------------------------------------------------------------- helpers

local function cat(...)
  local t = {}
  for i = 1, select("#", ...) do vim.list_extend(t, (select(i, ...))) end
  return t
end
local function lines(s) return vim.split(s or "", "\n", { plain = true, trimempty = true }) end
local function notify(msg, lvl) vim.notify(msg, lvl or vim.log.levels.INFO, { title = "git" }) end
local function confirm(msg) return vim.fn.confirm(msg, "&Yes\n&No", 2) == 1 end
-- cb is deferred: with ui2 + cmdheight=0 a prompt opened from inside another prompt's callback never shows
local function input(prompt, default, cb)
  vim.ui.input({ prompt = prompt, default = default }, function(v)
    if v and v ~= "" then vim.schedule(function() cb(v) end) end
  end)
end
local function pick(prompt, items, cb)
  if #items == 0 then return notify(prompt .. ": nothing to pick", vim.log.levels.WARN) end
  require("nkjda.select").select(items, { prompt = prompt }, function(c) if c then cb(c) end end)
end

-- run git (or opts.raw argv) in the repo; cb(res) on the main loop
-- detach: no controlling tty, so ssh/https fail instead of prompting over the UI
local function git(args, opts, cb)
  opts = opts or {}
  local cmd = opts.raw or cat({ "git" }, args)
  local env = { GIT_EDITOR = EDITOR, GIT_SEQUENCE_EDITOR = EDITOR, NVIM = vim.v.servername,
    NVIM_BIN = vim.v.progpath, GIT_TERMINAL_PROMPT = "0" }
  for k, v in pairs(opts.env or {}) do env[k] = v end
  local t0 = vim.uv.hrtime()
  vim.system(cmd, { cwd = S.root, text = true, env = env, stdin = opts.stdin, detach = true },
    vim.schedule_wrap(function(r)
      if opts.log then
        table.insert(S.history, 1, { cmd = table.concat(cmd, " "), code = r.code,
          ms = math.floor((vim.uv.hrtime() - t0) / 1e6), out = vim.trim((r.stdout or "") .. (r.stderr or "")) })
        S.history[HISTORY_MAX + 1] = nil
      end
      if cb then cb(r) end
    end))
end

-- read-only buffer in this window; q goes back one step (log -> show -> q -> log, cursor kept)
-- and deletes only the view it leaves. Views are hidden, not wiped, so the one below stays alive
local function scratch(name, ft, text)
  local prev = vim.api.nvim_get_current_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "hide"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, type(text) == "table" and text or lines(text))
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = ft
  pcall(vim.api.nvim_buf_set_name, buf, "git://" .. name)
  vim.api.nvim_win_set_buf(0, buf)
  vim.keymap.set("n", "q", function()
    local back = vim.api.nvim_buf_is_valid(prev) and prev or S.buf
    if back and vim.api.nvim_buf_is_valid(back) then vim.api.nvim_win_set_buf(0, back) end
    S.rows[buf] = nil
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end, { buffer = buf, nowait = true })
  return buf
end

local function output(out)
  local l = lines(out)
  if #l > 8 then scratch("output", "git", l) else notify(out) end
end

-- index/worktree commands run one at a time: rapid s/x would otherwise race on .git/index.lock.
-- commit/push/fetch stay free (plain commit holds no lock while its editor is open)
local SERIAL = { add = true, apply = true, restore = true, rm = true, reset = true, stash = true, switch = true, checkout = true }

-- user-visible git command: errors are reported, status refreshes after
local function act(args, opts)
  opts = opts or {}
  local Q = S.queue
  local function run(done)
    if opts.msg then notify(opts.msg .. "…") end
    git(args, { log = true, raw = opts.raw, stdin = opts.stdin, env = opts.env }, function(r)
      local out = vim.trim((r.stdout or "") .. "\n" .. (r.stderr or ""))
      if r.code ~= 0 then
        notify(out ~= "" and out or ("git exited " .. r.code), vim.log.levels.ERROR)
      elseif opts.show and out ~= "" then
        output(out)
      end
      if r.code == 0 and opts.after then opts.after(r) end
      M.refresh() -- after every job, so repeated s on one row hits the file that slid up
      if done then done() end
    end)
  end
  if not (args and SERIAL[args[1]]) then return run() end
  local function next_job()
    table.remove(Q, 1)
    if Q[1] then Q[1](next_job) end
  end
  Q[#Q + 1] = run
  if #Q == 1 then run(next_job) end
end

-- snapshot tracked changes into a stash entry (worktree untouched), then cb(); Z restores it
local function backup(cb)
  git({ "stash", "create" }, nil, function(r)
    local h = vim.trim(r.stdout or "")
    if r.code ~= 0 or h == "" then return cb() end
    git({ "stash", "store", "-m", "nkjda backup " .. os.date("%H:%M:%S"), h }, { log = true }, function()
      notify("backup: stash@{0} (Z to restore)")
      cb()
    end)
  end)
end

local function describe(ps)
  local t = vim.list_slice(ps, 1, 10)
  if #ps > 10 then t[#t + 1] = ("…and %d more"):format(#ps - 10) end
  return table.concat(t, "\n")
end

local function state()
  local function has(f) return S.gitdir and vim.uv.fs_stat(S.gitdir .. "/" .. f) ~= nil end
  return { rebase = has("rebase-merge") or has("rebase-apply"), merge = has("MERGE_HEAD"),
    pick = has("CHERRY_PICK_HEAD"), revert = has("REVERT_HEAD"), bisect = has("BISECT_LOG") }
end

-- background `fetch --all`; cb runs once it is done (or right away if one finished recently)
local function fetch_bg(cb)
  local F = S.fetch
  if cb then F.cbs[#F.cbs + 1] = cb end
  local function flush()
    local cbs = F.cbs
    F.cbs = {}
    for _, f in ipairs(cbs) do f() end
  end
  if F.job then
    if cb then notify("waiting for fetch…") end
    return
  end
  if vim.uv.now() - F.at < FETCH_TTL then return flush() end
  F.job = true
  git({ "fetch", "--all", "--prune", "--quiet" }, { log = true }, function()
    F.job, F.at = false, vim.uv.now()
    M.refresh()
    flush()
  end)
end

-- local + remote branch names, most recently committed first
local function refs(paths, cb)
  git(cat({ "for-each-ref", "--sort=-committerdate", "--format=%(refname:short)" }, paths), nil, function(r)
    local set, out = S.data and S.data.remoteset or {}, {}
    for _, l in ipairs(lines(r.stdout)) do
      if not l:match("/HEAD$") and not set[l] then out[#out + 1] = l end
    end
    cb(out)
  end)
end

local function remote(cb)
  local rs = S.data and S.data.remotes or {}
  if #rs == 0 then return notify("no remotes (M a adds one)", vim.log.levels.WARN) end
  if #rs == 1 or vim.tbl_contains(rs, "origin") then return cb(#rs == 1 and rs[1] or "origin") end
  pick("Remote", rs, cb)
end

local function commits(ctx, cb)
  if #ctx.commits > 0 then return cb(ctx.commits) end
  input("Commit: ", nil, function(c) cb({ c }) end)
end

-- `c^`, or --root when c has no parent
local function base_of(c)
  local r = vim.system({ "git", "rev-parse", "-q", "--verify", c .. "^" }, { cwd = S.root }):wait()
  return r.code == 0 and c .. "^" or "--root"
end

---------------------------------------------------------------- parsing

local function parse_status(out)
  local st = { untracked = {}, unstaged = {}, staged = {} }
  local recs = vim.split(out or "", "\0", { plain = true })
  local i = 1
  while i <= #recs do
    local r, t = recs[i], recs[i]:sub(1, 1)
    if t == "#" then
      local k, v = r:match("^# branch%.(%S+) (.*)$")
      if k then st[k] = v end
    elseif t == "?" then
      table.insert(st.untracked, { section = "untracked", path = r:sub(3), mode = "?" })
    elseif t == "1" or t == "2" then
      local x, y = r:sub(3, 3), r:sub(4, 4)
      local path = r:match("^" .. t .. (" %S+"):rep(t == "1" and 7 or 8) .. " (.*)$")
      local orig
      if t == "2" then i, orig = i + 1, recs[i + 1] end
      if x ~= "." then table.insert(st.staged, { section = "staged", path = path, mode = x, orig = orig }) end
      if y ~= "." then table.insert(st.unstaged, { section = "unstaged", path = path, mode = y }) end
    elseif t == "u" then
      table.insert(st.unstaged, { section = "unstaged", path = r:match("^u" .. (" %S+"):rep(9) .. " (.*)$"), mode = "U" })
    end
    i = i + 1
  end
  return st
end

-- one row per line of `git log [--graph] --format=LOGFMT`; graph-only connector lines have no hash
local function parse_log(out, marked)
  local t = {}
  for _, l in ipairs(lines(out)) do
    local m
    if marked then m, l = l:sub(1, 1), l:sub(2) end
    local g, h, refs_, subj, an, ar = l:match("^(.-)(%x+)\31(.-)\31(.-)\31(.-)\31(.*)$")
    t[#t + 1] = h and { graph = g, hash = h, refs = refs_, subject = subj, author = an, date = ar, mark = m } or { graph = l }
  end
  return t
end
local function commit_count(list)
  local n = 0
  for _, c in ipairs(list) do if c.hash then n = n + 1 end end
  return n
end

local function parse_diff(out)
  local d, h = { header = {}, hunks = {} }, nil
  for _, l in ipairs(lines(out)) do
    if l:sub(1, 2) == "@@" then
      h = { header = l, lines = {}, new = tonumber(l:match("%+(%d+)")) or 1 }
      table.insert(d.hunks, h)
    elseif h then
      table.insert(h.lines, l)
    else
      table.insert(d.header, l)
    end
  end
  return d
end

-- conflict blocks read straight from the markers in the worktree file (|||||| base part is optional)
local function parse_conflicts(path)
  local out, cur, part, n = {}, nil, nil, 0
  local ok, it = pcall(io.lines, path)
  if not ok then return out end
  for l in it do
    n = n + 1
    if l:match("^<<<<<<<") then cur, part = { line = n, ours = {}, base = {}, theirs = {} }, "ours"
    elseif cur and l:match("^|||||||") then part = "base"
    elseif cur and l:match("^=======$") then part = "theirs"
    elseif cur and l:match("^>>>>>>>") then out[#out + 1], cur = cur, nil
    elseif cur then table.insert(cur[part], l) end
  end
  return out
end

local function diff_args(f)
  if f.section == "untracked" then return { "diff", "--no-index", "--", "/dev/null", f.path } end
  return cat({ "diff" }, f.section == "staged" and { "--cached" } or {}, { "--", f.path, f.orig })
end

local function fkey(f) return f.section .. ":" .. f.path end

local function key(it)
  if not it then return nil end
  if it.commit then return (it.section or "") .. "@" .. it.commit end
  if it.stash then return "stash:" .. it.stash end
  if it.conflict then return fkey(it.file) .. ":c" .. it.ci .. ":" .. it.cl end
  if it.header then return "#" .. it.section end
  return fkey(it.file) .. (it.hunk and (":" .. it.hi .. ":" .. it.idx) or "")
end

---------------------------------------------------------------- render

local LABEL = { M = "modified", A = "new file", D = "deleted", R = "renamed", C = "copied", T = "typechange", U = "unmerged" }
local MODE_HL = { M = "GitChangeModified", A = "GitChangeNewFile", D = "GitChangeDeleted",
  R = "GitChangeRenamed", C = "GitChangeCopied", T = "GitChangeUpdated", U = "GitChangeUnmerged" }
local BUSY = { { "rebase", "rebase" }, { "merge", "merge" }, { "pick", "cherry-pick" }, { "revert", "revert" }, { "bisect", "bisect" } }

-- write lines/highlights to buf, touching only the lines that changed (keeps the cursor and is cheap)
local function paint(buf, L, H)
  local old = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local p, s = 0, 0
  while p < #old and p < #L and old[p + 1] == L[p + 1] do p = p + 1 end
  while s < #old - p and s < #L - p and old[#old - s] == L[#L - s] do s = s + 1 end
  if p == #old and p == #L then return end -- identical: keep lines and highlights
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, p, #old - s, false, vim.list_slice(L, p + 1, #L - s))
  vim.bo[buf].modifiable = false
  -- unchanged lines keep their extmarks (they move with the text); marks of replaced lines collapse
  -- onto row p, so the redone range always includes it
  local e = math.max(#L - s, p + 1)
  vim.api.nvim_buf_clear_namespace(buf, ns, p, e)
  for _, h in ipairs(H) do
    if h[1] >= p and h[1] < e then vim.api.nvim_buf_set_extmark(buf, ns, h[1], h[2], { end_col = h[3], hl_group = h[4] }) end
  end
end

-- builder: add({ {text, hl?}, ... }, item)
local function builder()
  local L, H, R = {}, {}, {}
  local function add(chunks, item)
    local t, col = {}, 0
    for _, c in ipairs(chunks) do
      t[#t + 1] = c[1]
      if c[2] and #c[1] > 0 then H[#H + 1] = { #L, col, col + #c[1], c[2] } end
      col = col + #c[1]
    end
    L[#L + 1] = table.concat(t)
    R[#L] = item
  end
  return add, L, H, R
end

local function refchunks(refs_, ch, set)
  for r in vim.gsplit(refs_ or "", ", ", { plain = true }) do
    local head, tag = r:match("^HEAD %-> (.+)$"), r:match("^tag: (.+)$")
    if head then ch[#ch + 1] = { head, "GitBranchHead" }
    elseif tag then ch[#ch + 1] = { tag, "GitTagName" }
    elseif r ~= "" and r ~= "HEAD" then ch[#ch + 1] = { r, set[r:match("^[^/]+")] and "GitRemote" or "GitBranch" }
    end
    if r ~= "" and r ~= "HEAD" then ch[#ch + 1] = { " " } end
  end
end

-- unix time -> "now", "20m", "3h", "2d", "5w", "4mo", "2y"
local function age(t)
  local d = os.time() - (tonumber(tostring(t or ""):match("(%d+)}?$")) or os.time())
  for _, u in ipairs({ { 31536000, "y" }, { 2592000, "mo" }, { 604800, "w" }, { 86400, "d" }, { 3600, "h" }, { 60, "m" } }) do
    if d >= u[1] then return math.floor(d / u[1]) .. u[2] end
  end
  return "now"
end

-- text columns of a window (minus number/sign columns)
local function text_width(win)
  local info = win and win ~= -1 and vim.fn.getwininfo(win)[1]
  return info and (info.width - info.textoff) or vim.o.columns
end

local function cut(str, n)
  if vim.api.nvim_strwidth(str) <= n then return str end
  return n < 1 and "" or vim.fn.strcharpart(str, 0, n - 1) .. "…"
end

-- one meaning per color, everywhere: new work green, fix rose, integration teal, branch moves sakura,
-- destructive red, history rewrites amber, housekeeping grey (remotes stay lilac, tags gold)
local KIND_HL = { commit = "GitKindNew", amend = "GitKindNew", feat = "GitKindNew", fix = "GitKindFix",
  merge = "GitKindMerge", pull = "GitKindMerge", checkout = "GitKindBranch", reset = "GitKindReset",
  rebase = "GitKindRewrite", ["cherry-pick"] = "GitKindRewrite", revert = "GitKindRewrite" }
local CONVENTIONAL = { feat = true, fix = true, chore = true, docs = true, refactor = true, test = true,
  style = true, perf = true, ci = true, build = true, revert = true }
local function kind_hl(kind) return KIND_HL[(kind or ""):gsub("!$", "")] or "GitKindChore" end

-- subject -> kind + detail, nothing dropped: "fix(api)!: x" -> "fix!", "(api) x"; merges -> "a → b"
local function kind_of(subject)
  local a, b = subject:match("^Merge branch '(.-)' into (.+)$")
  if a then return "merge", a .. " → " .. b end
  a = subject:match("^Merge branch '(.-)'$") or subject:match("^Merge remote%-tracking branch '(.-)'")
  if a then return "merge", a end
  local n, from = subject:match("^Merge pull request (#%d+) from (%S+)")
  if n then return "merge", n .. " " .. from end
  local t, scope, bang, rest = subject:match("^(%a+)(%b())(!?):%s+(.*)$")
  if not t then t, bang, rest = subject:match("^(%a+)(!?):%s+(.*)$") end
  if t and CONVENTIONAL[t:lower()] then return t:lower() .. bang, (scope and (scope .. " ") or "") .. rest end
  return nil, subject
end

-- header lines (Head/Merge/Push): same kind + detail look as the commit lists
local function subject_chunks(subject)
  if not subject or subject == "" then return {} end
  local kind, detail = kind_of(subject)
  if not kind then return { { " " .. subject } } end
  return { { " " }, { kind, kind_hl(kind) }, { " " .. detail } }
end

-- graph columns cycle GitGraph1..6 so parallel branches stay apart; author/age form one aligned column
-- and subjects are cut with … so a row never wraps in `avail` columns
local function add_commits(add, list, set, k, avail)
  local rows, w, rw, kw, aw = {}, 0, 0, 0, 0
  for _, c in ipairs(list) do
    if c.hash and not c.detail then c.kind, c.detail = kind_of(c.subject) end
    kw = math.max(kw, #(c.kind or ""))
    aw = math.max(aw, vim.api.nvim_strwidth(c.author or ""))
  end
  for i, c in ipairs(list) do
    local ch, g = {}, c.graph or ""
    for j = 1, #g do
      local x = g:sub(j, j)
      ch[#ch + 1] = { x, x == "*" and "GitGraphCommit" or x ~= " " and ("GitGraph" .. (math.floor((j - 1) / 2) % 6 + 1)) or nil }
    end
    local right
    if c.hash then
      vim.list_extend(ch, { { c.hash, "GitObjectId" }, { " " } })
      if kw > 0 then vim.list_extend(ch, { { ("%-" .. kw .. "s"):format(c.kind or ""), kind_hl(c.kind) }, { " " } }) end
      -- refs in git's own (…) so they never read as part of the message
      local rc = {}
      refchunks(c.refs, rc, set)
      if #rc > 0 then
        rc[#rc] = nil
        vim.list_extend(ch, { { "(", "GitSubtleText" } })
        vim.list_extend(ch, rc)
        ch[#ch + 1] = { ") ", "GitSubtleText" }
      end
      right = (aw > 0 and (" "):rep(aw + 1) or "") .. "   "
      rw = math.max(rw, #right)
    end
    local pw = 0
    for _, x in ipairs(ch) do pw = pw + vim.api.nvim_strwidth(x[1]) end
    rows[i] = { ch, pw, right }
    if c.hash then w = math.max(w, pw + vim.api.nvim_strwidth(c.detail)) end
  end
  w = math.min(w, 90, (avail or vim.o.columns) - rw - 2) -- column for author/age; never pushed off screen
  for i, c in ipairs(list) do
    local ch, pw, right = rows[i][1], rows[i][2], rows[i][3]
    if c.hash then
      local subj = cut(c.detail, w - pw)
      vim.list_extend(ch, { { subj }, { (" "):rep(math.max(w - pw - vim.api.nvim_strwidth(subj), 0) + 2) } })
      if aw > 0 then vim.list_extend(ch, { { c.author, "GitGraphAuthor" }, { (" "):rep(aw - vim.api.nvim_strwidth(c.author) + 1) } }) end
      ch[#ch + 1] = { ("%3s"):format(age(c.date)), "GitSubtleText" }
    end
    add(ch, c.hash and { section = k, commit = c.hash } or nil)
  end
end

-- reflog: kind = what moved HEAD ("checkout: moving from a to b" -> checkout, "a → b")
local function reflog_rows(list)
  for _, c in ipairs(list) do
    if c.hash then
      local action, rest = c.subject:match("^([^:]+):%s*(.*)$")
      action, rest = action or "?", rest or c.subject
      local kind = action:match("^commit %((.-)%)") or action:match("^(%S+)")
      c.kind = kind == "initial" and "commit" or kind
      local from, to = rest:match("^moving from (.-) to (.+)$")
      if from then
        c.detail = from .. " → " .. to
      elseif c.kind == "merge" then
        c.detail = select(2, kind_of(rest))
      else
        c.detail = (rest:gsub("^moving to ", "→ "):gsub("^returning to refs/heads/", "→ "):gsub("^refs/heads/", ""))
      end
    end
  end
  return list
end

local function render(focus)
  local buf, d = S.buf, S.data
  if not (d and buf and vim.api.nvim_buf_is_valid(buf)) then return end
  local win = vim.fn.bufwinid(buf)
  local cur = win ~= -1 and vim.api.nvim_win_get_cursor(win)[1] or 1
  local want = focus or key((S.rows[buf] or {})[cur])
  local add, L, H, R = builder()
  local st, sub = d.st, "GitSubtleText"

  local head = st.head == "(detached)" and (st.oid or ""):sub(1, 7) or (st.head or "?")
  local head_subject = st.oid == "(initial)" and "(no commits yet)" or (d.recent[1] or {}).subject -- --graph: first row is HEAD
  add(cat({ { "Head:     ", sub }, { head, "GitBranch" } }, subject_chunks(head_subject)))
  if st.upstream then add(cat({ { "Merge:    ", sub }, { st.upstream, "GitRemote" } }, subject_chunks(d.up_subject))) end
  if d.push then add(cat({ { "Push:     ", sub }, { d.push, "GitRemote" } }, subject_chunks(d.push_subject))) end
  -- PR status always shown for GitHub-ish repos; "loading…" until the first gh answer is cached
  if not S.pr then
    local f = io.open(PR_CACHE)
    local ok, t = pcall(vim.json.decode, f and f:read("*a") or "")
    if f then f:close() end
    S.pr = ok and type(t) == "table" and t or {}
  end
  local pr = S.pr[S.root .. "\0" .. head] or (HAS_GH and #d.remotes > 0 and { { { "loading…", "Comment" } } })
  for i, chunks in ipairs(pr or {}) do add(cat({ { i == 1 and "PR:       " or "          ", sub } }, chunks)) end
  local busy, s = {}, state()
  for _, b in ipairs(BUSY) do if s[b[1]] then busy[#busy + 1] = b[2] end end
  if #busy > 0 then add({ { "State:    ", sub }, { table.concat(busy, ", ") .. " in progress", "GitChangeUnmerged" } }) end
  if s.rebase then
    local function read(f)
      for _, dir in ipairs({ "rebase-merge", "rebase-apply" }) do
        local h = io.open(S.gitdir .. "/" .. dir .. "/" .. f)
        if h then
          local v = vim.trim(h:read("*a"))
          h:close()
          return v
        end
      end
    end
    add({ { "Rebasing: ", sub }, { (read("head-name") or "?"):gsub("^refs/heads/", ""), "GitBranch" },
      { " onto " }, { (read("onto") or "?"):sub(1, 7), "GitObjectId" } })
  end
  add({ { "" } })

  local function section(k, title, list, body, n)
    n = n or #list
    if n == 0 then return end
    add({ { title .. " (" .. n .. ")", "GitSectionHeader" } }, { header = true, section = k })
    if not S.fold[k] then body(list, k) end
    add({ { "" } })
  end
  local function file(f)
    local k = fkey(f)
    local chunks = f.section == "untracked" and { { f.path } }
      or { { ("%-11s"):format(LABEL[f.mode] or f.mode), MODE_HL[f.mode] }, { f.orig and (f.orig .. " -> " .. f.path) or f.path } }
    add(chunks, { section = f.section, file = f })
    local diff = S.open[k] and S.diffs[k]
    if not diff then return end
    S.open[k] = f
    if diff.conflicts then -- one compact block per conflict: where it is, then each side
      local cs = diff.conflicts
      add({ { "  " }, { #cs == 0 and "no markers left · s marks it resolved" or (#cs .. " conflict" .. (#cs > 1 and "s" or "") .. " · e merges in nvim"), "GitSubtleText" } },
        { section = f.section, file = f })
      for ci, c in ipairs(cs) do
        local function row(cl, chunks) add(chunks, { section = f.section, file = f, conflict = c, ci = ci, cl = cl }) end
        row(0, { { "  conflict " .. ci, "GitChangeUnmerged" }, { " · line " .. c.line, "GitSubtleText" } })
        local cl = 0
        for _, side in ipairs({ { "ours  ", c.ours, "GitOurs" }, { "base  ", c.base, "GitBase" }, { "theirs", c.theirs, "GitTheirs" } }) do
          local ls = side[2]
          if side[1] ~= "base  " or #ls > 0 then -- base only exists with diff3/zdiff3
            for i = 1, math.min(#ls, 3) do
              cl = cl + 1
              row(cl, { { i == 1 and ("    " .. side[1] .. "  ") or "            ", side[3] }, { ls[i], side[3] ~= "GitBase" and side[3] or "GitSubtleText" } })
            end
            if #ls == 0 then cl = cl + 1; row(cl, { { "    " .. side[1] .. "  ", side[3] }, { "(empty)", "GitSubtleText" } }) end
            if #ls > 3 then cl = cl + 1; row(cl, { { "            " }, { "… +" .. (#ls - 3) .. " lines", "GitSubtleText" } }) end
          end
        end
      end
      return
    end
    for hi, h in ipairs(diff.hunks or {}) do
      add({ { h.header, "GitHunkHeader" } }, { section = f.section, file = f, diff = diff, hunk = h, hi = hi, idx = 0 })
      for i, l in ipairs(h.lines) do
        local c = l:sub(1, 1)
        add({ { l, c == "+" and "GitDiffAdd" or c == "-" and "GitDiffDelete" or nil } },
          { section = f.section, file = f, diff = diff, hunk = h, hi = hi, idx = i })
      end
    end
  end

  local function files(list) for _, f in ipairs(list) do file(f) end end
  local function commits(list, k) add_commits(add, list, d.remoteset, k, text_width(win)) end
  section("untracked", "Untracked files", st.untracked, files)
  section("unstaged", "Unstaged changes", st.unstaged, files)
  section("staged", "Staged changes", st.staged, files)
  section("unpulled", "Unpulled from " .. (st.upstream or ""), d.unpulled, commits)
  section("unpushed", "Unmerged into " .. (st.upstream or ""), d.unpushed, commits)
  section("stashes", "Stashes", d.stashes, function(list)
    for _, z in ipairs(list) do add({ { z.ref, "GitObjectId" }, { " " .. z.subject } }, { section = "stashes", stash = z.ref }) end
  end)
  section("recent", "Recent commits", d.recent, commits, commit_count(d.recent))

  paint(buf, L, H)
  S.rows[buf] = R
  if win ~= -1 then
    local row = math.min(cur, #L)
    for r, it in pairs(R) do if key(it) == want then row = r break end end
    vim.api.nvim_win_set_cursor(win, { row, 0 })
  end
end

---------------------------------------------------------------- pull requests (gh)

local PR_STATE = { OPEN = "PrOpen", MERGED = "PrMerged", CLOSED = "PrClosed", DRAFT = "PrDraft" }
local function str(v, fb) return (v == nil or v == vim.NIL) and (fb or "") or tostring(v) end
local function pr_state(pr) return pr.isDraft == true and "DRAFT" or str(pr.state, "?") end
local function gh(args, opts, cb) git(nil, { raw = cat({ "gh" }, args), log = opts.log }, cb) end
local function json(r)
  local ok, v = pcall(vim.json.decode, r.stdout or "")
  return ok and type(v) == "table" and v or nil
end

local function ci_summary(rollup)
  local fail, pending = 0, 0
  for _, c in ipairs(type(rollup) == "table" and rollup or {}) do
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

-- integration base branch: origin/develop, origin/main, else origin/HEAD
local function find_base(cb)
  local candidates = { "origin/develop", "origin/main" }
  local function try(i)
    if i > #candidates then
      return git({ "rev-parse", "--abbrev-ref", "origin/HEAD" }, nil, function(r)
        local b = vim.trim(r.stdout or "")
        cb((r.code == 0 and b ~= "") and b or "origin/develop")
      end)
    end
    git({ "rev-parse", "--verify", "--quiet", candidates[i] }, nil, function(r)
      if r.code == 0 then cb(candidates[i]) else try(i + 1) end
    end)
  end
  try(1)
end

-- PR status under Push: state + title, then mergeable · review · CI (cached per branch, refetched on each refresh)
local function pr_line(branch)
  if not branch or branch == "(detached)" or not HAS_GH then return end
  local root, k = S.root, S.root .. "\0" .. branch
  if vim.uv.now() - (S.pr_at[k] or -math.huge) < PR_TTL then return end
  S.pr_at[k] = vim.uv.now() -- set before the call: refreshes while gh is in flight don't start another
  local function show(...)
    S.pr[k] = { ... }
    local f = io.open(PR_CACHE, "w")
    if f then f:write(vim.json.encode(S.pr)) f:close() end
    render()
  end
  gh({ "pr", "view", "--json", "number,state,isDraft,title,mergeable,reviewDecision,statusCheckRollup" }, {}, function(r)
    local pr = json(r)
    if pr and pr.number then
      local s = pr_state(pr)
      local ci, ci_hl = ci_summary(pr.statusCheckRollup)
      local mergeable = str(pr.mergeable, "?")
      return show(
        { { "#" .. str(pr.number, "?") .. " ", "Comment" }, { s, PR_STATE[s] or "Normal" }, { "  " .. str(pr.title) } },
        { { mergeable:lower(), mergeable == "CONFLICTING" and "PrClosed" or "Comment" },
          { " · review " .. (str(pr.reviewDecision) == "" and "none" or str(pr.reviewDecision):lower()), pr.reviewDecision == "APPROVED" and "PrOpen" or "Comment" },
          { " · CI ", "Comment" }, { ci, ci_hl } })
    end
    find_base(function(base)
      git({ "merge-base", "--is-ancestor", "HEAD", base }, nil, function(m)
        local merged = m.code == 0
        show({ { "no PR · ", "Comment" }, { (merged and "merged into " or "not merged into ") .. base, merged and "PrMerged" or "PrWarn" } })
      end)
    end)
  end)
end

local PR = {}

function PR.status()
  gh({ "pr", "view", "--json", "number,state,title,isDraft,mergeable,reviewDecision,statusCheckRollup,headRefName" }, {}, function(r)
    local pr = json(r)
    if not (pr and pr.number) then return vim.api.nvim_echo({ { "no PR for this branch", "Comment" } }, true, {}) end
    local s = pr_state(pr)
    local ci, ci_hl = ci_summary(pr.statusCheckRollup)
    vim.api.nvim_echo({
      { "#" .. str(pr.number, "?") .. " ", "Comment" }, { s, PR_STATE[s] or "Normal" },
      { "  " .. str(pr.title) }, { "  " .. str(pr.headRefName), "PrBranch" },
      { "\n" .. str(pr.mergeable, "?") .. " · review " .. str(pr.reviewDecision, "none") .. " · CI ", "Comment" },
      { ci, ci_hl },
    }, true, {})
  end)
end

function PR.list()
  gh({ "pr", "list", "--limit", "30", "--json", "number,title,author,headRefName,isDraft,state,reviewDecision,statusCheckRollup" }, {}, function(r)
    local prs = json(r)
    if not prs or #prs == 0 then return vim.api.nvim_echo({ { "no PRs", "Comment" } }, true, {}) end
    local chunks = {}
    for i, pr in ipairs(prs) do
      local s = pr_state(pr)
      local ci, ci_hl = ci_summary(pr.statusCheckRollup)
      local login = type(pr.author) == "table" and str(pr.author.login, "?") or "?"
      vim.list_extend(chunks, {
        { (i > 1 and "\n" or "") .. "#" .. str(pr.number, "?") .. " ", "Comment" }, { s, PR_STATE[s] or "Normal" },
        { "  " .. str(pr.title) }, { "  " .. str(pr.headRefName), "PrBranch" }, { "  @" .. login, "Comment" },
        { " · " .. str(pr.reviewDecision, "no review"), "Comment" }, { " · " .. ci, ci_hl },
      })
    end
    vim.api.nvim_echo(chunks, true, {})
  end)
end

function PR.create()
  -- blank reviewer = PR without one; only <esc> (nil) cancels
  vim.ui.input({ prompt = "Reviewer (blank = none): ", default = "juanrdlo" }, function(reviewer)
    if reviewer == nil then return end
    reviewer = vim.trim(reviewer)
    notify("creating PR…") -- gh is network-bound; show it's working
    gh(cat({ "pr", "create", "--fill" }, reviewer ~= "" and { "--reviewer", reviewer } or {}), { log = true }, function(r)
      S.pr_at = {}
      -- gh fails with "a pull request for branch ... already exists:\n<url>"
      local existing = r.code ~= 0 and (r.stderr or ""):match("already exists:%s*(https://%S+)")
      if r.code ~= 0 and not existing then return notify(r.stderr, vim.log.levels.ERROR) end
      local url = existing or vim.trim(r.stdout)
      vim.fn.setreg("+", url)
      notify((existing and "PR already exists" or "PR created") .. ", URL copied:\n" .. url)
      M.refresh()
    end)
  end)
end

function PR.open()
  gh({ "pr", "view", "--json", "url", "--jq", ".url" }, {}, function(r)
    if r.code ~= 0 then return notify(r.stderr, vim.log.levels.ERROR) end
    local url = vim.trim(r.stdout)
    vim.fn.setreg("+", url)
    vim.ui.open(url)
    notify("PR URL copied:\n" .. url)
  end)
end

function PR.close()
  if not confirm("Close the PR for this branch?") then return end
  gh({ "pr", "close" }, { log = true }, function(r)
    S.pr_at = {}
    if r.code ~= 0 then return notify(r.stderr, vim.log.levels.ERROR) end
    notify("PR closed")
    M.refresh()
  end)
end

---------------------------------------------------------------- refresh

function M.refresh()
  local buf = S.buf
  if not (S.root and buf and vim.api.nvim_buf_is_valid(buf)) then return end
  S.seq = S.seq + 1
  local seq, d, diffs, pending = S.seq, {}, {}, 0
  local function step(args, fn)
    pending = pending + 1
    git(args, nil, function(r)
      if seq ~= S.seq then return end
      fn(r)
      pending = pending - 1
      if pending > 0 then return end
      S.data, S.diffs = d, diffs
      render()
      if #d.remotes > 0 then pr_line(d.st.head) end
    end)
  end
  local function ok(r) return r.code == 0 and vim.trim(r.stdout) or nil end
  step({ "--no-optional-locks", "status", "--porcelain=v2", "--branch", "-z" }, function(r) d.st = parse_status(r.stdout) end)
  step({ "log", "--graph", "-n", tostring(RECENT), "--format=" .. LOGFMT }, function(r) d.recent = parse_log(r.stdout) end)
  step({ "log", "-n", "256", "--left-right", "--format=%m" .. LOGFMT, "HEAD...@{upstream}" }, function(r)
    d.unpulled, d.unpushed = {}, {}
    for _, c in ipairs(parse_log(r.stdout, true)) do table.insert(c.mark == ">" and d.unpulled or d.unpushed, c) end
  end)
  step({ "show", "-s", "--format=%s", "@{upstream}" }, function(r) d.up_subject = ok(r) end)
  step({ "rev-parse", "--abbrev-ref", "@{push}" }, function(r) d.push = ok(r) end)
  step({ "show", "-s", "--format=%s", "@{push}" }, function(r) d.push_subject = ok(r) end)
  step({ "stash", "list", "--format=%gd%x1f%gs" }, function(r)
    d.stashes = {}
    for _, l in ipairs(lines(r.stdout)) do
      local ref, subj = l:match("^(.-)\31(.*)$")
      if ref then d.stashes[#d.stashes + 1] = { ref = ref, subject = subj } end
    end
  end)
  step({ "remote" }, function(r)
    d.remotes, d.remoteset = lines(r.stdout), {}
    for _, x in ipairs(d.remotes) do d.remoteset[x] = true end
  end)
  for k, f in pairs(S.open) do
    if f.mode == "U" then
      diffs[k] = { conflicts = parse_conflicts(S.root .. "/" .. f.path) }
    else
      step(diff_args(f), function(r) diffs[k] = parse_diff(r.stdout) end)
    end
  end
end

---------------------------------------------------------------- applying changes

-- items under the cursor, or under the visual selection (which is ended)
local function context()
  local rows = S.rows[vim.api.nvim_get_current_buf()] or {}
  local s, e = vim.fn.line("."), vim.fn.line(".")
  local visual = vim.fn.mode():match("^[vV\22]") ~= nil
  if visual then
    s = vim.fn.line("v")
    if s > e then s, e = e, s end
    vim.api.nvim_feedkeys(vim.keycode("<esc>"), "nx", false)
  end
  local ctx = { items = {}, commits = {}, visual = visual }
  for r = s, e do
    local it = rows[r]
    if it then
      ctx.items[#ctx.items + 1] = it
      if it.commit and it.commit ~= ctx.commits[#ctx.commits] then ctx.commits[#ctx.commits + 1] = it.commit end
    end
  end
  ctx.item = visual and ctx.items[1] or rows[s]
  ctx.commit = ctx.commits[1]
  return ctx
end

-- files in the selection; a section header means every file in it
local function files(ctx)
  local out, seen = {}, {}
  for _, it in ipairs(ctx.items) do
    local list = it.header and S.data.st[it.section] or (it.file and not it.hunk and { it.file }) or {}
    for _, f in ipairs(list) do
      if not seen[fkey(f)] then seen[fkey(f)], out[#out + 1] = true, f end
    end
  end
  return out
end
local function paths(fs, pred)
  local t = {}
  for _, f in ipairs(fs) do
    if not pred or pred(f) then
      t[#t + 1] = f.path
      if f.orig then t[#t + 1] = f.orig end
    end
  end
  return t
end

-- patch for the hunk under the cursor; a visual selection inside it keeps only the selected lines.
-- reverse: the patch will be applied with -R (unstage/discard)
local function patch(ctx, reverse)
  local it, sel = ctx.item, nil
  if ctx.visual then
    sel = {}
    for _, x in ipairs(ctx.items) do if x.hunk == it.hunk and x.idx > 0 then sel[x.idx] = true end end
    if not next(sel) then sel = nil end
  end
  local out, dropped = vim.list_extend({}, it.diff.header), false
  out[#out + 1] = it.hunk.header
  for i, l in ipairs(it.hunk.lines) do
    local c = l:sub(1, 1)
    if not sel or sel[i] or c == " " then
      out[#out + 1], dropped = l, false
    elseif c == "\\" then
      if not dropped then out[#out + 1] = l end
    elseif (c == "+") == reverse then
      out[#out + 1], dropped = " " .. l:sub(2), false -- unselected: keep as context
    else
      dropped = true
    end
  end
  return table.concat(out, "\n") .. "\n"
end
local function apply(ctx, flags, reverse)
  act(cat({ "apply", "--recount" }, flags, { "-" }), { stdin = patch(ctx, reverse) })
end

local function stage(ctx)
  local it = ctx.item
  if not it or it.section == "staged" or it.commit then return end
  if it.hunk then return apply(ctx, { "--cached" }, false) end
  if it.header and it.section == "unstaged" then return act({ "add", "-u" }) end
  local fs = files(ctx)
  if #fs > 0 then act(cat({ "add", "--" }, paths(fs, function(f) return f.section ~= "staged" end))) end
end

local function unstage_all()
  if S.data and S.data.st.oid == "(initial)" then return act({ "rm", "-r", "-q", "--cached", "--", "." }) end
  act({ "reset", "-q" })
end

local function unstage(ctx)
  local it = ctx.item
  if not it or it.section ~= "staged" then return end
  if it.hunk then return apply(ctx, { "--cached", "--reverse" }, true) end
  if it.header then return unstage_all() end
  local ps = paths(files(ctx), function(f) return f.section == "staged" end)
  if #ps == 0 then return end
  if S.data.st.oid == "(initial)" then return act(cat({ "rm", "-q", "--cached", "--" }, ps)) end
  act(cat({ "restore", "--staged", "--" }, ps))
end

-- nothing is lost: tracked changes go to a backup stash first, untracked files move to .git/nkjda-trash/
local function discard(ctx)
  local it = ctx.item
  if not it or it.commit then return end
  if it.stash then
    if confirm("Drop " .. it.stash .. "?\n" .. it.stash) then act({ "stash", "drop", it.stash }) end
    return
  end
  if it.hunk and it.section ~= "untracked" then
    if not confirm("Discard hunk in " .. it.file.path .. "?") then return end
    return backup(function() apply(ctx, it.section == "staged" and { "--reverse", "--index" } or { "--reverse" }, true) end)
  end
  local fs = files(ctx)
  if #fs == 0 or not confirm(("Discard %d file(s)?\n%s"):format(#fs, describe(paths(fs)))) then return end
  local trash = S.gitdir .. "/nkjda-trash/" .. os.date("%Y%m%d-%H%M%S")
  local moved = 0
  for _, f in ipairs(fs) do
    if f.section == "untracked" then
      local dst = trash .. "/" .. f.path:gsub("/$", "")
      vim.fn.mkdir(vim.fs.dirname(dst), "p")
      local ok, err = os.rename(S.root .. "/" .. f.path:gsub("/$", ""), dst)
      if ok then moved = moved + 1 else notify("kept " .. f.path .. ": " .. tostring(err), vim.log.levels.ERROR) end
    end
  end
  if moved > 0 then notify(("moved %d untracked to %s"):format(moved, vim.fn.fnamemodify(trash, ":~:."))) end
  local tracked = vim.tbl_filter(function(f) return f.section ~= "untracked" end, fs)
  if #tracked == 0 then return M.refresh() end
  backup(function()
    local function run(args, pred)
      local ps = paths(tracked, pred)
      if #ps > 0 then act(cat(args, ps)) end
    end
    run({ "restore", "--" }, function(f) return f.section == "unstaged" end)
    run({ "rm", "-f", "-q", "--" }, function(f) return f.section == "staged" and f.mode == "A" end)
    run({ "restore", "--staged", "--worktree", "--source=HEAD", "--" }, function(f) return f.section == "staged" and f.mode ~= "A" end)
  end)
end

local function untrack(ctx)
  local ps = paths(files(ctx), function(f) return f.section ~= "untracked" end)
  if #ps > 0 then act(cat({ "rm", "-r", "-q", "--cached", "--" }, ps)) end
end

---------------------------------------------------------------- views

-- multi-file patch -> { path, orig, mode, header, hunks, add, del, binary }
local function parse_files(out)
  local files, cur, h = {}, nil, nil
  for _, l in ipairs(lines(out)) do
    local a, b = l:match("^diff %-%-git a/(.-) b/(.+)$")
    if a then
      cur, h = { path = b, orig = a ~= b and a or nil, mode = "M", header = { l }, hunks = {}, add = 0, del = 0 }, nil
      files[#files + 1] = cur
    elseif cur and l:sub(1, 2) == "@@" then
      h = { header = l, lines = {}, new = tonumber(l:match("%+(%d+)")) or 1 }
      cur.hunks[#cur.hunks + 1] = h
    elseif h then
      h.lines[#h.lines + 1] = l
      local c = l:sub(1, 1)
      if c == "+" then cur.add = cur.add + 1 elseif c == "-" then cur.del = cur.del + 1 end
    elseif cur then
      cur.header[#cur.header + 1] = l
      if l:match("^new file") then cur.mode = "A"
      elseif l:match("^deleted file") then cur.mode = "D"
      elseif l:match("^rename from") then cur.mode = "R"
      elseif l:match("^Binary files") then cur.binary = true end
    end
  end
  return files
end

-- one commit (or stash), same look as the status: header, kind-colored message, files with
-- +/− and foldable diffs (za zo zc zR zM). <cr>: parent -> that commit, diff line -> file at that line.
-- Popups (A v X r b …) act on this commit from any row. Merges diff against their first parent.
local function show(rev, opts)
  opts = opts or {}
  local hdr, files, pending = nil, nil, 2
  local function done()
    pending = pending - 1
    if pending > 0 then return end
    if not hdr then return notify(rev .. ": not found", vim.log.levels.WARN) end
    local buf = scratch((opts.stash and "stash " or "show ") .. rev, "GitCommit", {})
    local total, open = 0, {}
    for _, f in ipairs(files) do for _, h in ipairs(f.hunks) do total = total + #h.lines end end
    for i, f in ipairs(files) do open[i] = opts.focus and f.path == opts.focus or (not opts.focus and total <= 400) end
    local base = opts.stash and { stash = rev } or { commit = hdr.short }
    local function item(extra) return vim.tbl_extend("force", base, extra or {}) end
    local file_row = {}

    local function draw()
      local add, L, H, R = builder()
      local sub = "GitSubtleText"
      local head = { { "Commit   ", sub }, { hdr.short, "GitObjectId" }, { " " } }
      local rc = {}
      if not opts.stash then refchunks(hdr.refs, rc, S.data and S.data.remoteset or {}) end -- refs/stash is noise
      if #rc > 0 then
        rc[#rc] = nil
        head[#head + 1] = { "(", sub }
        vim.list_extend(head, rc)
        head[#head + 1] = { ")", sub }
      end
      add(head, item())
      add({ { "Author   ", sub }, { hdr.author, "GitGraphAuthor" }, { " <" .. hdr.email .. ">", sub },
        { " · " .. age(hdr.at) .. " · " .. os.date("%Y-%m-%d %H:%M", tonumber(hdr.at)), sub } }, item())
      if #hdr.parents > 1 and not opts.stash then
        local ch = { { "Merge    ", sub } }
        for _, par in ipairs(hdr.parents) do vim.list_extend(ch, { { par:sub(1, 7), "GitObjectId" }, { " " } }) end
        ch[#ch + 1] = { " diff vs first parent", sub }
        add(ch, item({ parents = hdr.parents }))
      end
      add({ { "" } }, item())
      local subject, on = hdr.subject, nil
      if opts.stash then -- "On main: msg" / "WIP on main: abc msg" -> msg · on main
        on, subject = subject:match("^%a+ on (.-): (.*)$")
        if not on then on, subject = hdr.subject:match("^On (.-): (.*)$") end
        subject = subject or hdr.subject
      end
      local kind, detail = kind_of(subject)
      add(cat(kind and { { kind, kind_hl(kind) }, { " " .. detail } } or { { detail } }, on and { { " · on " .. on, sub } } or {}), item())
      for _, l in ipairs(hdr.body) do add({ { l } }, item()) end
      add({ { "" } }, item())

      local A, D, pw = 0, 0, 0
      for _, f in ipairs(files) do
        A, D = A + f.add, D + f.del
        pw = math.max(pw, vim.api.nvim_strwidth(f.orig and (f.orig .. " -> " .. f.path) or f.path))
      end
      add({ { "Files (" .. #files .. ")", "GitSectionHeader" }, { "  +" .. A, "GitChangeAdded" }, { " −" .. D, "GitChangeDeleted" } }, item())
      for i, f in ipairs(files) do
        local name = f.orig and (f.orig .. " -> " .. f.path) or f.path
        local stats = f.binary and { { "binary", sub } } or { { "+" .. f.add, "GitChangeAdded" }, { " −" .. f.del, "GitChangeDeleted" } }
        add(cat({ { ("%-11s"):format(LABEL[f.mode] or f.mode), MODE_HL[f.mode] }, { name }, { (" "):rep(pw - vim.api.nvim_strwidth(name) + 2) } }, stats),
          item({ vfile = i }))
        file_row[i] = #L
        if open[i] then
          for _, h in ipairs(f.hunks) do
            add({ { h.header, "GitHunkHeader" } }, item({ vfile = i, hunk = h, idx = 0 }))
            for j, l in ipairs(h.lines) do
              local c = l:sub(1, 1)
              add({ { l, c == "+" and "GitDiffAdd" or c == "-" and "GitDiffDelete" or nil } }, item({ vfile = i, hunk = h, idx = j }))
            end
          end
        end
      end
      paint(buf, L, H)
      S.rows[buf] = R
    end
    draw()
    if opts.focus then
      for i, f in ipairs(files) do if f.path == opts.focus then pcall(vim.api.nvim_win_set_cursor, 0, { file_row[i], 0 }) end end
    end

    M.maps(buf, true)
    local o = { buffer = buf, nowait = true }
    local function cur() return (S.rows[buf] or {})[vim.fn.line(".")] or {} end
    local function fold(op)
      local i = cur().vfile
      if not i then return end
      open[i] = op == "o" or (op == "a" and not open[i])
      draw()
      vim.api.nvim_win_set_cursor(0, { file_row[i], 0 })
    end
    local function all(v)
      for i in ipairs(files) do open[i] = v end
      draw()
    end
    vim.keymap.set("n", "za", function() fold("a") end, o)
    vim.keymap.set("n", "zo", function() fold("o") end, o)
    vim.keymap.set("n", "zc", function() fold("c") end, o)
    vim.keymap.set("n", "zR", function() all(true) end, o)
    vim.keymap.set("n", "zM", function() all(false) end, o)
    vim.keymap.set("n", "<cr>", function()
      local it = cur()
      if it.parents then
        local w = vim.fn.expand("<cword>")
        for _, par in ipairs(it.parents) do if w ~= "" and vim.startswith(par, w) then return show(par) end end
        return show(it.parents[1])
      end
      local f = it.vfile and files[it.vfile]
      if not f then return end
      local abs = S.root .. "/" .. f.path
      if vim.fn.filereadable(abs) == 0 then return notify(f.path .. " no longer exists in the worktree", vim.log.levels.WARN) end
      local lnum
      if it.hunk then
        lnum = it.hunk.new
        for j = 1, it.idx - 1 do if it.hunk.lines[j]:sub(1, 1) ~= "-" then lnum = lnum + 1 end end
      end
      vim.cmd.edit(vim.fn.fnameescape(abs))
      if lnum then pcall(vim.api.nvim_win_set_cursor, 0, { math.max(lnum, 1), 0 }) end
    end, o)
  end
  git({ "log", "-1", "--format=%H%x1f%h%x1f%D%x1f%an%x1f%ae%x1f%at%x1f%P%x1f%B", rev }, nil, function(r)
    local t = vim.split(r.stdout or "", "\31", { plain = true })
    if r.code == 0 and #t >= 8 then
      local msg = vim.split(vim.trim(table.concat(vim.list_slice(t, 8), "\31")), "\n", { plain = true })
      local body = vim.list_slice(msg, 2)
      while body[1] == "" do table.remove(body, 1) end
      hdr = { short = t[2], refs = t[3], author = t[4], email = t[5], at = t[6], parents = vim.split(t[7], " ", { trimempty = true }),
        subject = msg[1] or "", body = body }
    end
    done()
  end)
  git(opts.stash and { "stash", "show", "-p", "--include-untracked", rev }
    or { "show", "--format=", "--patch", "--diff-merges=first-parent", rev }, nil, function(r)
    files = parse_files(r.stdout)
    done()
  end)
end

local function history()
  local L = {}
  for _, h in ipairs(S.history) do
    L[#L + 1] = ("%s %5dms  %s"):format(h.code == 0 and " " or "!", h.ms, h.cmd)
    for _, l in ipairs(lines(h.out)) do L[#L + 1] = "      " .. l end
  end
  scratch("history", "git", #L > 0 and L or { "no commands yet" })
end

local function goto_item()
  local it = (S.rows[vim.api.nvim_get_current_buf()] or {})[vim.fn.line(".")]
  if not it then return end
  if it.commit then return show(it.commit, { focus = vim.b.git_file }) end -- file history: open on that file
  if it.stash then return show(it.stash, { stash = true }) end
  if not it.file then return end
  local lnum = it.conflict and it.conflict.line
  if it.hunk then
    lnum = it.hunk.new
    for i = 1, it.idx - 1 do if it.hunk.lines[i]:sub(1, 1) ~= "-" then lnum = lnum + 1 end end
  end
  vim.cmd.edit(vim.fn.fnameescape(S.root .. "/" .. it.file.path))
  if lnum then pcall(vim.api.nvim_win_set_cursor, 0, { math.max(lnum, 1), 0 }) end
end

local function load(f, k)
  if f.mode == "U" then
    S.diffs[k] = { conflicts = parse_conflicts(S.root .. "/" .. f.path) }
    return render()
  end
  git(diff_args(f), nil, function(r)
    S.diffs[k] = parse_diff(r.stdout)
    render()
  end)
end

-- vim-style folds: za toggle, zo open, zc close (on a closed file: its section), zR/zM everything
local function fold(op)
  local it = (S.rows[S.buf] or {})[vim.fn.line(".")]
  if not it then return end
  if it.header then
    S.fold[it.section] = (op == "c" or (op == "a" and not S.fold[it.section])) or nil
    return render()
  end
  local f = it.file
  if not f or f.path:sub(-1) == "/" then return end
  local k = fkey(f)
  local open = S.open[k] ~= nil
  if op == "o" or (op == "a" and not open) then
    if open then return end
    S.open[k] = f
    return load(f, k)
  end
  if not open then -- zc on a closed file folds the section around it
    S.fold[f.section] = true
    return render("#" .. f.section)
  end
  S.open[k] = nil
  render(k)
end

local function fold_all(open)
  S.fold, S.open = {}, {}
  if not S.data then return end
  for _, sec in ipairs({ "untracked", "unstaged", "staged" }) do
    for _, f in ipairs(S.data.st[sec]) do
      if open and f.path:sub(-1) ~= "/" then S.open[fkey(f)] = f end
    end
  end
  if not open then
    for _, sec in ipairs({ "untracked", "unstaged", "staged", "unpulled", "unpushed", "stashes", "recent" }) do S.fold[sec] = true end
    return render()
  end
  M.refresh() -- one parallel batch fetches every diff
end

---------------------------------------------------------------- merge mode

-- e on a conflicted file: new tab, ours | theirs on top (diffed), the real file below with its
-- conflict blocks colored. co/ct/cb/c0 keep ours/theirs/both/none, q saves and returns
-- (staging the file when no markers are left). ]c [c jump conflicts here, like changes in the diffed windows
local mns = vim.api.nvim_create_namespace("nkjda_merge")

local function blocks(buf)
  local out, cur = {}, nil
  for i, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if l:match("^<<<<<<<") then cur = { s = i }
    elseif cur and l:match("^|||||||") then cur.b = i
    elseif cur and l:match("^=======$") then cur.m = i
    elseif cur and l:match("^>>>>>>>") and cur.m then cur.e = i; out[#out + 1], cur = cur, nil end
  end
  return out
end

local function paint_merge(buf)
  vim.api.nvim_buf_clear_namespace(buf, mns, 0, -1)
  for _, c in ipairs(blocks(buf)) do
    local function hl(a, b, g) for r = a, b do vim.api.nvim_buf_set_extmark(buf, mns, r - 1, 0, { line_hl_group = g }) end end
    for _, r in ipairs({ c.s, c.b, c.m, c.e }) do hl(r, r, "GitMergeMarker") end
    hl(c.s + 1, (c.b or c.m) - 1, "GitMergeOurs")
    if c.b then hl(c.b + 1, c.m - 1, "GitMergeBase") end
    hl(c.m + 1, c.e - 1, "GitMergeTheirs")
  end
end

local function merge_mode()
  local it = (S.rows[S.buf] or {})[vim.fn.line(".")]
  local f = it and it.file
  if not (f and f.mode == "U") then return notify("not a conflicted file", vim.log.levels.WARN) end
  local rel, abs = f.path, S.root .. "/" .. f.path
  local line = it.conflict and it.conflict.line
  vim.cmd.tabnew(vim.fn.fnameescape(abs))
  local mwin, mbuf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype
  local function side(stage, label, split)
    vim.cmd(split)
    local r = vim.system({ "git", "show", ":" .. stage .. ":" .. rel }, { cwd = S.root, text = true }):wait()
    local b = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(b, 0, -1, false, lines(r.stdout))
    vim.bo[b].bufhidden, vim.bo[b].modifiable, vim.bo[b].filetype = "wipe", false, ft
    pcall(vim.api.nvim_buf_set_name, b, label .. ":" .. rel)
    vim.api.nvim_win_set_buf(0, b)
    vim.cmd("diffthis")
    vim.wo.winbar = "%#Comment# " .. label .. " %*"
    return b
  end
  vim.api.nvim_set_current_win(mwin)
  local ours = side(2, "ours (HEAD)", "aboveleft split")
  local theirs = side(3, "theirs (incoming)", "rightbelow vsplit")
  vim.api.nvim_win_set_height(vim.api.nvim_get_current_win(), math.floor(vim.o.lines / 3))
  vim.api.nvim_set_current_win(mwin)
  vim.wo[mwin].winbar = "%#Comment# merged · co ours  ct theirs  cb both  c0 none  ]c [c  q done %*"

  local aug = vim.api.nvim_create_augroup("nkjda_merge", { clear = true })
  paint_merge(mbuf)
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, { group = aug, buffer = mbuf, callback = function() paint_merge(mbuf) end })

  local function jump(dir)
    local cur, list = vim.fn.line("."), blocks(mbuf)
    for i = dir > 0 and 1 or #list, dir > 0 and #list or 1, dir do
      if (dir > 0 and list[i].s > cur) or (dir < 0 and list[i].s < cur) then return vim.api.nvim_win_set_cursor(0, { list[i].s, 0 }) end
    end
  end
  local function take(which)
    local cur = vim.fn.line(".")
    for _, c in ipairs(blocks(mbuf)) do
      if cur >= c.s and cur <= c.e then
        local L = vim.api.nvim_buf_get_lines(mbuf, c.s - 1, c.e, false)
        local function part(a, b) return vim.list_slice(L, a - c.s + 1, b - c.s + 1) end
        local o, t = part(c.s + 1, (c.b or c.m) - 1), part(c.m + 1, c.e - 1)
        local keep = which == "o" and o or which == "t" and t or which == "b" and vim.list_extend(o, t) or {}
        vim.api.nvim_buf_set_lines(mbuf, c.s - 1, c.e, false, keep)
        vim.api.nvim_win_set_cursor(0, { math.min(c.s, vim.api.nvim_buf_line_count(mbuf)), 0 })
        return jump(1)
      end
    end
    notify("cursor is not inside a conflict", vim.log.levels.WARN)
  end
  local function done()
    if vim.bo[mbuf].modified then vim.api.nvim_buf_call(mbuf, function() vim.cmd("silent write") end) end
    local left = #blocks(mbuf)
    vim.api.nvim_del_augroup_by_id(aug)
    vim.api.nvim_buf_clear_namespace(mbuf, mns, 0, -1)
    for _, k in ipairs({ "co", "ct", "cb", "c0", "]c", "[c", "q" }) do pcall(vim.keymap.del, "n", k, { buffer = mbuf }) end
    vim.cmd("diffoff! | tabclose")
    if left == 0 then
      act({ "add", "--", rel }, { after = function() notify(rel .. ": resolved and staged") end })
    else
      notify(("%s: %d conflict(s) left"):format(rel, left), vim.log.levels.WARN)
      M.refresh()
    end
  end
  local o = { buffer = mbuf, nowait = true }
  vim.keymap.set("n", "co", function() take("o") end, o)
  vim.keymap.set("n", "ct", function() take("t") end, o)
  vim.keymap.set("n", "cb", function() take("b") end, o)
  vim.keymap.set("n", "c0", function() take("0") end, o)
  vim.keymap.set("n", "]c", function() jump(1) end, o)
  vim.keymap.set("n", "[c", function() jump(-1) end, o)
  for _, b in ipairs({ mbuf, ours, theirs }) do vim.keymap.set("n", "q", done, { buffer = b, nowait = true }) end
  if line then vim.api.nvim_win_set_cursor(mwin, { line, 0 }) else vim.api.nvim_win_set_cursor(mwin, { 1, 0 }); jump(1) end
end

local function log_view(args, name, file)
  git(args, nil, function(r)
    if vim.trim(r.stdout or "") == "" then return notify(name .. ": no history", vim.log.levels.WARN) end
    local add, L, H, R = builder()
    local list = parse_log(r.stdout)
    if name == "reflog" then reflog_rows(list) end
    add_commits(add, list, S.data and S.data.remoteset or {}, "log", text_width(vim.api.nvim_get_current_win()))
    local buf = scratch(name, "GitLog", {})
    vim.b[buf].git_file = file
    paint(buf, L, H)
    S.rows[buf] = R
    M.maps(buf, true)
  end)
end

function M.command(cmd)
  local function go(c) act(nil, { raw = { "sh", "-c", "git " .. c }, show = true }) end
  if cmd and cmd ~= "" then return go(cmd) end
  input("git ", nil, go)
end

-- d: plain vimdiff of the file under the cursor vs HEAD, no plugins
-- ponytail: untracked files have no HEAD to diff, so they warn
local function vimdiff()
  local it = (S.rows[S.buf] or {})[vim.fn.line(".")]
  if not (it and it.file) then return notify("no file under cursor", vim.log.levels.WARN) end
  if it.file.mode == "U" then return merge_mode() end -- HEAD alone says nothing about a conflict
  local root, rel = S.root, it.file.path
  vim.fn.system({ "git", "-C", root, "cat-file", "-e", "HEAD:" .. rel })
  if vim.v.shell_error ~= 0 then return notify("untracked: nothing in HEAD to diff", vim.log.levels.WARN) end
  -- ponytail: one diff at a time; repeat-d replaces instead of stacking splits
  vim.cmd("diffoff!")
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.b[b].git_head_scratch then vim.api.nvim_buf_delete(b, { force = true }) end
  end
  local abs = root .. "/" .. rel
  if vim.fn.filereadable(abs) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(abs))
  else
    vim.cmd("enew") -- deleted in worktree: empty side still diffs vs HEAD
    vim.bo.buftype = "nofile"
  end
  vim.b.git_work_diff = true
  local work_win = vim.api.nvim_get_current_win()
  local ft = vim.bo.filetype
  vim.cmd("diffthis")
  vim.api.nvim_set_option_value("winbar", "%#Comment# working %*", { win = work_win })
  local head = vim.fn.systemlist({ "git", "-C", root, "show", "HEAD:" .. rel })
  vim.cmd("vnew")
  local head_win = vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, head)
  pcall(vim.api.nvim_buf_set_name, 0, "HEAD:" .. rel)
  vim.bo.filetype = ft
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.buflisted = false
  vim.bo.swapfile = false
  vim.bo.readonly = true
  vim.bo.modifiable = false
  vim.b.git_head_scratch = true
  vim.cmd("diffthis")
  vim.api.nvim_set_option_value("winbar", "%#Comment# head %*", { win = head_win })
end

-- :DiffOff closes the diff (HEAD split + labels) and goes back to the status
vim.api.nvim_create_user_command("DiffOff", function()
  local closed = false
  vim.cmd("diffoff!")
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.b[b].git_head_scratch or vim.b[b].git_work_diff then
      vim.api.nvim_set_option_value("winbar", "", { win = w })
      if vim.b[b].git_head_scratch then
        vim.api.nvim_buf_delete(b, { force = true })
      else
        vim.b[b].git_work_diff = nil
      end
      closed = true
    end
  end
  if closed then M.open() end
end, { desc = "Close diff, back to git status" })

---------------------------------------------------------------- popups

-- def = { title, args = { {key, flag, desc} }, groups = { {title, { {key, desc, fn(args, ctx)} }} } }
-- -<key> toggles an argument (remembered per popup), q/<esc> closes
local function popup(def)
  local ctx = context()
  local on = S.switches[def.title] or {}
  S.switches[def.title] = on
  local src = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local groups = vim.tbl_filter(function(g) return #g[2] > 0 end, def.groups)
  local win

  local function draw()
    local L, H = {}, {}
    if def.args and #def.args > 0 then
      L[1] = " Arguments"
      H[1] = { 0, 1, 10, "GitSectionHeader" }
      for _, a in ipairs(def.args) do
        local head = " -" .. a[1] .. " " .. a[3] .. " "
        L[#L + 1] = head .. "(" .. a[2] .. ")"
        H[#H + 1] = { #L - 1, 1, 3, "GitPopupSwitchKey" }
        H[#H + 1] = { #L - 1, #head, #L[#L], on[a[2]] and "GitPopupSwitchEnabled" or "GitSubtleText" }
      end
      L[#L + 1] = ""
    end
    local top, x = #L, 1
    for _, g in ipairs(groups) do
      local w = #g[1]
      for i = 0, #g[2] do
        local a = g[2][i]
        local cell = a and (a[1] .. " " .. a[2]) or g[1]
        local r = top + i + 1
        L[r] = L[r] or ""
        L[r] = L[r] .. (" "):rep(x - #L[r]) .. cell
        H[#H + 1] = { r - 1, x, x + (a and #a[1] or #g[1]), a and "GitPopupActionKey" or "GitSectionHeader" }
        w = math.max(w, #cell)
      end
      x = x + w + 4
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, L)
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for _, h in ipairs(H) do vim.api.nvim_buf_set_extmark(buf, ns, h[1], h[2], { end_col = h[3], hl_group = h[4] }) end
    return #L
  end

  draw()
  win = vim.api.nvim_open_win(buf, true, { split = "below", win = -1, height = require("nkjda.select").height })
  for o, v in pairs({ number = false, relativenumber = false, signcolumn = "no", cursorline = false,
    winfixheight = true, list = false, foldcolumn = "0" }) do
    vim.wo[win][o] = v
  end
  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    if vim.api.nvim_win_is_valid(src) then vim.api.nvim_set_current_win(src) end
  end
  local o = { buffer = buf, nowait = true }
  for _, g in ipairs(groups) do
    for _, a in ipairs(g[2]) do
      vim.keymap.set("n", a[1], function()
        local t = {}
        for _, s in ipairs(def.args or {}) do if on[s[2]] then t[#t + 1] = s[2] end end
        close()
        a[3](t, ctx)
      end, o)
    end
  end
  vim.keymap.set("n", "-", function()
    local c = vim.fn.getcharstr()
    for _, s in ipairs(def.args or {}) do if s[1] == c then on[s[2]] = not on[s[2]] or nil end end
    draw()
  end, o)
  for _, k in ipairs({ "q", "<esc>" }) do vim.keymap.set("n", k, close, o) end
end

local P = {}

local function sequencer(cmd, key) -- continue/skip/abort group for an in-progress operation
  return { "Sequencer", {
    { key, "Continue", function() act({ cmd, "--continue" }) end },
    { "s", "Skip", function() act({ cmd, "--skip" }) end },
    { "a", "Abort", function() act({ cmd, "--abort" }) end },
  } }
end

function P.commit()
  local function fix(kind)
    return function(_, ctx) commits(ctx, function(cs) act({ "commit", "--" .. kind .. "=" .. cs[1] }) end) end
  end
  popup({ title = "Commit",
    args = { { "a", "--all", "Stage all modified and deleted files" }, { "e", "--allow-empty", "Allow empty commit" },
      { "v", "--verbose", "Show diff of changes to be committed" }, { "n", "--no-verify", "Disable hooks" } },
    groups = {
      { "Create", { { "c", "Commit", function(a) act(cat({ "commit" }, a)) end } } },
      { "Edit HEAD", {
        { "e", "Extend", function(a) act(cat({ "commit", "--amend", "--no-edit" }, a)) end },
        { "a", "Amend", function(a) act(cat({ "commit", "--amend" }, a)) end },
        { "w", "Reword", function(a) act(cat({ "commit", "--amend", "--only" }, a)) end },
      } },
      { "Edit", {
        { "f", "Fixup", fix("fixup") },
        { "s", "Squash", fix("squash") },
        { "F", "Instant fixup", function(_, ctx)
          commits(ctx, function(cs)
            act({ "commit", "--fixup=" .. cs[1] }, { after = function()
              act({ "rebase", "-i", "--autosquash", "--autostash", base_of(cs[1]) }, { env = { GIT_SEQUENCE_EDITOR = "true" } })
            end })
          end)
        end },
      } },
    } })
end

function P.branch()
  local function at(ctx) return ctx.commit and { ctx.commit } or {} end
  popup({ title = "Branch", groups = {
    { "Checkout", {
      { "b", "Branch/revision", function()
        refs({ "refs/heads", "refs/remotes" }, function(l)
          pick("Checkout", l, function(b)
            local r, rest = b:match("^([^/]+)/(.+)$")
            -- remote ref: switch to (or DWIM-create) the local tracking branch
            act({ "switch", (r and S.data.remoteset[r]) and rest or b })
          end)
        end)
      end },
      { "r", "Recent (previous branch)", function() act({ "switch", "-" }) end }, -- toggles between the last two
      { "l", "Local branch", function() refs({ "refs/heads" }, function(l) pick("Checkout", l, function(b) act({ "switch", b }) end) end) end },
      { "c", "New branch", function(_, ctx) input("New branch: ", nil, function(n) act(cat({ "switch", "-c", n }, at(ctx))) end) end },
    } },
    { "Create", {
      { "n", "New branch", function(_, ctx) input("Create branch: ", nil, function(n) act(cat({ "branch", n }, at(ctx))) end) end },
    } },
    { "Do", {
      { "m", "Rename", function()
        refs({ "refs/heads" }, function(l)
          pick("Rename", l, function(b) input("Rename " .. b .. " to: ", b, function(n) act({ "branch", "-m", b, n }) end) end)
        end)
      end },
      { "u", "Set upstream", function()
        refs({ "refs/remotes" }, function(l) pick("Upstream", l, function(u) act({ "branch", "-u", u }) end) end)
      end },
      { "D", "Delete", function()
        refs({ "refs/heads" }, function(l)
          pick("Delete branch", l, function(b)
            git({ "branch", "-d", b }, { log = true }, function(r)
              if r.code == 0 then return M.refresh() end
              if confirm(b .. " is not fully merged. Force delete?") then act({ "branch", "-D", b }) end
            end)
          end)
        end)
      end },
    } },
  } })
end

function P.bisect()
  local s = state()
  popup({ title = "Bisect", groups = s.bisect and {
    { "Bisect", {
      { "g", "Good", function() act({ "bisect", "good" }, { show = true }) end },
      { "b", "Bad", function() act({ "bisect", "bad" }, { show = true }) end },
      { "s", "Skip", function() act({ "bisect", "skip" }, { show = true }) end },
      { "R", "Run script", function() input("Run: ", nil, function(c) act({ "bisect", "run", "sh", "-c", c }, { show = true, msg = "Bisecting" }) end) end },
      { "r", "Reset", function() act({ "bisect", "reset" }) end },
    } },
  } or {
    { "Bisect", {
      { "B", "Start (HEAD bad)", function(_, ctx)
        local function go(good) act({ "bisect", "start", "HEAD", good }, { show = true }) end
        if ctx.commit then go(ctx.commit) else input("Good commit: ", nil, go) end
      end },
    } },
  } })
end

function P.cherry()
  local s = state()
  local function go(extra)
    return function(a, ctx)
      commits(ctx, function(cs) act(cat({ "cherry-pick" }, extra, a, vim.fn.reverse(cs))) end) -- oldest first
    end
  end
  popup({ title = "Cherry Pick",
    args = { { "x", "-x", "Reference cherry in commit message" }, { "e", "--edit", "Edit commit message" }, { "f", "--ff", "Fast-forward when possible" } },
    groups = s.pick and { sequencer("cherry-pick", "A") } or {
      { "Apply here", { { "A", "Pick", go({}) }, { "a", "Apply (no commit)", go({ "--no-commit" }) } } },
    } })
end

function P.revert()
  local s = state()
  local function go(extra)
    return function(a, ctx) commits(ctx, function(cs) act(cat({ "revert" }, extra, a, cs)) end) end
  end
  popup({ title = "Revert",
    args = { { "e", "--edit", "Edit commit message" } },
    groups = s.revert and { sequencer("revert", "v") } or {
      { "Revert", { { "v", "Commit(s)", go({}) }, { "V", "Changes (no commit)", go({ "--no-commit" }) } } },
    } })
end

function P.fetch()
  local up = S.data and S.data.st.upstream and S.data.st.upstream:match("^[^/]+")
  popup({ title = "Fetch",
    args = { { "p", "--prune", "Prune deleted branches" }, { "t", "--tags", "Fetch all tags" } },
    groups = { { "Fetch from", {
      { "u", up or "upstream", function(a) if up then act(cat({ "fetch" }, a, { up }), { msg = "Fetching", show = true }) end end },
      { "a", "All remotes", function(a) act(cat({ "fetch", "--all" }, a), { msg = "Fetching", show = true }) end },
      { "e", "Elsewhere", function(a)
        pick("Fetch", S.data.remotes, function(r) act(cat({ "fetch" }, a, { r }), { msg = "Fetching", show = true }) end)
      end },
    } },
    -- big repos: hourly prefetch + commit-graph, so the auto-fetch and log --graph stay instant
    { "Repo", { { "m", "Maintenance start", function() act({ "maintenance", "start" }, { msg = "Registering maintenance" }) end } } },
  } })
end

function P.remote()
  popup({ title = "Remote",
    args = { { "f", "-f", "Fetch after add" } },
    groups = { { "Remote", {
      { "a", "Add", function(a)
        input("Remote name: ", #S.data.remotes == 0 and "origin" or nil, function(n)
          input("URL: ", nil, function(u) act(cat({ "remote", "add" }, a, { n, u })) end)
        end)
      end },
      { "r", "Rename", function()
        pick("Rename remote", S.data.remotes, function(r) input("Rename " .. r .. " to: ", r, function(n) act({ "remote", "rename", r, n }) end) end)
      end },
      { "u", "Set URL", function()
        if #S.data.remotes == 0 then -- no remote yet: set-url means "add origin"
          return input("URL for origin: ", nil, function(u) act({ "remote", "add", "origin", u }) end)
        end
        pick("Remote", S.data.remotes, function(r) input("URL: ", nil, function(u) act({ "remote", "set-url", r, u }) end) end)
      end },
      { "x", "Remove", function()
        pick("Remove remote", S.data.remotes, function(r) if confirm("Remove remote " .. r .. "?") then act({ "remote", "remove", r }) end end)
      end },
    } } } })
end

function P.merge()
  fetch_bg()
  local function go(extra)
    return function(a)
      fetch_bg(function()
        refs({ "refs/heads", "refs/remotes" }, function(l) pick("Merge", l, function(b) act(cat({ "merge" }, extra, a, { b })) end) end)
      end)
    end
  end
  popup({ title = "Merge",
    args = { { "f", "--ff-only", "Fast-forward only" }, { "n", "--no-ff", "No fast-forward" } },
    groups = state().merge and {
      { "Actions", { { "m", "Commit merge", function() act({ "commit", "--no-edit" }) end }, { "a", "Abort", function() act({ "merge", "--abort" }) end } } },
    } or {
      { "Actions", {
        { "m", "Merge", go({ "--no-edit" }) },
        { "e", "Merge, edit message", go({ "--edit", "--no-ff" }) },
        { "n", "Merge, don't commit", go({ "--no-commit", "--no-ff" }) },
        { "s", "Squash merge", go({ "--squash" }) },
      } },
    } })
end

function P.pull()
  fetch_bg()
  local up = S.data and S.data.st.upstream
  local function elsewhere(a)
    refs({ "refs/remotes" }, function(l)
      pick("Pull from", l, function(b)
        local r, br = b:match("^([^/]+)/(.+)$")
        act(cat({ "pull" }, a, { r, br }), { msg = "Pulling", show = true })
      end)
    end)
  end
  popup({ title = "Pull",
    args = { { "r", "--rebase", "Rebase local commits" }, { "f", "--ff-only", "Fast-forward only" }, { "a", "--autostash", "Autostash" } },
    groups = { { "Pull into " .. (S.data and S.data.st.head or "HEAD") .. " from", {
      { "p", up or "upstream (pick)", function(a)
        fetch_bg(function()
          if up then act(cat({ "pull" }, a), { msg = "Pulling", show = true }) else elsewhere(a) end
        end)
      end },
      { "e", "Elsewhere", function(a) fetch_bg(function() elsewhere(a) end) end },
    } } } })
end

-- --force, or a lease onto a shared branch, asks first
local function push_ok(a, target)
  local force, lease = vim.tbl_contains(a, "--force"), vim.tbl_contains(a, "--force-with-lease")
  local shared = (target or ""):match("[/:]?main$") or (target or ""):match("master$") or (target or ""):match("develop$")
  if force then return confirm("Force push to " .. (target or "remote") .. "? This overwrites remote commits.") end
  if lease and shared then return confirm("Force (lease) push to shared branch " .. target .. "?") end
  return true
end

function P.push()
  fetch_bg()
  local d = S.data or { st = {} }
  local function tags(cb) git({ "tag", "--sort=-creatordate" }, nil, function(r) pick("Tag", lines(r.stdout), cb) end) end
  popup({ title = "Push",
    args = { { "f", "--force-with-lease", "Force with lease" }, { "F", "--force", "Force" },
      { "u", "--set-upstream", "Set upstream" }, { "h", "--no-verify", "Disable hooks" }, { "n", "--dry-run", "Dry run" } },
    groups = {
      { "Push " .. (d.st.head or "HEAD") .. " to", {
        { "p", d.push or d.st.upstream or "remote (sets upstream)", function(a)
          fetch_bg(function()
            if not push_ok(a, d.push or d.st.upstream) then return end
            local function pushed() S.pr_at = {} end
            if d.st.upstream then return act(cat({ "push" }, a), { msg = "Pushing", show = true, after = pushed }) end
            remote(function(r) act(cat({ "push", "-u" }, a, { r, "HEAD" }), { msg = "Pushing", show = true, after = pushed }) end)
          end)
        end },
        { "e", "Elsewhere", function(a)
          fetch_bg(function()
            refs({ "refs/remotes" }, function(l)
              pick("Push to", l, function(b)
                local r, br = b:match("^([^/]+)/(.+)$")
                if push_ok(a, b) then act(cat({ "push" }, a, { r, "HEAD:refs/heads/" .. br }), { msg = "Pushing", show = true }) end
              end)
            end)
          end)
        end },
      } },
      { "Push", {
        { "t", "All tags", function(a) remote(function(r) act(cat({ "push" }, a, { r, "--tags" }), { msg = "Pushing tags", show = true }) end) end },
        { "T", "A tag", function(a)
          tags(function(t) remote(function(r) act(cat({ "push" }, a, { r, "refs/tags/" .. t }), { msg = "Pushing " .. t, show = true }) end) end)
        end },
      } },
    } })
end

function P.rebase()
  local up = S.data and S.data.st.upstream
  popup({ title = "Rebase",
    args = { { "a", "--autostash", "Autostash" }, { "k", "--keep-empty", "Keep empty commits" } },
    groups = state().rebase and {
      { "Actions", {
        { "r", "Continue", function() act({ "rebase", "--continue" }) end },
        { "s", "Skip", function() act({ "rebase", "--skip" }) end },
        { "e", "Edit todo", function() act({ "rebase", "--edit-todo" }) end },
        { "a", "Abort", function() act({ "rebase", "--abort" }) end },
      } },
    } or {
      { "Rebase " .. (S.data and S.data.st.head or "HEAD") .. " onto", {
        { "u", up or "upstream", function(a) if up then act(cat({ "rebase" }, a, { up })) end end },
        { "e", "Elsewhere", function(a)
          refs({ "refs/heads", "refs/remotes" }, function(l) pick("Rebase onto", l, function(b) act(cat({ "rebase" }, a, { b })) end) end)
        end },
      } },
      { "Rebase", {
        { "i", "Interactively", function(a, ctx) commits(ctx, function(cs) act(cat({ "rebase", "-i" }, a, { base_of(cs[1]) })) end) end },
        { "f", "Autosquash", function(a, ctx)
          commits(ctx, function(cs) act(cat({ "rebase", "-i", "--autosquash" }, a, { base_of(cs[1]) })) end)
        end },
      } },
    } })
end

function P.tag()
  fetch_bg()
  popup({ title = "Tag",
    args = { { "a", "--annotate", "Annotate (opens editor)" }, { "f", "--force", "Force" } },
    groups = { { "Tag", {
      { "t", "Create", function(a, ctx)
        input("Tag name: ", nil, function(n) act(cat({ "tag" }, a, { n, ctx.commit })) end)
      end },
      { "x", "Delete", function()
        fetch_bg(function()
          git({ "tag", "--sort=-creatordate" }, nil, function(r)
            pick("Delete tag", lines(r.stdout), function(t)
              act({ "tag", "-d", t }, { after = function()
                remote(function(rm)
                  if confirm("Also delete " .. t .. " on " .. rm .. "?") then act({ "push", rm, ":refs/tags/" .. t }, { msg = "Deleting remote tag" }) end
                end)
              end })
            end)
          end)
        end)
      end },
    } } } })
end

function P.log()
  local f = "--format=" .. LOGFMT
  popup({ title = "Log", groups = { { "Log", {
    { "l", "Current branch", function() log_view({ "log", "--graph", "-n", "256", f }, "log") end },
    { "a", "All branches", function() log_view({ "log", "--graph", "--all", "-n", "256", f }, "log --all") end },
    -- the file under the cursor, else the buffer the status was opened from; --follow keeps history across renames
    { "f", "Current file", function(_, ctx)
      local path = ctx.item and ctx.item.file and ctx.item.file.path
      if not path and S.prev and vim.api.nvim_buf_is_valid(S.prev) then
        local name = vim.api.nvim_buf_get_name(S.prev)
        if vim.startswith(name, S.root .. "/") then path = name:sub(#S.root + 2) end
      end
      if not path then return notify("no file under cursor or in the previous buffer", vim.log.levels.WARN) end
      log_view({ "log", "--follow", "-n", "256", f, "--", path }, "log " .. path, path)
    end },
    -- every place HEAD has been: the undo list for rebase/reset/amend. %gs = what moved it,
    -- %gd with --date=unix = when it moved (not the commit's date); no author, it's always you
    { "r", "Reflog (undo)", function()
      log_view({ "reflog", "-n", "256", "--date=unix", "--format=%h%x1f%x1f%gs%x1f%x1f%gd" }, "reflog")
    end },
  } } } })
end

function P.reset()
  local function go(mode)
    return function(_, ctx)
      local function run(c)
        if mode ~= "--hard" then return act({ "reset", mode, c }) end
        if not confirm("Hard reset to " .. c .. "? Uncommitted changes go to a backup stash.") then return end
        backup(function() act({ "reset", "--hard", c }) end)
      end
      if ctx.commit then run(ctx.commit) else input("Reset to: ", "HEAD", run) end
    end
  end
  popup({ title = "Reset", groups = { { "Reset HEAD to commit at cursor", {
    { "s", "Soft (keep changes staged)", go("--soft") },
    { "m", "Mixed (keep changes unstaged)", go("--mixed") },
    { "k", "Keep (refuse if it would lose changes)", go("--keep") },
    { "h", "Hard (backup stash first)", go("--hard") },
  } } } })
end

function P.stash()
  local function target(ctx, cb)
    if ctx.item and ctx.item.stash then return cb(ctx.item.stash) end
    local list = {}
    for _, z in ipairs(S.data and S.data.stashes or {}) do list[#list + 1] = z.ref .. " " .. z.subject end
    pick("Stash", list, function(c) cb(c:match("^%S+")) end)
  end
  popup({ title = "Stash",
    args = { { "u", "--include-untracked", "Include untracked files" }, { "k", "--keep-index", "Keep staged changes" } },
    groups = {
      { "Stash", {
        { "z", "Both", function(a) act(cat({ "stash", "push" }, a)) end },
        { "i", "Index only", function() act({ "stash", "push", "--staged" }) end },
        { "m", "With message", function(a) input("Stash message: ", nil, function(m) act(cat({ "stash", "push" }, a, { "-m", m })) end) end },
      } },
      { "Use", {
        { "p", "Pop", function(_, ctx) target(ctx, function(z) act({ "stash", "pop", "--index", z }) end) end },
        { "a", "Apply", function(_, ctx) target(ctx, function(z) act({ "stash", "apply", "--index", z }) end) end },
        { "d", "Drop", function(_, ctx) target(ctx, function(z) if confirm("Drop " .. z .. "?") then act({ "stash", "drop", z }) end end) end },
      } },
    } })
end

function P.pr()
  popup({ title = "PRs", groups = {
    { "Pull request", {
      { "p", "Status", PR.status },
      { "l", "List", PR.list },
      { "o", "Open + copy URL", PR.open },
    } },
    { "Do", {
      { "n", "Create (reviewer)", PR.create },
      { "x", "Close", PR.close },
    } },
  } })
end

---------------------------------------------------------------- keys

local function close()
  if S.prev and S.prev ~= S.buf and vim.api.nvim_buf_is_valid(S.prev) then
    vim.api.nvim_win_set_buf(0, S.prev)
  else
    vim.cmd.enew()
  end
end

local function with(fn) return function() fn(context()) end end

local KEYS
local function help()
  local groups = {}
  for _, g in ipairs(KEYS) do
    local acts = {}
    for _, k in ipairs(g[2]) do acts[#acts + 1] = { k[1], k[2], function() k[3]() end } end
    groups[#groups + 1] = { g[1], acts }
  end
  popup({ title = "Help", groups = groups })
end

-- { key, desc, fn, visual? }
KEYS = {
  { "Commands", {
    { "$", "History", history }, { "A", "Cherry Pick", P.cherry, true }, { "b", "Branch", P.branch },
    { "B", "Bisect", P.bisect }, { "c", "Commit", P.commit }, { "f", "Fetch", P.fetch },
    { "l", "Log / reflog", P.log }, { "M", "Remote", P.remote }, { "m", "Merge", P.merge },
  } },
  { "", {
    { "O", "PRs", P.pr }, { "p", "Pull", P.pull }, { "P", "Push", P.push }, { "Q", "Command", M.command },
    { "r", "Rebase", P.rebase }, { "t", "Tag", P.tag }, { "v", "Revert", P.revert, true }, { "X", "Reset", P.reset },
    { "Z", "Stash", P.stash },
  } },
  { "Applying changes", {
    { "<c-s>", "Stage all", function() act({ "add", "-A" }) end }, { "K", "Untrack", with(untrack), true },
    { "s", "Stage", with(stage), true }, { "S", "Stage unstaged", function() act({ "add", "-u" }) end },
    { "u", "Unstage", with(unstage), true }, { "U", "Unstage all", unstage_all }, { "x", "Discard", with(discard), true },
    { "d", "Diff mode (against HEAD)", vimdiff }, { "e", "Merge mode (conflict)", merge_mode },
  } },
  { "Essential commands", {
    { "<c-r>", "Refresh", M.refresh }, { "<cr>", "Go to file", goto_item },
    { "za", "Toggle fold", function() fold("a") end }, { "zo", "Open fold", function() fold("o") end },
    { "zc", "Close fold", function() fold("c") end }, { "zR", "Open all", function() fold_all(true) end },
    { "zM", "Close all", function() fold_all(false) end },
    { "?", "Help", help }, { "q", "Close", close },
  } },
}

-- log view only gets the commands + <cr>/?: applying keys mean nothing there
function M.maps(buf, log)
  for gi, g in ipairs(KEYS) do
    for _, k in ipairs(g[2]) do
      if not log or gi <= 2 or k[1] == "<cr>" or k[1] == "?" then
        vim.keymap.set(k[4] and { "n", "x" } or "n", k[1], k[3], { buffer = buf, nowait = true, desc = k[2] })
      end
    end
  end
end

---------------------------------------------------------------- open / editor

-- ~ is a dotfiles repo: a non-repo subdir must not fall back to it, offer git init instead
function M.open()
  local cwd, home = vim.uv.cwd(), vim.uv.os_homedir()
  local r = vim.system({ "git", "rev-parse", "--show-toplevel", "--absolute-git-dir" }, { cwd = cwd, text = true }):wait()
  local root, gitdir = unpack(lines(r.stdout))
  if r.code ~= 0 or (root == home and cwd ~= home) then
    if not confirm("Not a git repo. git init in " .. cwd .. "?") then return end
    vim.system({ "git", "init", cwd }):wait()
    root, gitdir = cwd, cwd .. "/.git"
  end
  if root ~= S.root then
    S.open, S.diffs, S.data, S.fetch.at = {}, {}, nil, -math.huge
  end
  S.root, S.gitdir = root, gitdir
  S.pr_at = {} -- opening always rechecks the PR

  if not (S.buf and vim.api.nvim_buf_is_valid(S.buf)) then
    S.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(S.buf, "git://status")
    vim.bo[S.buf].filetype = "GitStatus"
    vim.bo[S.buf].modifiable = false
    M.maps(S.buf)
    -- BufWinEnter, not BufEnter: coming back from a popup/picker window is not a reason to refresh
    vim.api.nvim_create_autocmd("BufWinEnter", { buffer = S.buf, callback = function() M.refresh() end })
    vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained" }, { callback = function()
      if S.buf and vim.fn.bufwinid(S.buf) ~= -1 then M.refresh() end
    end })
    vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, { callback = function() render() end }) -- subjects re-fit
  end
  local cur = vim.api.nvim_get_current_buf()
  if cur ~= S.buf then
    S.prev = cur
    vim.api.nvim_win_set_buf(0, S.buf) -- BufWinEnter refreshes
  else
    M.refresh()
  end
  fetch_bg()
end

-- called by $GIT_EDITOR over RPC: edit the file here; closing the buffer lets git continue.
-- closed without :w (or <c-c><c-k>) -> the file is emptied, which makes git abort
function M.edit(path)
  vim.schedule(function()
    local win = S.buf and vim.fn.bufwinid(S.buf) or -1
    if win ~= -1 then vim.api.nvim_set_current_win(win) end
    -- split, so :wq closes just the editor and lands back on the status
    vim.cmd("aboveleft split " .. vim.fn.fnameescape(path))
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].bufhidden = "wipe"
    local written = false
    vim.api.nvim_create_autocmd("BufWritePost", { buffer = buf, callback = function() written = true end })
    vim.api.nvim_create_autocmd("BufUnload", { buffer = buf, once = true, callback = function()
      if not written then
        local f = io.open(path, "w")
        if f then f:close() end
      end
      os.remove(path .. ".nvlock")
    end })
    local o = { buffer = buf }
    vim.keymap.set({ "n", "i" }, "<c-c><c-c>", function() vim.cmd("stopinsert | write | bwipeout") end, o)
    vim.keymap.set({ "n", "i" }, "<c-c><c-k>", function() written = false; vim.cmd("stopinsert | bwipeout!") end, o)
    if vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "" then vim.cmd.startinsert() end
  end)
end

return M
