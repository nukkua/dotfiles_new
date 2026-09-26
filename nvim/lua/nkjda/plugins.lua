-- nkjda/plugins.lua — plugin list (vim.pack) + plugin setups

vim.pack.add({
    { src = "https://github.com/j-hui/fidget.nvim" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main" },
    { src = "https://github.com/windwp/nvim-ts-autotag" },
    { src = "https://github.com/monaqa/dial.nvim" },
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
    { src = "https://github.com/tpope/vim-commentary" },
    { src = "https://github.com/dmtrKovalenko/fff" },
    { src = "https://github.com/lifepillar/vim-solarized8",                  branch = "neovim" },
    { src = "https://github.com/NeogitOrg/neogit" },
    { src = "https://github.com/mistweaverco/kulala.nvim" },
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
    debug = { enabled = true, show_scores = false},
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
    notification = { pool_rate = 5, window = { winblend = 0, normal_hl = "NormalFloat" } }
}

-- treesitter parsers (incl. html/xml for autotag) + highlight
require("nvim-treesitter").install({
    "c", "cpp", "lua", "rust", "html", "xml",
    "javascript", "typescript", "vue", "astro", "svelte", "go",
})
vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "c", "cpp", "lua", "rust", "html", "xml",
        "javascript", "typescript", "javascriptreact", "typescriptreact",
        "vue", "astro", "svelte", "go",
    },
    callback = function() vim.treesitter.start() end,
})

-- tag rename/close via treesitter
require("nvim-ts-autotag").setup()

-- dial: <C-a>/<C-x> that also cycles dates, hex, booleans, etc.
local augend = require("dial.augend")
local _dial_defaults = {
    augend.integer.alias.decimal,
    augend.integer.alias.hex,
    augend.date.alias["%Y/%m/%d"],
    augend.date.alias["%m/%d"],
    augend.date.alias["%H:%M"],
    augend.constant.alias.bool,
    augend.semver.alias.semver,
    augend.constant.new({ elements = { "and", "or" } }),
    augend.constant.new({ elements = { "&&", "||" } }),
    augend.constant.new({ elements = { "==", "!=" } }),
    augend.constant.new({ elements = { "let", "const" } }),
}
require("dial.config").augends:register_group({ default = _dial_defaults })
-- cpp: same defaults plus int/ll/ull/char type cycle
require("dial.config").augends:on_filetype({
    cpp = vim.list_extend(vim.deepcopy(_dial_defaults),
        { augend.constant.new({ elements = { "int", "ll", "ull", "char" } }) }),
})

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

-- kulala (http client) — opts from your lazy spec, adapted for vim.pack
pcall(function()
  require("kulala").setup({
    kulala_core = { path = nil, timeout = 60000, data_dir = nil, download_url = "https://github.com/mistweaverco/kulala-core/releases/download/%s/%s", download_tool = "curl" },
    session = { restore = true },
    treesitter = { enable = true, cli_path = "tree-sitter" },
    default_env = "default",
    environment_scope = "b",
    vscode_rest_client_environmentvars = false,
    response_format = { indent = 2, expand_tabs = true, sort_keys = false },
    ui = {
      display_mode = "split", split_direction = "right", win_opts = { bo = {}, wo = {} },
      default_view = "body", winbar = true,
      default_winbar_panes = { "body", "headers", "verbose", "script_output", "report" },
      winbar_labels = { body = "Body", headers = "Headers", headers_body = "All", verbose = "Verbose", script_output = "Script Output", stats = "Stats", report = "Report", help = "Help" },
      winbar_labels_keymaps = true, show_variable_info_text = false, show_icons = "on_request",
      icons = { inlay = { loading = "⏳", done = "✔", error = "✘" }, lualine = "🐼", textHighlight = "WarningMsg", loadingHighlight = "Normal", doneHighlight = "String", errorHighlight = "ErrorMsg" },
      show_request_summary = true, max_response_size = 32768, max_request_size = 2048,
      report = { show_script_output = true, show_asserts_output = true, show_summary = true, headersHighlight = "Special", successHighlight = "String", errorHighlight = "Error" },
      scratchpad_default_contents = { "@MY_TOKEN_NAME=my_token_value", "", "# @name scratchpad", "POST https://echo.kulala.app/post HTTP/1.1", "accept: application/json", "content-type: application/json", "", "{", '  "foo": "bar"', "}" },
      pickers = { snacks = { layout = function() local has_snacks, snacks_picker = pcall(require, "snacks.picker") return not has_snacks and {} or vim.tbl_deep_extend("force", snacks_picker.config.layout("telescope"), { reverse = true, layout = { { { win = "list" }, { height = 1, win = "input" }, box = "vertical" }, { win = "preview", width = 0.6 }, box = "horizontal", width = 0.8 } }) end } },
    },
    lsp = { enable = true, filetypes = { "http", "rest", "javascript", "typescript", "lua" }, enforce_external_script_naming_convention = true, keymaps = false, on_attach = nil },
    debug = 3, generate_bug_report = false,
    global_keymaps = {
      ["Send request"] = { "<leader>ks", function() require("kulala").run() end, mode = { "n", "v" }, desc = "Send request" },
      ["Send all requests"] = { "<leader>ka", function() require("kulala").run_all() end, mode = { "n", "v" }, desc = "Send all requests" },
      ["Open scratchpad"] = { "<leader>kb", function() require("kulala").scratchpad() end, desc = "Open scratchpad" },
      ["Replay the last request"] = { "<leader>kr", function() require("kulala").replay() end, desc = "Replay last request" },
      ["Manage Auth Config"] = { "<leader>ku", function() require("kulala.ui.auth_manager").open_auth_config() end, desc = "Manage Auth" },
    }, global_keymaps_prefix = "<leader>k",
    kulala_keymaps = true, kulala_keymaps_prefix = "",
    script_console_notify = true,
    openapi_panel_keymaps = true,
    openapi_panel = { split = "right", signs = { folded = ">", expanded = "v" }, highlights = { section = "Title", operation = "Function", parameter = "Identifier", response = "Number", schema = "Type", try_it_out = "String", description = "Comment", badge = "Comment", sign = "Special", value = "Constant" } },
  })
end)

-- expose harpoon for keymaps.lua
_G._nkjda_harpoon = harpoon
