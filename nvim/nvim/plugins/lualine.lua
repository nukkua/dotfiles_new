local lualine = require('lualine')
local palette = require("plugins.colorsset").palette


local function lsp_status()
    local s = ""
    s = '?'
    local client = vim.lsp.get_active_clients({
        bufnr = vim.api.nvim_get_current_buf()
    })[1]
    if client ~= nil then
        s = client.name
        if not client.initialized then
            s = '+' .. s
        end

        local has_pending = false
        for k, v in pairs(client.requests) do
            if v.type and v.type == "pending" then
                has_pending = true
                break
            end
        end
        if has_pending then
            s = '*' .. s
        end
    end
    return s
end

local theme = {
    replace = {
        a = { bg = palette.color6, fg = palette.color5, gui = 'bold' },
        b = { bg = palette.color5, fg = palette.color14 },
        c = { bg = palette.bg, fg = palette.color15 },
        x = { bg = palette.bg, fg = palette.color15, gui = 'bold' },
        y = { bg = palette.color13, fg = palette.color7 },
        z = { bg = palette.color5, fg = palette.color15 }
    },
    normal = {
        a = { bg = palette.color9, fg = palette.color11, gui = 'bold' },
        b = { bg = palette.color6, fg = palette.color7 },
        c = { bg = palette.bg, fg = palette.color15 },
        x = { bg = palette.bg, fg = palette.color15, gui = 'bold' },
        y = { bg = palette.color14, fg = palette.color7 },
        z = { bg = palette.color1, fg = palette.color11 }
    },
    visual = {
        a = { bg = palette.color12, fg = palette.color4, gui = 'bold' },
        b = { bg = palette.color4, fg = palette.color15 },
        c = { bg = palette.bg, fg = palette.color15 },
        x = { bg = palette.bg, fg = palette.color15, gui = 'bold' },
        y = { bg = palette.color12, fg = palette.color5 },
        z = { bg = palette.color6, fg = palette.color7 }
    },
    command = {
        a = { bg = palette.color13, fg = palette.color15, gui = 'bold' },
        b = { bg = palette.color10, fg = palette.color7 },
        c = { bg = palette.bg, fg = palette.color15 },
        x = { bg = palette.bg, fg = palette.color15, gui = 'bold' },
        y = { bg = palette.color2, fg = palette.color15 },
        z = { bg = palette.color5, fg = palette.color15 }
    },
    insert = {
        a = { bg = palette.color0, fg = palette.color11, gui = 'bold' },
        b = { bg = palette.color8, fg = palette.color7 },
        c = { bg = palette.bg, fg = palette.color15 },
        x = { bg = palette.bg, fg = palette.color15, gui = 'bold' },
        y = { bg = palette.color11, fg = palette.color7 },
        z = { bg = palette.color3, fg = palette.color7 }
    },
    inactive = {
        a = { bg = palette.color7, fg = palette.color7, gui = 'bold' },
        b = { bg = palette.color0, fg = palette.color7 },
        c = { bg = palette.color7, fg = palette.color15 },
        x = { bg = palette.bg, fg = palette.color15, gui = 'bold' },
        y = { bg = palette.color7, fg = palette.color8 },
        z = { bg = palette.color0, fg = palette.color0 }
    },
}

lualine.setup {
    options = {
        theme = theme,
        refresh = {
            statusline = 500
        }
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { 'filename' },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {},
    },
}
