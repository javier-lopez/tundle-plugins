#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/vars.sh"
. "${CURRENT_DIR}/helpers.sh"

if _supported_tmux_version_helper; then
    if [ "$(_get_tmux_option_global_helper "@logging_$(_pane_unique_id_helper)" "not logging")" = "not logging" ]; then
        if [ "$(_get_tmux_option_global_helper "${logging_interactive_option}" "${default_logging_interactive}")" = "y" ]; then
            #command-prompt is weird, doesn't return results on time so it's hard to rely on it
            #may be forking in background internally?
            tmux command-prompt -p "Log to:" "run-shell \"${CURRENT_DIR}/capture_pane.sh 'Log' '%1'\""
        else
            "${CURRENT_DIR}/capture_pane.sh" 'Log'
        fi
    else
        #pipe-pane available in tmux >= 1.0
        tmux pipe-pane #if called without parameters stops piping
        _display_message_helper "Ended logging to $(_get_tmux_option_global_helper "@logging_fname")"
        tmux set-environment -g "@logging_$(_pane_unique_id_helper)" "not logging" > /dev/null
    fi
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
        #"Error, Tmux version unsupported! Please install Tmux version ${SUPPORTED_TMUX_VERSION} or greater!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
