-- nkjda/http_script.lua — pre/post request scripts for nkjda.http
-- JS (`< {% ... %}`, `> {% ... %}`, `< ./x.js`) runs in node; `-- lua` scripts / .lua files run in nvim.
-- API (kulala/JetBrains subset): client.global.set/get/isEmpty/clear/clearAll, client.log,
-- client.test, client.assert, request.variables.set/get, request.environment.get,
-- response.body (parsed JSON or text), response.headers.valueOf/valuesOf, response.status.
-- JS scripts may use await and run with cwd = the .http file's dir. A block with only `< {% %}`
-- (no request line) is a script-only request: its `return` value is shown as the response body.
-- ponytail: no TypeScript, no response.cookies, no request mutation (headers/url/body) from scripts

local M = {}

local store = vim.fn.stdpath("data") .. "/http/globals.json"
M.globals = (function()
  local f = io.open(store)
  if not f then return {} end
  local ok, t = pcall(vim.json.decode, f:read("*a"))
  f:close()
  return ok and type(t) == "table" and t or {}
end)()

local function save()
  vim.fn.mkdir(vim.fs.dirname(store), "p")
  local f = io.open(store, "w")
  if f then
    f:write(vim.json.encode(next(M.globals) and M.globals or vim.empty_dict()))
    f:close()
  end
end

function M.clear()
  M.globals = {}
  save()
end

local js_harness = [[
const ctx = JSON.parse(require("fs").readFileSync(0, "utf8"));
const globals = ctx.globals, vars = {}, logs = [];
const client = {
  global: {
    set: (k, v) => { globals[k] = v; }, get: (k) => globals[k],
    isEmpty: () => Object.keys(globals).length === 0,
    clear: (k) => { delete globals[k]; }, clearAll: () => { for (const k in globals) delete globals[k]; },
  },
  log: (...a) => logs.push(a.map((x) => typeof x === "string" ? x : JSON.stringify(x)).join(" ")),
  test: (name, fn) => { try { fn(); logs.push("✔ " + name); } catch (e) { logs.push("✘ " + name + ": " + e.message); } },
  assert: (c, msg) => { if (!c) throw new Error(msg || "assertion failed"); },
};
const lower = (h) => Object.fromEntries(Object.entries(h || {}).map(([k, v]) => [k.toLowerCase(), v]));
const hdrs = (h) => { const l = lower(h); return {
  valueOf: (n) => (l[n.toLowerCase()] || [])[0] ?? null, valuesOf: (n) => l[n.toLowerCase()] || [] }; };
const request = { ...ctx.request, headers: hdrs(ctx.request.headers),
  variables: { set: (k, v) => { vars[k] = v; }, get: (k) => vars[k] ?? ctx.vars[k] },
  environment: { get: (k) => ctx.env[k] } };
let response;
if (ctx.response) {
  let body = ctx.response.body;
  try { body = JSON.parse(body); } catch (_) {}
  response = { body, status: ctx.response.status, headers: hdrs(ctx.response.headers),
    contentType: { mimeType: ((lower(ctx.response.headers)["content-type"] || [""])[0]).split(";")[0] } };
}
(async () => {
  let result;
  try { result = await new (async () => {}).constructor("client", "request", "response", ctx.code)(client, request, response); }
  catch (e) { logs.push("✘ script error: " + e.message); }
  if (result !== undefined && typeof result !== "string") result = JSON.stringify(result);
  // exit explicitly: SDKs like firebase-admin keep the event loop alive
  process.stdout.write(JSON.stringify({ globals, vars, logs, result }), () => process.exit(0));
})();
]]

-- headers list {{k, v}} -> { k = {v1, v2} }
local function header_map(hs)
  local out = {}
  for _, h in ipairs(hs or {}) do
    out[h[1]] = out[h[1]] or {}
    table.insert(out[h[1]], h[2])
  end
  return out
end

local function run_lua(ctx)
  local vars, logs = {}, {}
  local function lookup(hs)
    return {
      -- works as headers.valueOf("x") and headers:valueOf("x")
      valueOf = function(a, b)
        local n = (type(a) == "table" and b or a):lower()
        for k, v in pairs(hs) do if k:lower() == n then return v[1] end end
      end,
      valuesOf = function(a, b)
        local n = (type(a) == "table" and b or a):lower()
        for k, v in pairs(hs) do if k:lower() == n then return v end end
        return {}
      end,
    }
  end
  -- client.global works both as client.global.token = x and client.global.set("token", x)
  local api = {
    set = function(k, v) M.globals[k] = v end, get = function(k) return M.globals[k] end,
    isEmpty = function() return next(M.globals) == nil end,
    clear = function(k) M.globals[k] = nil end, clearAll = function() M.globals = {} end,
  }
  local global = setmetatable({}, {
    __index = function(_, k) return api[k] or M.globals[k] end,
    __newindex = function(_, k, v) M.globals[k] = v end,
  })
  local client = {
    global = global,
    log = function(...) table.insert(logs, table.concat(vim.tbl_map(function(x) return type(x) == "string" and x or vim.inspect(x) end, { ... }), " ")) end,
    test = function(name, fn)
      local ok, err = pcall(fn)
      table.insert(logs, (ok and "✔ " or "✘ ") .. name .. (ok and "" or (": " .. tostring(err))))
    end,
    assert = function(c, msg) if not c then error(msg or "assertion failed", 2) end end,
  }
  local rh = ctx.request.headers
  local request = vim.tbl_extend("force", ctx.request, {
    headers = setmetatable(vim.deepcopy(rh), { __index = lookup(rh) }),
    variables = { set = function(k, v) vars[k] = v end, get = function(k) return vars[k] or ctx.vars[k] end },
    environment = { get = function(k) return ctx.env[k] end },
  })
  local response
  if ctx.response then
    local ok, body = pcall(vim.json.decode, ctx.response.body)
    local hs = ctx.response.headers
    response = {
      body = ok and body or ctx.response.body, body_raw = ctx.response.body, status = ctx.response.status,
      headers = setmetatable(vim.deepcopy(hs), { __index = lookup(hs) }),
    }
  end
  local env = setmetatable({ client = client, request = request, response = response }, { __index = _G })
  local fn, err = load(ctx.code, "http script", "t", env)
  local result
  if not fn then
    table.insert(logs, "✘ script error: " .. err)
  else
    local ok, e = pcall(fn)
    if not ok then table.insert(logs, "✘ script error: " .. tostring(e)) else result = e end
  end
  if type(result) == "table" then result = vim.json.encode(result) end
  return vars, logs, result ~= nil and tostring(result) or nil
end

-- run one script; returns request-scoped vars and log lines. Globals are updated and persisted.
-- script = { code = "...", file = "path" }, ctx = { request = {...}, response = {...}?, vars, env, dir }
local function run(script, ctx)
  local code, lang = script.code, "js"
  if script.file then
    local p = script.file:match("^/") and script.file or (ctx.dir .. "/" .. script.file)
    local f = io.open(p)
    if not f then return {}, { "✘ cannot read script " .. p } end
    code = f:read("*a")
    f:close()
    if p:match("%.lua$") then lang = "lua" end
  elseif code:match("^%s*%-%-%s*lua") then
    lang = "lua"
  end
  local request = { method = ctx.request.method, url = ctx.request.url, body = ctx.request.body, headers = header_map(ctx.request.headers) }
  local response = ctx.response and { body = ctx.response.body, status = ctx.response.status, headers = header_map(ctx.response.headers) }
  local vars, logs, result
  if lang == "lua" then
    vars, logs, result = run_lua({ code = code, request = request, response = response, vars = ctx.vars, env = ctx.env })
  else
    if vim.fn.executable("node") == 0 then return {}, { "✘ node is not installed (needed for JS scripts)" } end
    local input = vim.json.encode({
      code = code, globals = next(M.globals) and M.globals or vim.empty_dict(),
      request = request, response = response or vim.NIL,
      vars = next(ctx.vars) and ctx.vars or vim.empty_dict(), env = next(ctx.env) and ctx.env or vim.empty_dict(),
    })
    -- cwd = the .http file's dir, so require("./x") resolves next to it
    local res = vim.system({ "node", "-e", js_harness }, { text = true, stdin = input, cwd = ctx.dir }):wait(60000)
    local ok, out = pcall(vim.json.decode, res.stdout or "")
    if res.code ~= 0 or not ok then
      return {}, { "✘ node failed" .. (res.code == 124 and " (timed out after 60s)" or "") .. ": " .. vim.trim(res.stderr or "") }
    end
    M.globals = out.globals
    vars, logs, result = out.vars, out.logs, out.result ~= vim.NIL and out.result or nil
  end
  save()
  return vars, logs, result
end

-- returns vars, logs and the script's `return` value as a string (JSON for tables/objects)
function M.run(script, ctx)
  local ok, vars, logs, result = pcall(run, script, ctx)
  if not ok then return {}, { "✘ script error: " .. tostring(vars) } end
  return vars or {}, logs or {}, result
end

return M
