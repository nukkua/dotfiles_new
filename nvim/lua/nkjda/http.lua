-- nkjda/http.lua — .http REST client on curl
-- ponytail: REST only — no gRPC, websockets, GraphQL, LSP, `import`/`run`

local Auth = require("nkjda.http_auth")
local Script = require("nkjda.http_script")
local M = {}

local S = {
  history = {}, idx = 0, view = "body",
  named = {},   -- `### Name` -> { request = {...}, response = {...} } for {{Name.response...}}
  runtime = {}, -- vars set by @env-json-key / @env-header-key / @prompt
  env = "default",
  job = nil, queue = nil,
}
local jar = vim.fn.stdpath("data") .. "/http/cookies.txt"

---------------------------------------------------------------- parsing

local function is_comment(l) return l:match("^%s*#") or l:match("^%s*//") end

-- split a .http buffer into blocks + document vars (`@k=v`, later wins)
function M.parse_doc(lines)
  local doc = { vars = {}, blocks = {} }
  local cur = { s = 1 }
  for i, l in ipairs(lines) do
    local k, v = l:match("^@([%w_.-]+)%s*=%s*(.-)%s*$")
    if k then doc.vars[k] = v end
    if l:match("^###") then
      cur.e = i - 1
      table.insert(doc.blocks, cur)
      cur = { s = i + 1, name = vim.trim(l:sub(4)) ~= "" and vim.trim(l:sub(4)) or nil }
    end
  end
  cur.e = #lines
  table.insert(doc.blocks, cur)
  return doc
end

-- parse one block into a request (nil when it holds no request line)
function M.parse_block(lines, blk)
  local r = { name = blk.name, line = blk.s, headers = {}, body = {}, pre = {}, post = {},
    meta = { prompt = {}, curl = {}, json_key = {}, header_key = {} } }
  local state, script = "start", nil
  for i = blk.s, blk.e do
    local l = lines[i]
    local mk, mv = l:match("^%s*#%s*@([%w_-]+)%s*(.-)%s*$")
    local sdir, sfile = l:match("^%s*([<>])%s*([^<>%s{]%S*%.js)%s*$")
    if not sfile then sdir, sfile = l:match("^%s*([<>])%s*([^<>%s{]%S*%.lua)%s*$") end
    if script then
      local last = l:match("^(.-)%%}")
      table.insert(script.lines, last or l)
      if last then script.code, script = table.concat(script.lines, "\n"), nil end
    elseif l:match("^%s*[<>]%s*{%%") then
      -- `< {% pre-request %}` / `> {% post-request %}`, inline or multi-line
      local d, rest = l:match("^%s*([<>])%s*{%%(.*)$")
      local s = { lines = {} }
      table.insert(d == "<" and r.pre or r.post, s)
      local inline = rest:match("^(.-)%%}%s*$")
      if inline then s.code = inline else table.insert(s.lines, rest); script = s end
    elseif sfile then
      table.insert(sdir == "<" and r.pre or r.post, { file = sfile })
    elseif mk then
      if mk == "name" then r.name = mv
      elseif mk == "prompt" or mk == "secret" then
        local var, text = mv:match("^(%S+)%s*(.*)$")
        if var then table.insert(r.meta.prompt, { var = var, text = text ~= "" and text or var, secret = mk == "secret" }) end
      elseif mk:match("^curl%-") then
        local flag = "--" .. mk:sub(6)
        table.insert(r.meta.curl, flag)
        if mv ~= "" then table.insert(r.meta.curl, mv) end
      elseif mk == "env-json-key" or mk == "env-header-key" then
        local var, path = mv:match("^(%S+)%s+(.+)$")
        if var then table.insert(mk == "env-json-key" and r.meta.json_key or r.meta.header_key, { var = var, path = path }) end
      elseif mk == "delay" then r.meta.delay = tonumber(mv)
      elseif mk == "jq" then r.meta.jq = mv
      end
    elseif is_comment(l) or l:match("^@[%w_.-]+%s*=") then
      -- comment or document var
    elseif state == "start" then
      if l:match("%S") then
        local t = vim.split(vim.trim(l), "%s+")
        if #t > 1 and t[1]:match("^%u+$") then r.method = table.remove(t, 1) end
        if #t > 1 and t[#t]:match("^HTTP/") then r.version = table.remove(t) end
        r.method, r.url = r.method or "GET", table.concat(t, " ")
        state = "url"
      end
    elseif state == "url" and (l:match("^%s+[/?&]") or l:match("^[?&]")) then
      r.url = r.url .. vim.trim(l) -- multi-line URL
    elseif state ~= "body" and l:match("%S") then
      state = "headers"
      local k, v = l:match("^%s*([^:%s]+)%s*:%s*(.*)$")
      if k then table.insert(r.headers, { k, v }) end
    elseif state ~= "body" then
      state = "body"
    else
      local force, out = l:match("^>>(!?)%s*(.+)$")
      if out then r.out, r.out_force = vim.trim(out), force == "!"
      else table.insert(r.body, l) end
    end
  end
  if script then script.code = table.concat(script.lines, "\n") end -- unterminated {%
  if not r.url and #r.pre == 0 then return nil end -- url-less block with `< {% %}` = script-only request
  while #r.body > 0 and not r.body[#r.body]:match("%S") do table.remove(r.body) end
  return r
end

---------------------------------------------------------------- variables

local read_json = Auth.read_json

-- http-client(.private).env.json: walk up from the file, closest wins; plus closest .env
local function env_vars(dir)
  local dirs = Auth.dirs(dir)
  local out = {}
  for i = #dirs, 1, -1 do
    local d = dirs[i]
    local f = io.open(d .. "/.env")
    if f then
      for l in f:lines() do
        local k, v = l:match("^%s*([%w_.-]+)%s*=%s*(.-)%s*$")
        if k and not l:match("^%s*#") then out[k] = v:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1") end
      end
      f:close()
    end
  end
  for i = #dirs, 1, -1 do
    for _, name in ipairs({ "http-client.env.json", "http-client.private.env.json" }) do
      local t = read_json(dirs[i] .. "/" .. name)
      if t then
        for _, sec in ipairs({ "$shared", S.env }) do
          for k, v in pairs(type(t[sec]) == "table" and t[sec] or {}) do
            if type(v) ~= "table" then out[k] = tostring(v) end
          end
        end
      end
    end
  end
  return out
end

local function json_path(obj, path)
  path = path:gsub("^%$", "")
  for key in path:gmatch("[^%.%[%]'\"]+") do
    if type(obj) ~= "table" then return nil end
    local n = tonumber(key)
    obj = n and obj[n + 1] or obj[key]
  end
  if type(obj) == "table" then return vim.json.encode(obj) end
  return obj ~= nil and tostring(obj) or nil
end

local function header(hs, name)
  for _, h in ipairs(hs) do
    if h[1] == name then return h[2] end
  end
  for _, h in ipairs(hs) do
    if h[1]:lower() == name:lower() then return h[2] end
  end
end

local magic = {
  ["$uuid"] = function()
    return (("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"):gsub("[xy]", function(c)
      return ("%x"):format(c == "x" and math.random(0, 15) or math.random(8, 11))
    end))
  end,
  ["$timestamp"] = function() return tostring(os.time()) end,
  ["$date"] = function() return os.date("%Y-%m-%d") end,
  ["$randomInt"] = function() return tostring(math.random(0, 9999999)) end,
}

-- {{Name.response.body.$.a.b}} / {{Name.response.headers.X}} / {{Name.request.body.$.x}}
local function request_var(key)
  local name, part, kind, rest = key:match("^([^.]+)%.(response)%.(%a+)%.?(.*)$")
  if not name then name, part, kind, rest = key:match("^([^.]+)%.(request)%.(%a+)%.?(.*)$") end
  local n = name and S.named[name]
  if not n then return nil end
  local x = n[part]
  if kind == "headers" then
    return header(x.headers, rest:match("^%[['\"](.-)['\"]%]$") or rest)
  elseif kind == "body" then
    if rest == "" or rest == "*" then return x.body end
    local ok, obj = pcall(vim.json.decode, x.body or "")
    return ok and json_path(obj, rest) or nil
  end
end

local function str(v)
  if type(v) == "table" then return vim.json.encode(v) end
  return v ~= nil and v ~= vim.NIL and tostring(v) or nil
end

local function expander(doc_vars, dir, req_vars)
  req_vars = req_vars or {}
  local env -- loaded lazily, env files may not exist
  local function expand(s, depth)
    if depth > 10 then return s end
    return (s:gsub("{{%s*(.-)%s*}}", function(k)
      if magic[k] then return magic[k]() end
      local kind, id = k:match("^%$auth%.(%a+)%(%s*[\"']([^\"']+)[\"']%s*%)$")
      if kind then return Auth.value(dir, S.env, kind, id) end
      local v = str(req_vars[k]) or doc_vars[k] or S.runtime[k] or str(Script.globals[k]) or request_var(k) or vim.env[k]
      if not v then
        env = env or env_vars(dir)
        v = env[k]
      end
      return v and expand(v, depth + 1) -- unresolved stays as {{k}}
    end))
  end
  return function(s) return expand(s, 0) end
end

-- `Authorization: Basic user:pass` gets encoded; Digest/NTLM/Negotiate/AWS become curl flags.
-- Returns the header value to send, or nil when curl handles it.
local function auth_header(v, req)
  local scheme, rest = v:match("^(%a+)%s*(.-)%s*$")
  scheme = (scheme or ""):lower()
  local function userpass() return rest:find(":", 1, true) and rest or rest:gsub("%s+", ":", 1) end
  if scheme == "basic" and rest:find(":", 1, true) then
    return "Basic " .. vim.base64.encode(rest)
  elseif scheme == "digest" or scheme == "ntlm" then
    vim.list_extend(req.curl, { "--" .. scheme, "-u", rest ~= "" and userpass() or ":" })
  elseif scheme == "negotiate" then
    vim.list_extend(req.curl, { "--negotiate", "-u", ":" })
  elseif scheme == "aws" then
    local t = vim.split(rest, "%s+")
    local o = {}
    for i = 3, #t do
      local k, val = t[i]:match("^(%a+):(.+)$")
      if k then o[k] = val end
    end
    vim.list_extend(req.curl, { "--aws-sigv4", ("aws:amz:%s:%s"):format(o.region or "us-east-1", o.service or "execute-api"), "-u", t[1] .. ":" .. (t[2] or "") })
    if o.token then table.insert(req.headers, { "x-amz-security-token", o.token }) end
  else
    return v
  end
end

-- resolve vars/includes into what curl needs
local function build(r, doc_vars, dir, req_vars)
  for _, p in ipairs(r.meta.prompt) do
    if not S.runtime[p.var] then
      local fn = p.secret and vim.fn.inputsecret or vim.fn.input
      S.runtime[p.var] = fn(p.text .. ": ")
    end
  end
  local x = expander(doc_vars, dir, req_vars)
  local req = { name = r.name, line = r.line, method = r.method, version = r.version, post = r.post, curl = vim.deepcopy(r.meta.curl), meta = r.meta, headers = {} }
  for _, h in ipairs(r.headers) do
    local k, v = x(h[1]), x(h[2])
    if k:lower() == "authorization" then v = auth_header(v, req) end
    if v then table.insert(req.headers, { k, v }) end
  end
  local url = x(r.url)
  if not url:match("^%a[%w+.-]*://") then
    local host = header(req.headers, "Host") or ""
    url = (host:match("://") and host or ("http://" .. host)):gsub("/$", "") .. (url == "*" and "" or url)
  end
  req.url = url:gsub(" ", "%%20"):gsub('"', "%%22")
  local ct = (header(req.headers, "Content-Type") or ""):lower()
  local parts = {}
  for _, l in ipairs(r.body) do
    local inc = l:match("^<%s*(.+)$")
    if inc then
      local p = vim.fs.normalize(x(vim.trim(inc)))
      if not p:match("^/") then p = dir .. "/" .. p end
      local f = io.open(p, "rb")
      if not f then error("cannot read " .. p) end
      local data = f:read("*a")
      f:close()
      -- included text gets variables too; binary (multipart uploads) is sent as-is
      table.insert(parts, ct:match("multipart") and data or x(data))
    else
      table.insert(parts, ct:match("x%-www%-form%-urlencoded") and vim.trim(x(l)) or x(l))
    end
  end
  if #parts > 0 then
    local sep = ct:match("x%-www%-form%-urlencoded") and "" or ct:match("multipart") and "\r\n" or "\n"
    req.body = table.concat(parts, sep)
  end
  if r.out then
    req.out, req.out_force = vim.fs.normalize(x(r.out)), r.out_force
    if not req.out:match("^/") then req.out = dir .. "/" .. req.out end
  end
  return req
end

---------------------------------------------------------------- response UI

local FOLD_ABOVE = 200 -- non-JSON responses longer than this many lines start folded
local fold_levels = {}  -- per line, for the JSON foldexpr

-- one fold per JSON object/array, starting on its opening line (`"data": {`)
local function json_folds(lines)
  local out, depth = {}, 0
  for i, l in ipairs(lines) do
    if l:match("^%s*[}%]]") then
      out[i], depth = "<" .. depth, depth - 1
    elseif l:match("[{%[]%s*$") then
      depth = depth + 1
      out[i] = ">" .. depth
    else
      out[i] = depth
    end
  end
  return out
end

function M.foldexpr(lnum) return fold_levels[lnum] or "=" end

-- `"data": { … }  58 lines`
function M.foldtext()
  local first = vim.fn.getline(vim.v.foldstart)
  local close = first:match("{%s*$") and "}" or first:match("%[%s*$") and "]" or ""
  local n = vim.v.foldend - vim.v.foldstart + 1
  return { { first, "Normal" }, { " … " .. close, "Comment" }, { ("  %d lines"):format(n), "Comment" } }
end
local views = { B = "body", H = "headers", A = "all", V = "verbose", S = "stats", O = "script output" }
local ui_buf

local function split_response(out)
  local head, body = out:match("^(.-)\r?\n\r?\n(.*)$")
  -- curl -i prints every hop (100 Continue, redirects); keep only the final one
  while body and body:match("^HTTP/%S+ %d") do head, body = body:match("^(.-)\r?\n\r?\n(.*)$") end
  if not head then return out, {}, "" end
  local hs = {}
  local lines = vim.split(head:gsub("\r", ""), "\n")
  for i = 2, #lines do
    local k, v = lines[i]:match("^([^:]+):%s*(.*)$")
    if k then table.insert(hs, { k, v }) end
  end
  return lines[1], hs, body
end

-- jq keeps the server's key order; vim.json.encode would sort them randomly
local function pretty_json(text, obj)
  if vim.fn.executable("jq") == 1 then
    local res = vim.system({ "jq", "--indent", "2", "." }, { text = true, stdin = text }):wait()
    if res.code == 0 then return (res.stdout:gsub("\n$", "")) end
  end
  return vim.json.encode(obj, { indent = "  " })
end

local function render()
  local buf = ui_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
  local e = S.history[S.idx]
  local lines, ft = {}, "text"
  if not e then
    lines = { "No responses" }
  elseif e.pending then
    lines = { "⏳ " .. e.method .. " " .. e.url }
  elseif e.error then
    lines, ft = vim.split(e.error, "\n"), "text"
  else
    local ct = (header(e.headers, "Content-Type") or ""):lower()
    local body = e.filtered or e.body
    if e.filtered then ct = "json" end
    if ct:match("json") or body:match("^%s*[%[{]") then
      local ok, obj = pcall(vim.json.decode, body)
      if ok and type(obj) == "table" then body, ft = pretty_json(body, obj), "json" end
    elseif ct:match("html") then ft = "html"
    elseif ct:match("xml") then ft = "xml" end
    local hl = { e.status }
    for _, h in ipairs(e.headers) do table.insert(hl, h[1] .. ": " .. h[2]) end
    if S.view == "body" then lines = vim.split(body, "\r?\n")
    elseif S.view == "headers" then lines, ft = hl, "http"
    elseif S.view == "all" then
      lines, ft = hl, "text"
      table.insert(lines, "")
      vim.list_extend(lines, vim.split(body, "\r?\n"))
    elseif S.view == "verbose" then lines, ft = vim.split(e.verbose, "\r?\n"), "text"
    elseif S.view == "script output" then
      lines, ft = e.script_output and #e.script_output > 0 and e.script_output or { "(no script output)" }, "text"
    else
      local s = e.stats
      lines = { "status:        " .. e.status, ("total:         %d ms"):format(e.ms) }
      for _, k in ipairs({ "time_namelookup", "time_connect", "time_appconnect", "time_starttransfer" }) do
        if s[k] then table.insert(lines, ("%-14s %.1f ms"):format(k:sub(6) .. ":", s[k] * 1000)) end
      end
      table.insert(lines, "size:          " .. (s.size_download or #e.body) .. " B")
      table.insert(lines, "remote:        " .. (s.remote_ip or "?"))
    end
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable, vim.bo[buf].filetype = false, ft
  local win = vim.fn.bufwinid(buf)
  if win ~= -1 then
    vim.wo[win].foldenable = true
    if ft == "json" then
      -- JSON: open on the top-level keys, everything nested folded
      fold_levels = json_folds(lines)
      vim.wo[win].foldmethod, vim.wo[win].foldexpr = "expr", "v:lua.require'nkjda.http'.foldexpr(v:lnum)"
      vim.wo[win].foldtext, vim.wo[win].foldlevel = "v:lua.require'nkjda.http'.foldtext()", 1
    else
      -- anything else: fold by indent, only big responses start folded
      vim.wo[win].foldmethod, vim.wo[win].foldtext = "indent", ""
      vim.wo[win].foldlevel = #lines > FOLD_ABOVE and 2 or 99
    end
    local tabs = {}
    for _, k in ipairs({ "B", "H", "A", "V", "S", "O" }) do
      local active = S.view == views[k]
      table.insert(tabs, (active and "%#TabLineSel#" or "%#TabLine#") .. " " .. views[k] .. " (" .. k .. ") ")
    end
    local info = e and not e.pending and ("%#Normal#  " .. (e.status or "error") .. " · " .. (e.ms or 0) .. " ms") or ""
    vim.wo[win].winbar = table.concat(tabs) .. info .. ("%=[" .. S.idx .. "/" .. #S.history .. "] ? help")
  end
end

local function cancel()
  S.queue = nil
  if S.job then return S.job:kill("sigterm") end
  local e = S.history[S.idx]
  if e and e.pending then -- still waiting on auth
    e.pending, e.error = nil, "Cancelled"
    render()
  end
end

local function open_ui()
  if not ui_buf or not vim.api.nvim_buf_is_valid(ui_buf) then
    ui_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(ui_buf, "http://response")
    vim.bo[ui_buf].bufhidden = "hide"
    vim.bo[ui_buf].shiftwidth = 2 -- indent folds step by the JSON indent
    local function map(lhs, fn, desc) vim.keymap.set("n", lhs, fn, { buffer = ui_buf, desc = desc }) end
    for k, v in pairs(views) do map(k, function() S.view = v; render() end, "Show " .. v) end
    map("]", function() S.idx = math.min(S.idx + 1, #S.history); render() end, "Next response")
    map("[", function() S.idx = math.max(S.idx - 1, math.min(1, #S.history)); render() end, "Previous response")
    map("X", function() S.history, S.idx = {}, 0; render() end, "Clear responses history")
    map("q", function() vim.api.nvim_win_close(0, false) end, "Close")
    map("<C-c>", cancel, "Interrupt requests")
    map("F", function()
      local e = S.history[S.idx]
      if not e or e.pending or e.error then return end
      vim.ui.input({ prompt = "JQ Filter: ", default = e.jq or "." }, function(f)
        if f == nil then return end
        M.jq(e, f)
        S.view = "body"
        render()
      end)
    end, "Toggle jq filter")
    map("<CR>", function()
      local e = S.history[S.idx]
      if not e or not vim.api.nvim_buf_is_valid(e.buf) then return end
      local w = vim.fn.bufwinid(e.buf)
      if w == -1 then vim.cmd("wincmd p | buffer " .. e.buf) else vim.api.nvim_set_current_win(w) end
      vim.api.nvim_win_set_cursor(0, { e.line, 0 })
    end, "Jump to request")
    map("?", function()
      vim.notify("B body · H headers · A all · V verbose · S stats · O script output · F jq filter\nza toggle fold · zR open all · zM close all\n[ ] history · X clear · <CR> jump to request · <C-c> cancel · q close")
    end, "Help")
  end
  if vim.fn.bufwinid(ui_buf) == -1 then
    local cur = vim.api.nvim_get_current_win()
    vim.cmd("botright vsplit")
    vim.api.nvim_win_set_buf(0, ui_buf)
    vim.api.nvim_set_current_win(cur)
  end
end

---------------------------------------------------------------- sending

-- filter the shown body through jq (the raw body stays for chaining / >> file)
function M.jq(e, filter)
  if not filter or filter == "" then e.filtered, e.jq = nil, nil; return end
  if vim.fn.executable("jq") == 0 then e.filtered = "jq is not installed"; return end
  local res = vim.system({ "jq", filter }, { text = true, stdin = e.body }):wait()
  e.filtered, e.jq = res.code == 0 and res.stdout or res.stderr, filter
end

local function finish(req, e, res, dir)
  local raw = res.stdout or ""
  local stats = {}
  local cut = raw:find("\n__HTTPSTATS__", 1, true)
  if cut then
    stats = select(2, pcall(vim.json.decode, raw:sub(cut + 14))) or {}
    raw = raw:sub(1, cut - 1)
  end
  e.pending, e.verbose, e.stats = nil, res.stderr or "", type(stats) == "table" and stats or {}
  if res.signal ~= 0 then
    e.error = "Cancelled"
    return false
  end
  if res.code ~= 0 then
    e.error = (res.stderr or ""):match("(curl: [^\n]*)%s*$") or ("curl exited " .. res.code)
    return false
  end
  e.status, e.headers, e.body = split_response(raw)
  if req.name then
    S.named[req.name] = {
      request = { headers = req.headers, body = req.body },
      response = { headers = e.headers, body = e.body },
    }
  end
  for _, sc in ipairs(req.post) do
    local _, l = Script.run(sc, {
      request = req, vars = {}, env = env_vars(dir), dir = dir,
      origin = { file = e.file, name = req.name, line = req.line, host = req.url:match("^%a[%w+.-]*://([^/?#]+)") },
      response = { body = e.body, status = tonumber(e.status:match("^HTTP/%S+ (%d+)")), headers = e.headers },
    })
    e.script_output = vim.list_extend(e.script_output or {}, l)
  end
  if req.meta.jq then M.jq(e, req.meta.jq) end
  local ok, obj = pcall(vim.json.decode, e.body)
  for _, k in ipairs(req.meta.json_key) do
    S.runtime[k.var] = ok and json_path(obj, k.path) or S.runtime[k.var]
  end
  for _, k in ipairs(req.meta.header_key) do
    S.runtime[k.var] = header(e.headers, k.path) or S.runtime[k.var]
  end
  if req.out then
    if vim.uv.fs_stat(req.out) and not req.out_force then
      vim.notify(req.out .. " exists, not overwriting (use >>!)", vim.log.levels.WARN)
    else
      local f = io.open(req.out, "wb")
      if f then f:write(e.body); f:close() end
    end
  end
  return true
end

local function send(blocks, buf)
  cancel()
  S.last = { blocks = blocks, buf = buf }
  open_ui()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local doc = M.parse_doc(lines)
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
  if dir == "." or dir == "" then dir = vim.fn.getcwd() end
  local queue = {}
  for _, b in ipairs(blocks) do
    local r = M.parse_block(lines, b)
    if r then table.insert(queue, r) end
  end
  if #queue == 0 then return vim.notify("No request found", vim.log.levels.WARN) end
  S.queue = queue
  vim.fn.mkdir(vim.fs.dirname(jar), "p")

  local send_one
  local function step()
    if S.queue ~= queue then return end
    local r = table.remove(queue, 1)
    if not r then return end
    local e = { method = r.method or "SCRIPT", url = r.url or r.name or "", buf = buf, file = vim.api.nvim_buf_get_name(buf), line = r.line, pending = true, headers = {}, body = "" }
    table.insert(S.history, e)
    S.idx = #S.history
    render()
    local raw = { r.url }
    for _, h in ipairs(r.headers) do table.insert(raw, h[2]) end
    vim.list_extend(raw, r.body)
    Auth.ensure(Auth.refs(table.concat(raw, "\n")), dir, S.env, function(err)
      if S.queue ~= queue then return end
      if err then
        e.pending, e.error, S.queue = nil, "auth: " .. err, nil
        return render()
      end
      send_one(r, e)
    end)
  end

  function send_one(r, e)
    local req_vars, logs, result = {}, {}, nil
    local t0 = vim.uv.hrtime()
    if #r.pre > 0 then
      vim.cmd("redraw") -- scripts block (node :wait()), so paint the ⏳ line first
      local base = { method = r.method, url = r.url, headers = r.headers, body = table.concat(r.body, "\n") }
      for _, sc in ipairs(r.pre) do
        local v, l, res = Script.run(sc, { request = base, vars = doc.vars, env = env_vars(dir), dir = dir,
          origin = { file = e.file, name = r.name, line = r.line } })
        req_vars = vim.tbl_extend("force", req_vars, v)
        vim.list_extend(logs, l)
        result = res or result
      end
    end
    e.script_output = logs
    if not r.url then
      -- script-only: the script's return value is the body, its logs the fallback
      e.pending, e.status, e.verbose, e.stats = nil, "SCRIPT", "", {}
      e.ms = math.floor((vim.uv.hrtime() - t0) / 1e6)
      e.body = result or table.concat(logs, "\n")
      if r.meta.jq then M.jq(e, r.meta.jq) end
      render()
      return step()
    end
    local ok, req = pcall(build, r, doc.vars, dir, req_vars)
    if not ok then
      e.pending, e.error = nil, tostring(req)
      return render()
    end
    e.url = req.url
    render()
    local cmd = { "curl", "-sS", "-v", "-i", "-X", req.method, req.url, "-b", jar, "-c", jar, "-w", "\n__HTTPSTATS__%{json}" }
    local v = req.version and req.version:match("HTTP/(.+)")
    if v == "1.1" or v == "1.0" then table.insert(cmd, "--http" .. v)
    elseif v == "2" then table.insert(cmd, "--http2")
    elseif v == "3" then table.insert(cmd, "--http3") end
    for _, h in ipairs(req.headers) do
      vim.list_extend(cmd, { "-H", h[2] == "" and (h[1] .. ";") or (h[1] .. ": " .. h[2]) })
    end
    if req.body then vim.list_extend(cmd, { "--data-binary", "@-" }) end
    vim.list_extend(cmd, req.curl)
    local t = vim.uv.hrtime()
    local function go()
      S.job = vim.system(cmd, { text = false, stdin = req.body }, vim.schedule_wrap(function(res)
        S.job = nil
        e.ms = math.floor((vim.uv.hrtime() - t) / 1e6)
        local fine = finish(req, e, res, dir)
        render()
        if fine then step() else S.queue = nil end
      end))
    end
    if r.meta.delay then vim.defer_fn(go, r.meta.delay) else go() end
  end
  step()
end

---------------------------------------------------------------- commands

local function blocks_in(buf, from, to)
  local doc = M.parse_doc(vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  local out = {}
  for _, b in ipairs(doc.blocks) do
    if b.e >= from and b.s - 1 <= to then table.insert(out, b) end
  end
  return out
end

function M.run()
  local a, b = vim.fn.line("."), vim.fn.line(".")
  if vim.fn.mode():match("^[vV\22]") then
    a, b = math.min(a, vim.fn.line("v")), math.max(a, vim.fn.line("v"))
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  end
  send(blocks_in(vim.api.nvim_get_current_buf(), a, b), vim.api.nvim_get_current_buf())
end

function M.run_all()
  local buf = vim.api.nvim_get_current_buf()
  send(blocks_in(buf, 1, vim.api.nvim_buf_line_count(buf)), buf)
end

function M.replay()
  if not S.last or not vim.api.nvim_buf_is_valid(S.last.buf) then
    return vim.notify("Nothing to replay", vim.log.levels.WARN)
  end
  send(S.last.blocks, S.last.buf)
end

-- re-send the request whose script last set global `key` (found by name, else by line)
function M.renew(key)
  local o = Script.origins[key]
  if not o or not o.file or o.file == "" then
    return vim.notify("http: no known request sets " .. key .. ", run it once first", vim.log.levels.WARN)
  end
  local buf = vim.fn.bufadd(o.file)
  vim.fn.bufload(buf)
  local blocks = M.parse_doc(vim.api.nvim_buf_get_lines(buf, 0, -1, false)).blocks
  local pick
  for _, b in ipairs(blocks) do
    if o.name and b.name == o.name then pick = b; break end
    if not pick and b.s <= o.line and o.line <= b.e then pick = b end
  end
  if not pick then return vim.notify("http: request for " .. key .. " not found in " .. o.file, vim.log.levels.WARN) end
  send({ pick }, buf)
end

function M.scratchpad()
  vim.cmd("enew")
  vim.bo.buftype, vim.bo.bufhidden, vim.bo.filetype = "nofile", "hide", "http"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "@MY_TOKEN_NAME=my_token_value", "", "# @name scratchpad", "POST https://httpbin.org/post HTTP/1.1",
    "accept: application/json", "content-type: application/json", "", "{", '  "foo": "bar"', "}",
  })
end

local function buf_dir(buf)
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
  return (dir == "." or dir == "") and vim.fn.getcwd() or dir
end

-- environments from http-client.env.json next to (or above) the current file
function M.set_env(name)
  if name then
    S.env = name
    return vim.notify("http env: " .. name)
  end
  local seen, names = {}, {}
  for _, d in ipairs(Auth.dirs(buf_dir(0))) do
    for k in pairs(read_json(d .. "/http-client.env.json") or {}) do
      if not k:match("^%$") and not seen[k] then seen[k] = true; table.insert(names, k) end
    end
  end
  if #names == 0 then return vim.notify("No http-client.env.json found", vim.log.levels.WARN) end
  table.sort(names)
  vim.ui.select(names, { prompt = "http env (" .. S.env .. ")" }, function(c) if c then M.set_env(c) end end)
end

vim.keymap.set({ "n", "v" }, "<leader>ks", M.run, { desc = "Send request" })
vim.keymap.set({ "n", "v" }, "<leader>ka", M.run_all, { desc = "Send all requests" })
vim.keymap.set("n", "<leader>kb", M.scratchpad, { desc = "Open scratchpad" })
vim.keymap.set("n", "<leader>kr", M.replay, { desc = "Replay last request" })
vim.keymap.set("n", "<leader>ke", function() M.set_env() end, { desc = "Select http env" })
vim.keymap.set("n", "<leader>kx", function() Script.clear(); vim.notify("http: globals cleared") end, { desc = "Clear globals" })
vim.keymap.set("n", "<leader>ku", function() Auth.manager(buf_dir(0), S.env) end, { desc = "Manage Auth" })
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "http", "rest" },
  callback = function(ev)
    vim.keymap.set({ "n", "v" }, "<CR>", M.run, { buffer = ev.buf, desc = "Send request" })
  end,
})

M._state = S -- for tests
return M
