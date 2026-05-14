local M = {}

local IDLE_MS = 30 * 1000

local timer = vim.uv.new_timer()
local stopped_by_idle = false

local function stop_lsps()
  vim.schedule(function()
    local clients = vim.lsp.get_clients()

    if #clients == 0 then
      return
    end

    for _, client in ipairs(clients) do
      client:stop()
    end

    stopped_by_idle = true
  end)
end

local function reset_timer()
  if timer then
    timer:stop()
    timer:start(IDLE_MS, 0, stop_lsps)
  end
end

local function restart_lsps()
  reset_timer()

  if not stopped_by_idle then
    return
  end

  stopped_by_idle = false

  vim.schedule(function()
    vim.cmd("silent! edit")
  end)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("LspIdleStopper", { clear = true })

  vim.api.nvim_create_autocmd({
    "CursorMoved",
    "CursorMovedI",
    "InsertEnter",
    "TextChanged",
    "TextChangedI",
    "BufEnter",
  }, {
    group = group,
    callback = reset_timer,
  })

  vim.api.nvim_create_autocmd("FocusLost", {
    group = group,
    callback = reset_timer,
  })

  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = restart_lsps,
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = reset_timer,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if timer then
        timer:stop()
        timer:close()
        timer = nil
      end
    end,
  })
end

return M
