local mod = "ALT"

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.on("hyprland.start", function()
    hl.exec_cmd("bash -lc 'hyprpaper & sleep 0.3; hyprctl hyprpaper wallpaper \"eDP-1,/home/nukkua/wallpapers/goat_extended.jpg\"'")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE")
end)

hl.config({
    input = {
        kb_layout = "us", repeat_rate = 40, repeat_delay = 250, follow_mouse = 1,
        touchpad = { natural_scroll = false, scroll_factor = 2.0 },
    },
    general = {
        gaps_in = 1, gaps_out = 1, border_size = 0,
        col = { active_border = "rgb(c0cbff)", inactive_border = "rgb(555555)" },
        layout = "master",
    },
    master = { mfact = 0.60, new_status = "slave", new_on_top = false },
    decoration = { rounding = 0, shadow = { enabled = false } },
    animations = { enabled = true },
    misc = { disable_hyprland_logo = true, disable_splash_rendering = true, focus_on_activate = true },
})

hl.curve("smooth", { type = "bezier", points = {{0.25, 0.9}, {0.25, 1.0}} })
hl.animation({ leaf = "windows", enabled = false, speed = 0 })
hl.animation({ leaf = "windowsOut", enabled = false, speed = 0 })
hl.animation({ leaf = "fade", enabled = true, speed = 1.5, bezier = "smooth" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.5, bezier = "smooth", style = "fade" })

hl.window_rule({ name = "brave-workspace", match = { class = "brave-origin" }, workspace = 1 })
hl.window_rule({ name = "brave-fullscreen", match = { class = "brave-origin" }, suppress_event = "fullscreen", fullscreen_state = "2 0" })

local function bind(key, command)
    hl.bind(mod .. " + " .. key, hl.dsp.exec_cmd(command))
end

bind("Return", "bash -lc \"if hyprctl activeworkspace | grep -q 'windows: 0'; then kitty --start-as fullscreen; else kitty; fi\"")
bind("U", "shutdown now")
bind("Y", "brave-origin --remote-debugging-port=9222 --force-device-scale-factor=1.30")
bind("D", "discord --enable-features=UseOzonePlatform --ozone-platform=wayland")
bind("O", "bash -lc 'mkdir -p ~/Pictures/Screenshots; f=\"$HOME/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png\"; g=$(slurp) || exit; grim -g \"$g\" \"$f\" && wl-copy -t image/png < \"$f\" && notify-send \"Screenshot saved\" \"$f\"'")
bind("Print", "bash -lc 'mkdir -p ~/Pictures/Screenshots; f=\"$HOME/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png\"; g=$(slurp) || exit; grim -g \"$g\" \"$f\" && wl-copy -t image/png < \"$f\" && notify-send \"Screenshot saved\" \"$f\"'")
bind("A", "kitty --start-as fullscreen -e bash -lc $HOME/scripts/personal.sh")
bind("E", "kitty --start-as fullscreen -e bash -lc $HOME/scripts/work.sh")
bind("I", "kitty --start-as fullscreen -e bash -lc $HOME/scripts/pdf_searcher.sh")
bind("B", "rofi -show drun -theme /home/nukkua/.config/rofi/sakura.rasi")
bind("C", "bash -lc \"$HOME/.config/fuzzel/web.sh\"")
bind("CTRL + C", "bash -lc \"$HOME/.config/fuzzel/web.sh --tabs-only\"")
bind("P", "kitty -e pulsemixer")
bind("G", "stochos --bisect")
bind("minus", "brightnessctl set 2.5%-")
bind("M", "brightnessctl set 2.5%+")
hl.bind("CTRL + M", hl.dsp.exec_cmd("amixer -q set Master toggle"))
hl.bind("CTRL + up", hl.dsp.exec_cmd("amixer -q set Master 5%+ unmute"))
hl.bind("CTRL + down", hl.dsp.exec_cmd("amixer -q set Master 5%- unmute"))
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mod .. " + J", hl.dsp.window.cycle_next())
bind("K", "hyprctl dispatch cyclenext prev")
bind("SHIFT + J", "hyprctl dispatch swapnext")
bind("SHIFT + K", "hyprctl dispatch swapnext prev")
local workspaces = { S = 1, N = 2, T = 3, R = 4, W = 5 }
for key, workspace in pairs(workspaces) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

bind("comma", "hyprctl dispatch focusmonitor -1")
bind("period", "hyprctl dispatch focusmonitor +1")
hl.bind(mod .. " + SHIFT + comma", hl.dsp.window.move({ monitor = -1 }))
hl.bind(mod .. " + SHIFT + period", hl.dsp.window.move({ monitor = 1 }))
bind("L", "hyprctl dispatch resizeactive 20 0")
bind("H", "hyprctl dispatch resizeactive -20 0")
bind("SHIFT + space", "hyprctl dispatch togglefloating")
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
bind("X", "hyprctl reload")
hl.bind("ALT + Z", hl.dsp.exec_cmd("sh -c 'pgrep -x woomer >/dev/null && pkill -INT -x woomer || exec woomer'"))
