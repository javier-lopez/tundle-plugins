#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/vars.sh"
. "${CURRENT_DIR}/helpers.sh"

#add sleep to deal with ssh latency
_sleep_in_remote_shells() {
    case "${1}" in
        ssh|mosh) sleep "${REMOTE_SHELL_WAIT_TIME}" ;;
    esac
}

if _supported_tmux_version_helper; then
    copy_mode="$(tmux show-option -gw | awk "/^mode-keys/ {gsub(/\'/,\"\");gsub(/\"/,\"\"); print \$2; exit;}")"
    shell_mode="$(_get_tmux_option_global_helper "${shell_mode_option}" "${shell_mode_default}")"
    if [ "${TMUX_VERSION}" -ge "18" ]; then
        pane_cmd="$(tmux display-message -p '#{pane_current_command}')"
    else
        pane_id="$(tmux list-panes -a -F '#{pane_pid}')"
        #this only works in Linux|Darwin, help required for other BSD systems
        pane_cmd="$(ps -eo "ppid command"|awk '$1 == "'"${pane_id}"'" {print $2; exit}')"
        [ -z "${pane_cmd}" ] && { pane_cmd="$(ps aux|awk '$2 == "'"${pane_id}"'" {print $11; exit}')"; \
            pane_cmd="${pane_cmd#-}"; }
    fi

    #go to the beginning of the current line
    if [ "${shell_mode}" = "vi" ]; then
        tmux send-keys 'Escape' '0'
    else
        tmux send-keys 'C-a'
    fi
    _sleep_in_remote_shells "${pane_cmd}"

    tmux copy-mode #enter tmux copy mode

    #start tmux selection
    if [ "${copy_mode}" = "vi" ]; then
        tmux send-keys 'Space'
    else
        tmux send-keys 'C-Space'
    fi
    _sleep_in_remote_shells "${pane_cmd}"

    #go to the end of line in copy mode
    #works when command spans accross multiple lines
    if [ "${copy_mode}" = "vi" ]; then
        #this sequence of keys consistently selects multiple lines
        tmux send-keys '150' #go to the bottom of scrollback buffer by using
        tmux send-keys 'j'   #'down' key. 'vi' mode is faster so we're jumping more lines than emacs.
        tmux send-keys '$'   #end of line (just in case we are already at the last line).
        tmux send-keys 'b'   #beginning of the previous word.
        tmux send-keys 'e'   #end of next word.
    else
        i=1; while [ "${i}" -le "30" ]; do #go to the bottom of scrollback buffer
            tmux send-keys 'C-n'
            i="$(($i + 1))"
        done; unset i
        tmux send-keys 'C-e'
        tmux send-keys 'M-b'
        tmux send-keys 'M-f'
    fi
    _sleep_in_remote_shells "${pane_cmd}"

    #yank to external clipboard
    if [ "${TMUX_VERSION}" -ge "18" ]; then
        tmux send-keys "$(_get_tmux_option_global_helper "${yank_wo_newline_option}" "${yank_wo_newline_default}")"
    else
        tmux send-keys Enter
        clipboard_cmd="$(_clipboard_cmd_helper)"; tmux save-buffer - | tr -d '\n' | ${clipboard_cmd}
    fi

    #go to the end of the current line
    if [ "${shell_mode}" = "vi" ]; then
        tmux send-keys '$' 'a'
    else
        tmux send-keys 'C-e'
    fi

    if [ "$(_get_tmux_option_global_helper "${verbose_mode_option}" "${verbose_mode_default}")" = "y" ]; then
        _display_message_helper 'Line copied to clipboard!'
    fi
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
        #"Error, Tmux version unsupported! Please install Tmux version ${SUPPORTED_TMUX_VERSION} or greater!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
