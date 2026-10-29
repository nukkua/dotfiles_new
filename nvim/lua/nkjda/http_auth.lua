-- nkjda/http_auth.lua — OAuth2 auth configs for nkjda.http
-- Configs live in http-client(.private).env.json under <env>.Security.Auth.<id> (or $shared);
-- tokens are saved back as <env>.Security.Auth.<id>.auth_data in http-client.private.env.json.
-- Used in requests as {{$auth.token("id")}} / {{$auth.idToken("id")}}.

local M = {}

local function enc(s)
  return (tostring(s):gsub("[^%w%-._~]", function(c) return ("%%%02X"):format(c:byte()) end))
end

local function form(t)
  local out = {}
  for k, v in pairs(t) do
    for _, x in ipairs(type(v) == "table" and v or { v }) do table.insert(out, enc(k) .. "=" .. enc(x)) end
  end
  table.sort(out) -- stable order, easier to debug
  return table.concat(out, "&")
end

local function b64url(s) return (vim.base64.encode(s):gsub("+", "-"):gsub("/", "_"):gsub("=+$", "")) end

local function random(n)
  local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
  local out = {}
  for i = 1, n do
    local r = math.random(1, #chars)
    out[i] = chars:sub(r, r)
  end
  return table.concat(out)
end

function M.read_json(p)
  local f = io.open(p)
  if not f then return nil end
  local ok, t = pcall(vim.json.decode, f:read("*a"))
  f:close()
  return ok and type(t) == "table" and t or nil
end

local function write_json(p, t)
  local f = assert(io.open(p, "w"))
  f:write(vim.json.encode(t, { indent = "  " }), "\n")
  f:close()
end

-- dir and its parents, closest first
function M.dirs(dir)
  local out = { dir }
  for d in vim.fs.parents(dir) do table.insert(out, d) end
  return out
end

local function dig(t, ...)
  for _, k in ipairs({ ... }) do
    if type(t) ~= "table" then return nil end
    t = t[k]
  end
  return t
end

-- ensure t[k1][k2]... exist as JSON objects, return the last one
local function nest(t, ...)
  for _, k in ipairs({ ... }) do
    if type(t[k]) ~= "table" then t[k] = vim.empty_dict() end
    t = t[k]
  end
  return t
end

---------------------------------------------------------------- configs

-- all auth configs for `env`, merged closest-file-wins; each knows its env file
function M.configs(dir, env)
  local out, files = {}, {}
  local ds = M.dirs(dir)
  for i = #ds, 1, -1 do
    for _, name in ipairs({ "http-client.env.json", "http-client.private.env.json" }) do
      local p = ds[i] .. "/" .. name
      local t = M.read_json(p)
      for _, sec in ipairs({ "$shared", env }) do
        for id, cfg in pairs(dig(t, sec, "Security", "Auth") or {}) do
          if type(cfg) == "table" then
            out[id] = vim.tbl_deep_extend("force", out[id] or {}, cfg)
            if name == "http-client.env.json" then files[id] = p end
          end
        end
      end
    end
  end
  for id, cfg in pairs(out) do
    cfg._id, cfg._file = id, files[id]
    cfg._private = vim.fs.dirname(files[id] or (dir .. "/x")) .. "/http-client.private.env.json"
  end
  return out
end

local function save_data(cfg, env, data)
  local t = M.read_json(cfg._private) or vim.empty_dict()
  local a = nest(t, env, "Security", "Auth", cfg._id)
  a.auth_data = data
  write_json(cfg._private, t)
  cfg.auth_data = data
end

---------------------------------------------------------------- token requests

local function custom_params(cfg, where)
  local out = {}
  for k, v in pairs(cfg["Custom Request Parameters"] or {}) do
    if type(v) == "table" and v.Value ~= nil then
      if v.Use == nil or v.Use == "Everywhere" or v.Use == where then out[k] = v.Value end
    else
      out[k] = v
    end
  end
  return out
end

local function curl_post(url, body, headers, cb)
  local cmd = { "curl", "-sS", "-X", "POST", url, "-H", "Accept: application/json",
    "-H", "Content-Type: application/x-www-form-urlencoded", "--data-binary", "@-" }
  for k, v in pairs(headers or {}) do vim.list_extend(cmd, { "-H", k .. ": " .. v }) end
  vim.system(cmd, { text = true, stdin = body }, vim.schedule_wrap(function(res)
    if res.code ~= 0 then return cb(res.stderr ~= "" and vim.trim(res.stderr) or "curl failed") end
    local ok, t = pcall(vim.json.decode, res.stdout)
    if not ok or type(t) ~= "table" then return cb("bad response: " .. res.stdout:sub(1, 200)) end
    if t.error then return cb(t.error .. (t.error_description and (": " .. t.error_description) or ""), t) end
    cb(nil, t)
  end))
end

local function openssl_sign(input, args)
  local res = vim.system(vim.list_extend({ "openssl", "dgst", "-sha256", "-binary" }, args), { stdin = input }):wait()
  if res.code ~= 0 then error("openssl: " .. (res.stderr or "")) end
  return res.stdout
end

-- client_assertion for "Client Credentials": "jwt" — either given, or built from the JWT object
local function assertion(cfg)
  if cfg.Assertion and cfg.Assertion ~= "" then return cfg.Assertion end
  local jwt = cfg.JWT or {}
  local header = vim.tbl_extend("force", { alg = "HS256", typ = "JWT" }, jwt.Header or {})
  local now = os.time()
  local payload = vim.tbl_extend("force", {
    iss = cfg["Client ID"], sub = cfg["Client ID"], aud = cfg["Token URL"], jti = random(16),
  }, jwt.Payload or {})
  payload.iat = payload.iat or now
  payload.exp = (payload.exp and payload.exp < payload.iat) and payload.iat + payload.exp or payload.exp or now + 50
  local input = b64url(vim.json.encode(header)) .. "." .. b64url(vim.json.encode(payload))
  local sig
  if header.alg == "RS256" then
    local key = vim.fn.tempname()
    vim.fn.writefile(vim.split(cfg.private_key or error("RS256 needs private_key"), "\n"), key)
    local ok, s = pcall(openssl_sign, input, { "-sign", key })
    os.remove(key)
    sig = ok and s or error(s)
  else
    sig = openssl_sign(input, { "-hmac", cfg["Client Secret"] or "" })
  end
  return input .. "." .. b64url(sig)
end

local function token_request(cfg, params, cb)
  params = vim.tbl_extend("force", params, custom_params(cfg, "In Token Request"))
  local headers = vim.deepcopy(cfg["Custom Headers"] or cfg["Custom Request Headers"] or {})
  local mode = (cfg["Client Credentials"] or "basic"):lower()
  if mode == "basic" and cfg["Client Secret"] then
    headers.Authorization = "Basic " .. vim.base64.encode(cfg["Client ID"] .. ":" .. cfg["Client Secret"])
  elseif mode == "in body" or (mode == "basic" and not cfg["Client Secret"]) then
    params.client_id, params.client_secret = cfg["Client ID"], cfg["Client Secret"]
  elseif mode == "jwt" then
    local ok, a = pcall(assertion, cfg)
    if not ok then return cb(a) end
    params.client_id = cfg["Client ID"]
    params.client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
    params.client_assertion = a
  end
  if not cfg["Token URL"] then return cb("missing \"Token URL\"") end
  curl_post(cfg["Token URL"], form(params), headers, function(err, t)
    if err then return cb(err) end
    local old = cfg.auth_data or {}
    cb(nil, {
      access_token = t.access_token, id_token = t.id_token or old.id_token,
      refresh_token = t.refresh_token or old.refresh_token, token_type = t.token_type,
      expires_at = os.time() + (tonumber(t.expires_in) or tonumber(cfg["Expires In"]) or 10),
    })
  end)
end

---------------------------------------------------------------- browser flows

local function open_browser(cfg, url, redirect)
  if cfg["Browser CMD"] then
    local cmd = vim.split(cfg["Browser CMD"], "%s+", { trimempty = true })
    table.insert(cmd, 2, url)
    if #cmd == 2 then table.insert(cmd, redirect) end
    vim.system(cmd)
  else
    vim.ui.open(url)
  end
end

local function parse_query(q)
  local t = {}
  for k, v in (q or ""):gmatch("([^&=?#]+)=([^&#]*)") do
    t[vim.uri_decode(k)] = vim.uri_decode((v:gsub("+", " ")))
  end
  return t
end

-- tiny HTTP server on localhost that catches the redirect (query or #fragment)
local function catch_redirect(port, cb)
  local server = vim.uv.new_tcp()
  local done = false
  local function finish(err, q)
    if done then return end
    done = true
    if not server:is_closing() then server:close() end
    vim.schedule(function() cb(err, q) end)
  end
  local ok, err = pcall(function()
    assert(server:bind("127.0.0.1", port))
    assert(server:listen(16, function()
      local c = vim.uv.new_tcp()
      server:accept(c)
      local buf = ""
      c:read_start(function(_, chunk)
        if not chunk then return c:close() end
        buf = buf .. chunk
        local target = buf:match("^GET (%S+) HTTP")
        if not target then return end
        local q = parse_query(target:match("%?(.*)$"))
        local page
        if q.code or q.access_token or q.error then
          page = "<h3>Authentication finished, you can close this window.</h3>"
        else
          -- implicit flow returns the token in #fragment, which browsers never send: bounce it into the query
          page = "<script>location.replace(location.pathname + '?' + location.hash.slice(1))</script>"
        end
        c:write("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n" .. page, function() c:close() end)
        if q.code or q.access_token or q.error then finish(nil, q) end
      end)
    end))
  end)
  if not ok then return finish("cannot listen on port " .. port .. ": " .. tostring(err)) end
  vim.defer_fn(function() finish("timed out waiting for the browser redirect") end, 300000)
end

local function browser_flow(cfg, implicit, cb)
  local redirect = cfg["Redirect URL"] or "http://localhost:8080"
  local state = random(24)
  local p = {
    response_type = cfg["Response Type"] or (implicit and "token" or "code"),
    client_id = cfg["Client ID"], redirect_uri = redirect, state = state, scope = cfg.Scope,
  }
  local verifier
  if not implicit and cfg.PKCE then
    local pk = type(cfg.PKCE) == "table" and cfg.PKCE or {}
    verifier = pk["Code Verifier"] or random(64)
    local method = (pk["Code Challenge Method"] or "S256"):lower() == "plain" and "plain" or "S256"
    p.code_challenge = method == "plain" and verifier or b64url(vim.text.hexdecode(vim.fn.sha256(verifier)))
    p.code_challenge_method = method
  end
  p = vim.tbl_extend("force", p, custom_params(cfg, "In Auth Request"))
  if not cfg["Auth URL"] then return cb("missing \"Auth URL\"") end
  local url = cfg["Auth URL"] .. (cfg["Auth URL"]:find("?", 1, true) and "&" or "?") .. form(p)

  local function got(q)
    if q.error then return cb(q.error .. (q.error_description and (": " .. q.error_description) or "")) end
    if q.state and q.state ~= state then return cb("state mismatch") end
    if implicit then
      return cb(nil, {
        access_token = q.access_token, id_token = q.id_token, token_type = q.token_type,
        expires_at = os.time() + (tonumber(q.expires_in) or tonumber(cfg["Expires In"]) or 10),
      })
    end
    token_request(cfg, { grant_type = "authorization_code", code = q.code, redirect_uri = redirect, code_verifier = verifier }, cb)
  end

  local host = redirect:match("^https?://([^/:]+)")
  if host == "localhost" or host == "127.0.0.1" or cfg["Browser CMD"] then
    local port = tonumber(redirect:match("^https?://[^/:]+:(%d+)")) or 8080
    catch_redirect(port, function(err, q) if err then cb(err) else got(q) end end)
    open_browser(cfg, url, redirect)
    vim.notify("http auth: finish signing in in the browser…")
  else
    open_browser(cfg, url, redirect)
    vim.ui.input({ prompt = "Paste the redirect URL (or code): " }, function(s)
      if not s or s == "" then return cb("cancelled") end
      local q = s:find("[?#]") and parse_query(s:match("[?#](.*)$")) or { code = s }
      q.state = q.state or state
      got(q)
    end)
  end
end

local function device_flow(cfg, cb)
  if not cfg["Device Auth URL"] then return cb("missing \"Device Auth URL\"") end
  local p = vim.tbl_extend("force", { client_id = cfg["Client ID"], scope = cfg.Scope }, custom_params(cfg, "In Auth Request"))
  curl_post(cfg["Device Auth URL"], form(p), cfg["Custom Headers"], function(err, d)
    if err then return cb(err) end
    pcall(vim.fn.setreg, "+", d.user_code)
    vim.notify(("http auth: code %s (copied) — confirm at %s"):format(d.user_code, d.verification_uri or d.verification_url or "?"))
    open_browser(cfg, d.verification_uri_complete or d.verification_uri or d.verification_url, "")
    local interval = (tonumber(d.interval) or 5) * 1000
    local deadline = os.time() + (tonumber(d.expires_in) or 600)
    local function poll()
      if os.time() > deadline then return cb("device code expired") end
      local tp = { grant_type = "urn:ietf:params:oauth:grant-type:device_code", device_code = d.device_code, client_id = cfg["Client ID"] }
      token_request(cfg, tp, function(e, data)
        if e and e:match("^authorization_pending") then return vim.defer_fn(poll, interval) end
        if e and e:match("^slow_down") then interval = interval + 5000; return vim.defer_fn(poll, interval) end
        cb(e, data)
      end)
    end
    vim.defer_fn(poll, interval)
  end)
end

---------------------------------------------------------------- public API

-- get a brand-new token
function M.acquire(cfg, env, cb)
  local function done(err, data)
    if err then return cb(err) end
    save_data(cfg, env, data)
    cb(nil, data)
  end
  local g = (cfg["Grant Type"] or ""):lower()
  if g == "client credentials" then
    token_request(cfg, { grant_type = "client_credentials", scope = cfg.Scope }, done)
  elseif g == "password" then
    token_request(cfg, { grant_type = "password", username = cfg.Username, password = cfg.Password, scope = cfg.Scope }, done)
  elseif g == "authorization code" then
    browser_flow(cfg, false, done)
  elseif g == "implicit" then
    browser_flow(cfg, true, done)
  elseif g == "device authorization" then
    device_flow(cfg, done)
  else
    cb("unknown \"Grant Type\": " .. tostring(cfg["Grant Type"]))
  end
end

function M.refresh(cfg, env, cb)
  local rt = dig(cfg, "auth_data", "refresh_token")
  if not rt then return cb("no refresh token") end
  token_request(cfg, { grant_type = "refresh_token", refresh_token = rt, scope = cfg.Scope }, function(err, data)
    if err then return cb(err) end
    save_data(cfg, env, data)
    cb(nil, data)
  end)
end

function M.revoke(cfg, env, cb)
  local token = dig(cfg, "auth_data", "access_token")
  local function clear()
    save_data(cfg, env, nil)
    cb(nil)
  end
  if not token or not cfg["Revoke URL"] then return clear() end
  local p = { token = token, client_id = cfg["Client ID"], client_secret = cfg["Client Secret"] }
  curl_post(cfg["Revoke URL"], form(p), cfg["Custom Headers"], function(err)
    if err and not err:match("bad response") then return cb(err) end -- many revoke endpoints answer with an empty body
    clear()
  end)
end

local function valid(cfg)
  local d = cfg.auth_data
  return d and d.access_token and (tonumber(d.expires_at) or 0) > os.time()
end

-- make sure every id has a usable token (refresh or acquire when needed), then cb(err)
function M.ensure(ids, dir, env, cb)
  local cfgs = M.configs(dir, env)
  local i = 0
  local function next_id(err)
    if err then return cb(err) end
    i = i + 1
    local id = ids[i]
    if not id then return cb(nil) end
    local cfg = cfgs[id]
    if not cfg then return next_id("no auth config \"" .. id .. "\" in env \"" .. env .. "\"") end
    if valid(cfg) or cfg["Acquire Automatically"] == false then return next_id() end
    local function acquire() M.acquire(cfg, env, function(e) next_id(e and (id .. ": " .. e)) end) end
    if dig(cfg, "auth_data", "refresh_token") then
      M.refresh(cfg, env, function(e) if e then acquire() else next_id() end end)
    else
      acquire()
    end
  end
  next_id()
end

-- value for {{$auth.token("id")}} / {{$auth.idToken("id")}}
function M.value(dir, env, kind, id)
  local cfg = M.configs(dir, env)[id]
  local d = cfg and cfg.auth_data
  if not d then return nil end
  if kind == "idToken" or cfg["Use ID Token"] then return d.id_token end
  return d.access_token
end

-- ids referenced as $auth.token("id") / $auth.idToken("id") in text
function M.refs(text)
  local ids, seen = {}, {}
  for id in text:gmatch("%$auth%.%a+%(%s*[\"']([^\"']+)[\"']%s*%)") do
    if not seen[id] then seen[id] = true; table.insert(ids, id) end
  end
  return ids
end

---------------------------------------------------------------- manager UI

local template = {
  Type = "OAuth2", ["Grant Type"] = "Authorization Code",
  ["Client ID"] = "", ["Client Secret"] = "", ["Client Credentials"] = "basic",
  ["Auth URL"] = "", ["Token URL"] = "", ["Redirect URL"] = "http://localhost:1234",
  ["Revoke URL"] = "", ["Device Auth URL"] = "", Scope = "", PKCE = true,
  ["Acquire Automatically"] = true, ["Use ID Token"] = false,
  ["Custom Request Parameters"] = vim.empty_dict(), ["Custom Headers"] = vim.empty_dict(),
}

local function edit_at(file, id)
  vim.cmd("edit " .. vim.fn.fnameescape(file))
  vim.fn.search('"' .. vim.fn.escape(id, "\\/.*$^~[]") .. '"')
end

-- JWT payload claims, nil for anything that isn't a JWT
local function jwt(s)
  local p = type(s) == "string" and s:match("^[%w_-]+%.([%w_-]+)%.[%w_-]*$")
  if not p then return nil end
  p = p:gsub("-", "+"):gsub("_", "/")
  local ok, t = pcall(function() return vim.json.decode(vim.base64.decode(p .. ("="):rep(-#p % 4))) end)
  return ok and type(t) == "table" and t or nil
end

local function expiry(exp)
  local left = (tonumber(exp) or 0) - os.time()
  return left > 0 and ("valid " .. math.ceil(left / 60) .. " min") or "expired"
end

function M.manager(dir, env)
  local Script = require("nkjda.http_script")
  local cfgs = M.configs(dir, env)
  local ids = vim.tbl_keys(cfgs)
  table.sort(ids)
  local lines = {
    "Auth configs — env: " .. env,
    "a add · e edit · p private · m remove · g get token · r refresh · R revoke · q close",
    "",
  }
  local globals = {} -- line number -> global key
  for _, id in ipairs(ids) do
    local c, d = cfgs[id], cfgs[id].auth_data
    local status = "no token"
    if d and d.access_token then
      status = expiry(d.expires_at)
      if d.refresh_token then status = status .. " +refresh" end
    end
    table.insert(lines, ("%-24s %-22s %s"):format(id, c["Grant Type"] or "?", status))
  end
  if #ids == 0 then table.insert(lines, "(none — press a to add one)") end
  local keys = vim.tbl_keys(Script.globals)
  table.sort(keys)
  if #keys > 0 then
    vim.list_extend(lines, { "", "Globals (set by scripts) — m delete · r renew (re-run its request)" })
    for _, k in ipairs(keys) do
      local v, o, c = Script.globals[k], Script.origins[k] or {}, jwt(Script.globals[k])
      -- Firebase/most IdPs: aud = project / client, iss = issuer domain
      local project = c and (type(c.aud) == "string" and c.aud or c.iss) or ""
      local status = c and (c.exp and expiry(c.exp) or "no exp") or vim.inspect(v):sub(1, 30)
      table.insert(lines, ("%-24s %-40s %-18s %s"):format(k, o.host or "?", project, status))
      globals[#lines] = k
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local ns = vim.api.nvim_create_namespace("nkjda.http_auth")
  local function hl(i, s, e, group) vim.api.nvim_buf_set_extmark(buf, ns, i - 1, s, { end_col = e, hl_group = group }) end
  for i, l in ipairs(lines) do
    local id = l:match("^%S+")
    if i == 1 then
      hl(i, 0, #l, "HttpAuthTitle")
    elseif i == 2 or l:match("^Globals") then
      local dash = l:find(" — ", 1, true)
      if dash then hl(i, 0, dash - 1, "HttpAuthTitle") end
      hl(i, dash and dash - 1 or 0, #l, "Comment")
      for s in (" " .. l):gmatch("%s()%a%f[%s]") do -- single-letter tokens are the keys
        hl(i, s - 2, s - 1, "HttpAuthKey")
      end
    elseif globals[i] or (id and cfgs[id]) then
      hl(i, 0, #id, "HttpAuthId")
      local c = globals[i] and jwt(Script.globals[id])
      local p = c and l:find(" " .. (type(c.aud) == "string" and c.aud or c.iss or "\0") .. " ", #id + 1, true)
      if p then hl(i, p, l:find(" ", p + 1, true) - 1, "HttpAuthProject") end
      for word, group in pairs({ valid = "HttpAuthValid", expired = "HttpAuthExpired", ["no token"] = "Comment", ["no exp"] = "Comment" }) do
        local s, e = l:find(word .. "[^%s]*", 40, false)
        if s then hl(i, s - 1, word == "valid" and l:find(" min", s, true) + 3 or e, group) end
      end
    elseif l:match("^%(none") then
      hl(i, 0, #l, "Comment")
    end
  end
  local w = 0
  for _, l in ipairs(lines) do w = math.max(w, vim.fn.strdisplaywidth(l)) end
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", style = "minimal", border = "rounded", title = " http auth ",
    width = w + 2, height = #lines,
    row = math.floor((vim.o.lines - #lines) / 2), col = math.floor((vim.o.columns - w) / 2),
  })
  vim.wo[win].winhighlight = "FloatBorder:HttpAuthBorder,FloatTitle:HttpAuthTitle,CursorLine:HttpAuthCursor"
  vim.wo[win].cursorline = true
  vim.api.nvim_win_set_cursor(win, { math.min(4, #lines), 0 })
  local function close() if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end end
  local function current()
    local id = ids[vim.api.nvim_win_get_cursor(win)[1] - 3]
    return id and cfgs[id]
  end
  local function report(what)
    return function(err) vim.notify("http auth: " .. (err or what), err and vim.log.levels.ERROR or nil) end
  end
  local function act(fn, what)
    return function()
      local c = current()
      if not c then return end
      close()
      fn(c, env, report(c._id .. " " .. what))
    end
  end
  local function map(lhs, fn) vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true }) end
  map("q", close)
  map("<Esc>", close)
  map("g", act(M.acquire, "token acquired"))
  local refresh = act(M.refresh, "token refreshed")
  map("r", function()
    local k = globals[vim.api.nvim_win_get_cursor(win)[1]]
    if not k then return refresh() end
    close()
    require("nkjda.http").renew(k)
  end)
  map("R", act(M.revoke, "token revoked"))
  map("e", function()
    local c = current()
    close()
    local f = c and c._file or vim.fs.find("http-client.env.json", { path = dir, upward = true })[1]
    if f then edit_at(f, c and c._id or env) else vim.notify("No http-client.env.json found", vim.log.levels.WARN) end
  end)
  map("p", function()
    local c = current()
    close()
    edit_at(c and c._private or (dir .. "/http-client.private.env.json"), c and c._id or env)
  end)
  map("a", function()
    close()
    vim.ui.input({ prompt = "New auth id: " }, function(id)
      if not id or id == "" then return end
      local f = vim.fs.find("http-client.env.json", { path = dir, upward = true })[1] or (dir .. "/http-client.env.json")
      local t = M.read_json(f) or vim.empty_dict()
      nest(t, env, "Security", "Auth")[id] = vim.deepcopy(template)
      write_json(f, t)
      edit_at(f, id)
    end)
  end)
  map("m", function()
    local k = globals[vim.api.nvim_win_get_cursor(win)[1]]
    if k then
      if vim.fn.confirm("Delete global " .. k .. "?", "&Yes\n&No", 2) ~= 1 then return end
      close()
      Script.unset(k)
      return vim.notify("http: deleted global " .. k)
    end
    local c = current()
    if not c or vim.fn.confirm("Remove auth config " .. c._id .. "?", "&Yes\n&No", 2) ~= 1 then return end
    close()
    for _, f in ipairs({ c._file, c._private }) do
      local t = f and M.read_json(f)
      for _, sec in ipairs({ env, "$shared" }) do
        local a = dig(t, sec, "Security", "Auth")
        if a and a[c._id] then
          a[c._id] = nil
          write_json(f, t)
        end
      end
    end
    vim.notify("http auth: removed " .. c._id)
  end)
end

return M
