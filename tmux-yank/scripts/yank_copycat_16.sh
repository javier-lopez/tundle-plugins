#!/bin/sh

#copycat integration for older tmux versions without copy-pipe
#this script is source from tmux-copycat/scripts/copycat_mode_start.sh
. "${tmux_yank_dir}/scripts/vars.sh"
. "${tmux_yank_dir}/scripts/helpers.sh"

yank_key="$(_get_tmux_option_global_helper "${yank_option}" "${yank_default}")"
put_key="$(_get_tmux_option_global_helper "${put_option}" "${put_default}")"
yank_put_key="$(_get_tmux_option_global_helper "${yank_put_option}" "${yank_put_default}")"
verbose=$(_get_tmux_option_global_helper "${verbose_mode_option}" "${verbose_mode_default}")

if clipboard_cmd="$(_clipboard_cmd_helper)"; then
    tmux bind-key -n "${yank_key}" run "tmux send-keys Enter;
        tmux save-buffer - | ${clipboard_cmd};
        $([ "${verbose}" = "y" ] && printf "%s" "tmux display-message 'Copied tmux buffer to system clipboard';")
        ${tmux_copycat_dir}/scripts/copycat_mode_quit.sh;
        tmux unbind-key -n ${yank_key};"

    tmux bind-key -n "${put_key}" run "tmux send-keys Enter;
        tmux paste-buffer; ${tmux_copycat_dir}/scripts/copycat_mode_quit.sh;
        tmux unbind-key -n ${put_key};"

    tmux bind-key -n "${yank_put_key}" run "tmux send-keys Enter;
        tmux save-buffer - | ${clipboard_cmd};
        tmux paste-buffer; ${tmux_copycat_dir}/scripts/copycat_mode_quit.sh;
        tmux unbind-key -n ${yank_put_key};"

    tmux bind-key -n q run "tmux unbind-key -n ${yank_key}; tmux unbind-key -n ${put_key};
        tmux unbind-key -n ${yank_put_key}; ${tmux_copycat_dir}/scripts/copycat_mode_quit.sh;
        tmux send-keys q";

    tmux bind-key -n C-c run "tmux unbind-key -n ${yank_key}; tmux unbind-key -n ${put_key};
        tmux unbind-key -n ${yank_put_key}; ${tmux_copycat_dir}/scripts/copycat_mode_quit.sh;
        tmux send-keys C-c"
else
    for key in "${yank_key}" "${put_key}" "${yank_put_key}"; do
        tmux bind-key -n "${key}" run "tmux send-keys Enter;
            tmux run \"tmux display-message 'Error! tmux-yank dependencies (xclip|xsel|pbcopy) not installed!';
            ${tmux_copycat_dir}/scripts/copycat_mode_quit.sh;
            tmux unbind-key -n ${key}\""
    done

    tmux bind-key -n q run "tmux unbind-key -n ${yank_key}; tmux unbind-key -n ${put_key};
        tmux unbind-key -n ${yank_put_key}; ${tmux_copycat_dir}/scripts/copycat_mode_quit.sh;
        tmux send-keys q";

    tmux bind-key -n C-c run "tmux unbind-key -n ${yank_key}; tmux unbind-key -n ${put_key};
        tmux unbind-key -n ${yank_put_key}; ${tmux_copycat_dir}/scripts/copycat_mode_quit.sh;
        tmux send-keys C-c"
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
