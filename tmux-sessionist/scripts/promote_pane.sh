#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/helpers.sh"

current_session_name="$(tmux list-sessions | awk '/attached/ {sub(/:/,""); print $1}')"
current_pane_num="$(tmux list-panes        | awk '/active/   {print NR; exit}')"
current_pane_id="$(tmux  list-panes -t "${current_session_name}" -F '#{pane_id}' | \
    awk "NR == ${current_pane_num}")"
pane_current_path="$(_get_tmux_pane_current_path_helper)"

if _supported_tmux_version_helper; then
    if [ "$(tmux list-panes -s -t "${current_session_name}" | awk 'END {print NR}')" -gt "1" ]; then
        session_name="$(_tmux_new_session_helper  "${pane_current_path}")"
        new_session_pane_id="$(tmux list-panes -t "${session_name}" -F "#{pane_id}")"

        tmux join-pane     -s "${current_pane_id}" -t "${new_session_pane_id}"
        tmux kill-pane     -t "${new_session_pane_id}"
        tmux switch-client -t "${session_name}"
    else
        _display_message_helper "The pane already has its own session, canceling ..."
    fi
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
