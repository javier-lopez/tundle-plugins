#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/scripts/vars.sh"
. "${CURRENT_DIR}/scripts/helpers.sh"

if _supported_tmux_version_helper; then
    toggle_logging_key="$(_get_tmux_option_global_helper "${logging_key_option}" "${default_logging_key}")"
    tmux bind-key "${toggle_logging_key}" run-shell "${CURRENT_DIR}/scripts/toggle_logging.sh"

    pane_capture_key="$(_get_tmux_option_global_helper "${pane_screen_capture_key_option}" "${default_pane_screen_capture_key}")"
    tmux bind-key "${pane_capture_key}"   run-shell "${CURRENT_DIR}/scripts/save_screen.sh"

    save_history_key="$(_get_tmux_option_global_helper "${save_complete_history_key_option}" "${default_save_complete_history_key}")"
    tmux bind-key "${save_history_key}"   run-shell "${CURRENT_DIR}/scripts/save_history.sh"

    clear_history_key="$(_get_tmux_option_global_helper "${clear_history_key_option}" "${default_clear_history_key}")"
    tmux bind-key "${clear_history_key}"  run-shell "${CURRENT_DIR}/scripts/clear_history.sh"
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
        #"Error, Tmux version unsupported! Please install Tmux version ${SUPPORTED_TMUX_VERSION} or greater!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
