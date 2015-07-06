#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/scripts/vars.sh"
. "${CURRENT_DIR}/scripts/helpers.sh"

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
            #2. sync tmux-buffer with the system clipboard (prefix+c-y on this plugin)

            #radical hack to do the above in one keystroke, http://unix.stackexchange.com/a/44602/63300
            for copy_mode_key in $(tmux list-keys | awk '/copy-mode$/ {print $2}'); do
                tmux bind-key "${copy_mode_key}" run "tmux copy-mode;
                    tmux bind-key -n ${yank_key} run \"tmux send-keys Enter;
                    tmux save-buffer - | ${clipboard_cmd};
                    $([ "${verbose}" = "y" ] && printf "%s" "tmux display-message 'Copied tmux buffer to system clipboard';")
                    tmux unbind-key -n ${yank_key}; tmux unbind-key -n ${put_key};
                    tmux unbind-key -n ${yank_put_key}; tmux unbind-key -n ${yank_wo_newline_key}\";

                    tmux bind-key -n ${put_key} run \"tmux send-keys Enter;
                    tmux paste-buffer;
                    tmux unbind-key -n ${yank_key}; tmux unbind-key -n ${put_key};
                    tmux unbind-key -n ${yank_put_key}; tmux unbind-key -n ${yank_wo_newline_key}\";

                    tmux bind-key -n ${yank_put_key} run \"tmux send-keys Enter;
                    tmux save-buffer - | ${clipboard_cmd};
                    tmux paste-buffer;
                    tmux unbind-key -n ${yank_key}; tmux unbind-key -n ${put_key};
                    tmux unbind-key -n ${yank_put_key}; tmux unbind-key -n ${yank_wo_newline_key}\";

                    tmux bind-key -n ${yank_wo_newline_key} run \"tmux send-keys Enter;
                    tmux save-buffer - | ${clipboard_wo_newline_cmd};
                    tmux unbind-key -n ${yank_key}; tmux unbind-key -n ${put_key};
                    tmux unbind-key -n ${yank_put_key}; tmux unbind-key -n ${yank_wo_newline_key}\";

                    tmux bind-key -n q run \"tmux unbind-key -n ${yank_key}; tmux unbind-key -n ${put_key};
                    tmux unbind-key -n ${yank_put_key}; tmux unbind-key -n ${yank_wo_newline_key};
                    tmux send-keys q\";
                    tmux bind-key -n C-c run \"tmux unbind-key -n ${yank_key}; tmux unbind-key -n ${put_key};
                    tmux unbind-key -n ${yank_put_key}; tmux unbind-key -n ${yank_wo_newline_key};
                    tmux send-keys C-c\""
            done

            #just for completeness, this should never be active
            for mode in vi-copy emacs-copy; do
                tmux bind -t "${mode}" "${yank_key}" copy-selection
            done

        fi
        tmux bind-key "${yank_line_key}" run-shell "${CURRENT_DIR}/scripts/yank_line.sh"
    else
        if [ "${TMUX_VERSION}" -ge "18" ]; then
            for mode in vi-copy emacs-copy; do
                for key in "${yank_key}" "${put_key}" "${yank_put_key}"; do
                    tmux bind-key -t "${mode}" "${key}" \
                        run-shell "tmux display-message 'Error! tmux-yank dependencies (xclip|xsel|pbcopy) not installed!'"
                done
            done
        else
            for copy_mode_key in $(tmux list-keys | awk '/copy-mode$/ {print $2}'); do
                for key in "${yank_key}" "${put_key}" "${yank_put_key}"; do
                    tmux bind-key "${copy_mode_key}" run "tmux copy-mode;
                        tmux bind-key -n ${key}
                        run \"tmux display-message 'Error! tmux-yank dependencies (xclip|xsel|pbcopy) not installed!';
                        tmux unbind-key -n ${key}\";
                        tmux bind-key -n q run \"tmux unbind -n ${key};
                        tmux send-keys q\";
                        tmux bind-key -n C-c run \"tmux unbind -n ${key};
                        tmux send-keys C-c\""
                done
            done
            tmux bind-key "${yank_line_key}" run-shell "tmux display-message 'Error! tmux-yank dependencies (xclip|xsel|pbcopy) not installed!'"
        fi
    fi
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
        #"Error, Tmux version unsupported! Please install Tmux version ${SUPPORTED_TMUX_VERSION} or greater!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
