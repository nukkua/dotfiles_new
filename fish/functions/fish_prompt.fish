function fish_prompt
        echo
        set_color -o ffb6c1
        set -l symbol ' $ '

        set -l color $fish_color_cwd
        if fish_is_root_user
                set symbol ' # '
                set -q fish_color_cwd_root
                and set color $fish_color_cwd_root
        end

        echo -n ' '
        echo -n (prompt_pwd)
        set_color normal

        echo -n $symbol
end

function fish_right_prompt
        set -l mode insert
        switch $fish_bind_mode
                case default
                        set mode normal
                case insert
                        set mode insert
                case replace_one replace
                        set mode replace
                case visual
                        set mode visual
        end

        set_color ffb6c1
        echo -n '['$mode']'

        if set -q SSH_TTY; or set -q SSH_CONNECTION
                set_color 8a8a8a
                echo -n '  󰆍 SSH'
        end

        set_color normal
end

function fish_mode_prompt
end
