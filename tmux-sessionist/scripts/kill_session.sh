#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/helpers.sh"

case "${1}" in
    y|Y) : ;;
    *)   return 0 ;;
esac

old_session_id="${2}"

if _supported_tmux_version_helper; then
    if [ "$(tmux list-session | awk 'END {print NR}')" -gt "1" ]; then
        #try to switch to the alternative session
        tmux switch-client -l 2>/dev/null

        #check whether we are in a different session
        if [ "${TMUX_VERSION-16}" -ge "18" ]; then
            current_session_id="$(tmux display-message -p -F '#{session_id}')"
        else
            current_session_name="$(tmux list-sessions | awk '/attached/ {sub(/:/,""); print $1}')"
            current_session_id="${current_session_name}"
        fi

        if [ X"${old_session_id}" = X"${current_session_id}" ]; then
            #there is no alternative session or it's the same as the current session
            tmux switch-client -n
        fi
    fi

    tmux kill-session -t "${old_session_id}"
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
