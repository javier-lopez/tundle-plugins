#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

if [ -z "${1}" ]; then
    #dismiss session list page from view
    tmux send-keys C-c
    exit 0
fi

session_name="$(tmux list-sessions -F "#{session_name}" | grep -i "${1}" 2>/dev/null)"
session_len="$(printf "%s" "${session_name}" | awk 'END {print NR}')"

if [ "${session_len}" -gt "1" ]; then
    tmux send-keys C-c
    tmux run-shell "${CURRENT_DIR}/list_sessions.sh \"${session_name}\""
    "${CURRENT_DIR}/goto_session_prompt.sh"
elif [ "${session_len}" -eq "1" ]; then
    if tmux has-session -t "${session_name}" >/dev/null 2>&1; then
        tmux send-keys C-c
        tmux switch-client -t "${session_name}"
    else
        tmux send-keys C-c
        tmux run-shell "${CURRENT_DIR}/list_sessions.sh"
        tmux run-shell 'printf " \\n"'
        tmux run-shell 'printf "  %s\\n" "\"'"$1"'\" was not found, try again"'
        "${CURRENT_DIR}/goto_session_prompt.sh"
    fi
else
    tmux send-keys C-c
    tmux run-shell "${CURRENT_DIR}/list_sessions.sh"
    tmux run-shell 'printf " \\n"'
    tmux run-shell 'printf "  %s\\n" "\"'"$1"'\" was not found, try again"'
    "${CURRENT_DIR}/goto_session_prompt.sh"
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
