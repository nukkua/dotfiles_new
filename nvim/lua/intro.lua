if vim.fn.argc() > 0 then
  return
end

if vim.version().minor < 12 then
  return
end

vim.opt.shortmess:append("I")

local lines = {
":-=+++:::-=-:::::::-+****#****++==++++**###+*",
":::::::::::::::::::::=***#******+++++++++++++",
"::::::::::::::::::::::-********###%####****+*",
":::::::::::::::::::::::-********#%%%%%%%%%##*",
"::::::::::::-::--:::::::=******+=====++*#####",
"::::::::::::::-:::::::::-++****+-:::::-======",
":::::::=-:::::=*-::::::::=-=#**-::::::-::::::",
":-::::-*+:::::-***=-:::::==*##+=-::::::::::::",
"-:-:::-#**:::::**#*=-::::=%##+-+*=--:-:::::::",
"==-::::-*:-::::+**+++*-::=@@=:::-========-:::",
"+=+-:::-*#*#*-:=######:::+-::--============::",
"+==-:---=######=-####*:::#*::=*++==========::",
"=====--==+#######*+*##-:=%+++-==----======-::",
"*###*=-++#**#########*:===+%@@@%*+-:::::--:::",
"+*###*-***:::-*####*+=-::*@##%%%%%%+=--::::::",
"*****##*%=::::=-+++=::=*#####*++*+==+++-:::::",
"###***###=...:=::++++########++-:-===++++-:::",
"#*+++*##%#...:=:.:+#######+-:--:::::-===+=--:",
"###*+***##=..:=:...:--::::::==:::::::--===---",
"=+**###*##+:.:--:::::::::::-+-:::::::::===---",
":+++*###%%#=.:----:::::::::=+-:::::::::-==-==",
"*+######%%#*-.----===========-:::::::::-=====",
"**#####%#***=..----==========-::..:::::-=====",
"==++=**+++++*:.:----=========-::...::::--====",
  "                 welcome back, nkjda",
}

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    local buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local width = 0
    for _, line in ipairs(lines) do
      width = math.max(width, vim.fn.strdisplaywidth(line))
    end

    local height = #lines
    local row = math.floor((vim.o.lines - height) / 3)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, false, {
      relative = "editor",
      row = row,
      col = col,
      width = width,
      height = height,
      style = "minimal",
      border = "none",
      focusable = false,
      noautocmd = true,
    })

    vim.wo[win].winhighlight = "NormalFloat:Normal"

    local function close_intro()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end

    vim.api.nvim_create_autocmd({
      "InsertEnter",
      "BufReadPre",
      "CursorMoved",
      "WinEnter",
    }, {
      once = true,
      callback = function()
        vim.schedule(close_intro)
      end,
    })
  end,
})
