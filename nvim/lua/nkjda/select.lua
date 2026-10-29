-- nkjda/select.lua — a picker as a quickfix list
-- <CR> picks the cursor row, q/<Esc> or leaving the window cancels
-- used by <leader>ts (keymaps.lua) and the git status pickers (git.lua)

local M = {}
-- one height for every bottom split (this picker + git popups) so they don't jump around
M.height = 12

function M.select(items, opts, on_choice)
  opts = opts or {}
  local fmt = opts.format_item or tostring
  if #items == 0 then return on_choice(nil, nil) end

  local qf = {}
  for i, it in ipairs(items) do qf[i] = { text = fmt(it) } end
  -- new list (not "r") so :colder gets the previous errors back
  vim.fn.setqflist({}, " ", {
    title = opts.prompt and vim.trim(opts.prompt):gsub(":$", "") or "Select",
    items = qf,
    quickfixtextfunc = function(info)
      local lines = {}
      for i, it in ipairs(vim.fn.getqflist({ id = info.id, items = 1 }).items) do
        lines[i] = it.text
      end
      return lines
    end,
  })
  local id = vim.fn.getqflist({ id = 0 }).id
  vim.cmd("copen " .. M.height)
  local buf = vim.api.nvim_get_current_buf()

  local finished = false
  local function finish(idx)
    if finished then return end
    finished = true
    vim.cmd("cclose")
    on_choice(idx and items[idx] or nil, idx)
  end

  -- the qf buffer outlives this picker: keys only act while this list is current, otherwise as usual
  local function map(key, fn)
    vim.keymap.set("n", key, function()
      if finished or vim.fn.getqflist({ id = 0 }).id ~= id then
        return vim.api.nvim_feedkeys(vim.keycode(key), "n", false)
      end
      fn()
    end, { buffer = buf, nowait = true })
  end
  map("<CR>", function() finish(vim.fn.line(".")) end)
  for _, l in ipairs({ "q", "<Esc>" }) do map(l, function() finish(nil) end) end
  -- focus lost (mouse click, :wincmd) counts as cancel so the caller is never left hanging
  vim.api.nvim_create_autocmd("WinLeave", { buffer = buf, once = true, callback = function() finish(nil) end })
end

return M
