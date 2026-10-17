-- nkjda/select.lua — vim.ui.select as a bottom split with home-row labels, neogit only
-- neogit has no telescope/fzf here, so it falls back to vim.ui.select; every other caller gets the default
-- labels pick from the visible page; j/k scroll one line, <C-d>/<C-u> a page, q/<Esc> cancels

local labels = { "d", "i", "e", "a", "o", "s", "n", "t", "r", "w" }
local ns = vim.api.nvim_create_namespace("nkjda_select")

local default_select = vim.ui.select

vim.ui.select = function(items, opts, on_choice)
  if not debug.getinfo(2, "S").source:find("/neogit/", 1, true) then
    return default_select(items, opts, on_choice)
  end
  opts = opts or {}
  local fmt = opts.format_item or tostring
  if #items == 0 then return on_choice(nil, nil) end

  local height = math.min(#labels, #items)
  local max_top, top = #items - height, 0
  local prompt = opts.prompt and vim.trim(opts.prompt):gsub(":$", "") or "Select"

  -- bottom split like neogit popups; winbar holds prompt + position
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, { split = "below", win = -1, height = height })
  for k, v in pairs({ number = false, relativenumber = false, signcolumn = "no", foldcolumn = "0",
    cursorline = false, wrap = false, winfixheight = true, statuscolumn = "" }) do vim.wo[win][k] = v end

  local function render()
    local lines = {}
    for i = 1, height do lines[i] = labels[i] .. "  " .. fmt(items[top + i]) end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for i = 1, height do
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { end_col = 1, hl_group = "NeogitPopupActionKey" })
    end
    local pos = max_top > 0 and ("%%=%d-%d/%d "):format(top + 1, top + height, #items) or ""
    vim.wo[win].winbar = "%#NeogitPopupSectionTitle# " .. prompt:gsub("%%", "%%%%") .. "%*" .. pos
  end

  local finished = false
  local function finish(idx)
    if finished then return end
    finished = true
    pcall(vim.api.nvim_win_close, win, true)
    on_choice(idx and items[idx] or nil, idx)
  end

  local function map(lhs, fn) vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true }) end
  local function scroll(d) return function() top = math.max(0, math.min(max_top, top + d)); render() end end
  for i, l in ipairs(labels) do map(l, function() if i <= height then finish(top + i) end end) end
  for _, l in ipairs({ "j", "<Down>", "<C-n>" }) do map(l, scroll(1)) end
  for _, l in ipairs({ "k", "<Up>", "<C-p>" }) do map(l, scroll(-1)) end
  for _, l in ipairs({ "<C-d>", "<C-f>", "<PageDown>" }) do map(l, scroll(height)) end
  for _, l in ipairs({ "<C-u>", "<C-b>", "<PageUp>" }) do map(l, scroll(-height)) end
  map("go", function() top = 0; render() end)
  map("G", function() top = max_top; render() end)
  for _, l in ipairs({ "q", "<Esc>", "<C-c>" }) do map(l, function() finish(nil) end) end
  -- focus lost (mouse click, :wincmd) counts as cancel so the caller is never left hanging
  vim.api.nvim_create_autocmd("WinLeave", { buffer = buf, once = true, callback = function() finish(nil) end })

  render()
end
