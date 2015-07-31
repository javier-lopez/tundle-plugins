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
    if [ "${verbose}" = "y" ]; then
        _copycat_mode_add_helper "${yank_key}" "tmux save-buffer - | ${clipboard_cmd}" "msg:Copied tmux buffer to system clipboard"
    else
        _copycat_mode_add_helper "${yank_key}" "tmux save-buffer - | ${clipboard_cmd}"
    fi

    _copycat_mode_add_helper "${put_key}"      "tmux paste-buffer"
    _copycat_mode_add_helper "${yank_put_key}" "tmux save-buffer - | ${clipboard_cmd}; tmux paste-buffer"
    _copycat_mode_generate_helper #& #?
else
    for key in "${yank_key}" "${put_key}" "${yank_put_key}"; do
        _copycat_mode_add_helper "${key}" \
            "tmux display-message 'Error! tmux-yank dependencies (xclip|xsel|pbcopy) not installed!'; ${tmux_copycat_dir}/scripts/copycat_mode_quit.sh"
    done
    _copycat_mode_generate_helper #& #?
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
