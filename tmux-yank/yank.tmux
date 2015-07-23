#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/scripts/vars.sh"
. "${CURRENT_DIR}/scripts/helpers.sh"

_display_deps_error() {
    printf '%s\n' "tmux display-message 'Error! tmux-yank dependencies (xclip|xsel|pbcopy) not installed!'"
}

if _supported_tmux_version_helper; then
    yank_key="$(_get_tmux_option_global_helper "${yank_option}" "${yank_default}")"
    put_key="$(_get_tmux_option_global_helper "${put_option}" "${put_default}")"
    yank_put_key="$(_get_tmux_option_global_helper "${yank_put_option}" "${yank_put_default}")"
    yank_wo_newline_key="$(_get_tmux_option_global_helper "${yank_wo_newline_option}" "${yank_wo_newline_default}")"
    yank_line_key="$(_get_tmux_option_global_helper "${yank_line_option}" "${yank_line_default}")"
    verbose=$(_get_tmux_option_global_helper "${verbose_mode_option}" "${verbose_mode_default}")

    if clipboard_cmd="$(_clipboard_cmd_helper)"; then
        clipboard_wo_newline_cmd="tr -d '\n' | ${clipboard_cmd}"

        if [ "${TMUX_VERSION}" -ge "18" ]; then #copy-pipe appeared in tmux 1.8
            for mode in vi-copy emacs-copy; do
                if [ "${verbose}" = "y" ]; then
                    tmux bind-key -t "${mode}" "${yank_key}" \
                        copy-pipe "${clipboard_cmd}; tmux display-message 'Copied tmux buffer to system clipboard'"
                else
                    tmux bind-key -t "${mode}" "${yank_key}" copy-pipe "${clipboard_cmd}"
                fi
                tmux bind-key -t "${mode}" "${put_key}"      copy-pipe "tmux paste-buffer"
                tmux bind-key -t "${mode}" "${yank_put_key}" copy-pipe "${clipboard_cmd}; tmux paste-buffer"

                #this binding isn't intended to be used by the user. It is a helper for the `yank_line.sh` command
                tmux bind-key -t "${mode}" "${yank_wo_newline_key}" copy-pipe "${clipboard_wo_newline_cmd}"
            done
        else
            #due to tmux limitations on versions < 1.8 yanking to the system clipboard is only possible traditionally in two steps
            #1. copy to tmux-buffer in copy-mode
            #2. sync tmux-buffer with the system clipboard

            #radical hack to do the above in one keystroke, http://unix.stackexchange.com/a/44602/63300
            if [ "${verbose}" = "y" ]; then
                _tmux_copy_mode_add_helper "${yank_key}" "tmux save-buffer - | ${clipboard_cmd}" "msg:Copied tmux buffer to system clipboard"
            else
                _tmux_copy_mode_add_helper "${yank_key}" "tmux save-buffer - | ${clipboard_cmd}"
            fi
            _tmux_copy_mode_add_helper "${put_key}"      "tmux paste-buffer"
            _tmux_copy_mode_add_helper "${yank_put_key}" "tmux save-buffer - | ${clipboard_cmd}; tmux paste-buffer"

            for copy_mode_key in $(_get_tmux_copy_mode_keys); do
                _tmux_copy_mode_generate_helper "${copy_mode_key}" #& #?
            done

            #just for completeness, this should never be the case
            for mode in vi-copy emacs-copy; do
                tmux bind -t "${mode}" "${yank_key}" copy-selection
            done
        fi
        tmux bind-key "${yank_line_key}" run-shell "${CURRENT_DIR}/scripts/yank_line.sh"
    else
        if [ "${TMUX_VERSION}" -ge "18" ]; then
            for mode in vi-copy emacs-copy; do
                for key in "${yank_key}" "${put_key}" "${yank_put_key}"; do
                    tmux bind-key -t "${mode}" "${key}" run-shell "$(_display_deps_error)"
                done
            done
        else
            for key in "${yank_key}" "${put_key}" "${yank_put_key}"; do
                _tmux_copy_mode_add_helper "${key}" "$(_display_deps_error)"
            done
            for copy_mode_key in $(_get_tmux_copy_mode_keys); do
                _tmux_copy_mode_generate_helper "${copy_mode_key}" #& #?
            done

            tmux bind-key "${yank_line_key}" run-shell "$(_display_deps_error)"
        fi
    fi
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
        #"Error, Tmux version unsupported! Please install Tmux version ${SUPPORTED_TMUX_VERSION} or greater!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
