-- nkjda/claude.lua — claude code in a right vsplit terminal
-- toggle: <leader>tc (keymaps.lua). kill: q / :q / <leader>q inside it, confirms while claude is working.
-- busy/done come from claude hooks calling back into this nvim over $NVIM (set for every :terminal job)

local M = {}
local S = { buf = nil, job = nil, busy = false }

-- called by the hooks below via `nvim --server $NVIM --remote-expr`
_G._nkjda_claude_state = function(state)
  vim.schedule(function()
    S.busy = state == "busy"
    if state == "done" then
      vim.cmd("silent! checktime") -- pick up files claude just edited
      if vim.api.nvim_get_current_buf() ~= S.buf then vim.notify("claude is done") end
    end
  end)
  return ""
end

local function hook(state)
  local cmd = ([[nvim --clean --server "$NVIM" --remote-expr 'v:lua._nkjda_claude_state("%s")' >/dev/null 2>&1 || true]])
    :format(state)
  return { { hooks = { { type = "command", command = cmd } } } }
end
-- ponytail: Stop doesn't fire on a user interrupt, so <Esc> inside the terminal also clears busy
local settings = vim.json.encode({ hooks = { UserPromptSubmit = hook("busy"), Stop = hook("done") } })

function M.kill()
  if not (S.buf and vim.api.nvim_buf_is_valid(S.buf)) then return end
  if S.busy and vim.fn.confirm("Claude is working. Kill it?", "&Yes\n&No", 2) ~= 1 then return end
  local buf = S.buf
  S.buf, S.job, S.busy = nil, nil, false
  vim.api.nvim_buf_delete(buf, { force = true }) -- force kills the job
end

local function open_win()
  vim.cmd("botright vsplit")
  vim.api.nvim_win_set_width(0, math.floor(vim.o.columns * 0.4))
end

function M.toggle()
  if S.buf and vim.api.nvim_buf_is_valid(S.buf) then
    local win = vim.fn.bufwinid(S.buf)
    if win ~= -1 then
      pcall(vim.api.nvim_win_hide, win) -- fails only when it's the last window
    else
      open_win()
      vim.api.nvim_win_set_buf(0, S.buf)
      vim.cmd("startinsert")
    end
    return
  end

  open_win()
  vim.cmd("enew")
  local buf = vim.api.nvim_get_current_buf()
  S.buf, S.busy = buf, false
  S.job = vim.fn.jobstart({ "claude", "--settings", settings }, {
    term = true,
    on_exit = function()
      if S.buf == buf then S.buf, S.job, S.busy = nil, nil, false end
      if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
    end,
  })
  vim.bo[buf].buflisted = false

  local o = { buffer = buf }
  vim.keymap.set("n", "q", M.kill, o)
  vim.keymap.set("n", "<leader>q", M.kill, o)
  vim.keymap.set("ca", "q", function()
    return (vim.fn.getcmdtype() == ":" and vim.fn.getcmdline() == "q") and "lua require('nkjda.claude').kill()" or "q"
  end, { buffer = buf, expr = true })
  vim.keymap.set("t", "<Esc>", function() S.busy = false; return "<Esc>" end, { buffer = buf, expr = true })
  vim.cmd("startinsert")
end

return M
