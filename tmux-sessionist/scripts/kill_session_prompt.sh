#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/helpers.sh"

if _supported_tmux_version_helper; then
    if [ "${TMUX_VERSION-16}" -ge "18" ]; then
        current_session_name="$(tmux display-message -p -F '#{session_name}')"
        current_session_id="$(tmux display-message   -p -F '#{session_id}')"
    else
        current_session_name="$(tmux list-sessions | awk '/attached/ {sub(/:/,""); print $1}')"
        current_session_id="${current_session_name}"
    fi

    tmux command -p 'kill-session "'"${current_session_name}"'" ? (y/n)' \
        "run \"${CURRENT_DIR}/kill_session.sh '%1' '${current_session_id}'\""
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
