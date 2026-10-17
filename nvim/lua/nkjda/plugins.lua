-- nkjda/plugins.lua — plugin list (vim.pack) + plugin setups

vim.pack.add({
    { src = "https://github.com/j-hui/fidget.nvim" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main" },
    { src = "https://github.com/windwp/nvim-ts-autotag" },

    { src = "https://github.com/echasnovski/mini.nvim" },
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/ThePrimeagen/harpoon",                       version = "harpoon2" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/xeluxee/competitest.nvim" },
    { src = "https://github.com/MunifTanjim/nui.nvim" },
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
    { src = "https://github.com/L3MON4D3/LuaSnip" },
    { src = "https://github.com/Saghen/blink.cmp",                           version = vim.version.range("*") },
    { src = "https://github.com/dmtrKovalenko/fff" },
    { src = "https://github.com/NeogitOrg/neogit" },
})

-- fff binary build on install/update
vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
        local name, kind = ev.data.spec.name, ev.data.kind
        if name == 'fff' and (kind == 'install' or kind == 'update') then
            if not ev.data.active then vim.cmd.packadd('fff') end
            require('fff.download').download_or_build_binary()
        end
    end,
})

vim.g.fff = {
    title = 'fff',
    prompt_vim_mode = false,
    prompt = '> ',
    lazy_sync = true,
    keymaps = { close = '<C-a>', cycle_grep_modes = '<C-s>' },
    git = { enabled = false, show_status = false, status_text_color = false },
    file_picker = {
        current_file_label = '(current)',
        fuzzy_query_highlighting = false,
    },
}

-- competitest (lazy-loaded on cpp FileType)
local competitest_loaded = false
local function load_competitest()
    if competitest_loaded then return end
    vim.cmd("packadd competitest.nvim")
    require("competitest").setup({
        companion_port = 27121,
        evaluate_template_modifiers = true,
        template_file = { cpp = "~/cf/templates/template.cpp" },
        received_contests_problems_path = "$(PROBLEM)/main.$(FEXT)",
    })
    competitest_loaded = true
end

-- expose for keymaps.lua
_G._nkjda_load_competitest = load_competitest

vim.api.nvim_create_autocmd("FileType", {
    pattern = "cpp",
    callback = function() load_competitest() end,
})

-- harpoon / oil / fidget
local harpoon = require("harpoon")
harpoon:setup()

require("oil").setup({
    view_options = { show_hidden = true, natural_order = "fast" },
    columns = {},
    delete_to_trash = false,
    skip_confirm_for_simple_edits = true,
    prompt_save_on_select_new_entry = false,
    default_file_explorer = true,
    cleanup_delay_ms = 0,
    watch_for_changes = false,
    confirmation = { max_width = 0.4, max_height = 0.2, border = "rounded", win_options = { winblend = 0 } },
})

require("fidget").setup {
    progress = { suppress_on_insert = true, poll_rate = 0 },
    notification = {
        poll_rate = 5,
        window = { winblend = 0, normal_hl = "NormalFloat" },
    }
}

-- treesitter parsers (incl. html/xml for autotag) + highlight
require("nvim-treesitter").install({
    "c", "cpp", "lua", "rust", "html", "xml",
    "javascript", "typescript", "vue", "astro", "svelte", "go", "http",
})
vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "c", "cpp", "lua", "rust", "html", "xml",
        "javascript", "typescript", "javascriptreact", "typescriptreact",
        "vue", "astro", "svelte", "go", "http",
    },
    callback = function() vim.treesitter.start() end,
})

-- tag rename/close via treesitter
require("nvim-ts-autotag").setup()



-- mini.surround only (monorepo, don't setup other mini modules)
-- sa add, sd delete, sr replace (e.g. sr t div<CR> swaps both tags), sF/sf jump
require("mini.surround").setup()

-- neogit (replace buffer, not tab) — d on a file opens plain vimdiff vs HEAD, no plugins
-- ponytail: <cfile> + git plumbing only; untracked files have no HEAD to diff, so they warn
local function _neogit_vimdiff()
  local git_dir = vim.b.neogit_git_dir
  local line = vim.api.nvim_get_current_line()
  local file = line:match("^%s*%S+%s+(.-)%s*$") or vim.fn.expand("<cfile>")
  if not git_dir or git_dir == "" or file == "" then
    vim.notify("no file under cursor", vim.log.levels.WARN)
    return
  end
  local root = vim.fn.systemlist({ "git", "--git-dir=" .. git_dir, "rev-parse", "--show-toplevel" })[1]
  if not root or root == "" then return end
  local rel = file:gsub("^" .. vim.pesc(root .. "/"), "")
  vim.fn.system({ "git", "-C", root, "cat-file", "-e", "HEAD:" .. rel })
  if vim.v.shell_error ~= 0 then
    vim.notify("untracked: nothing in HEAD to diff", vim.log.levels.WARN)
    return
  end
  -- ponytail: one diff at a time; repeat-d replaces instead of stacking splits
  vim.cmd("diffoff!")
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.b[b].neogit_head_scratch then vim.api.nvim_buf_delete(b, { force = true }) end
  end
  local abs = root .. "/" .. rel
  if vim.fn.filereadable(abs) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(abs))
  else
    vim.cmd("enew") -- deleted in worktree: empty side still diffs vs HEAD
    vim.bo.buftype = "nofile"
  end
  vim.b.neogit_work_diff = true
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
  vim.b.neogit_head_scratch = true
  vim.cmd("diffthis")
  vim.api.nvim_set_option_value("winbar", "%#Comment# head %*", { win = head_win })
end
require("neogit").setup({
  kind = "replace",
  mappings = {
    popup = { ["d"] = false, ["D"] = "DiffPopup" }, -- d is vimdiff now; popup moves to D
    status = { ["d"] = _neogit_vimdiff },
  },
})
-- :DiffOff closes the diff (HEAD split + labels) and goes back to neogit
vim.api.nvim_create_user_command("DiffOff", function()
  local closed = false
  vim.cmd("diffoff!")
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.b[b].neogit_head_scratch or vim.b[b].neogit_work_diff then
      vim.api.nvim_set_option_value("winbar", "", { win = w })
      if vim.b[b].neogit_head_scratch then
        vim.api.nvim_buf_delete(b, { force = true })
      else
        vim.b[b].neogit_work_diff = nil
      end
      closed = true
    end
  end
  if closed then require("neogit").open() end
end, { desc = "Close diff, back to Neogit" })

-- expose harpoon for keymaps.lua
_G._nkjda_harpoon = harpoon
