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
            #by name, #{client_session} is where the client is: asked for the current session without
            #naming one, tmux 2.2 to 3.0 answer with the session of the last key press, the one to kill
            old_session_name="$(tmux display-message -p -F '#{session_name}' -t "${old_session_id}")"
            current_session_name="$(tmux display-message -p -F '#{client_session}')"
        else
            old_session_name="${old_session_id}"
            current_session_name="$(tmux list-sessions | awk '/attached/ {sub(/:/,""); print $1}')"
        fi

        if [ X"${old_session_name}" = X"${current_session_name}" ]; then
            #there is no alternative session or it's the same as the current session
            tmux switch-client -n
        fi
    fi

    tmux kill-session -t "${old_session_id}"
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
