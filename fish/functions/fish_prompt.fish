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

        echo -n ' '
        echo -n (prompt_pwd)
        echo -n ' ['
        echo -n $mode
        echo -n ']'
        set_color normal

        echo -n $symbol
end

function fish_mode_prompt
end
