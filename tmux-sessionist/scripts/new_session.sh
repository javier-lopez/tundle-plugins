#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/vars.sh"
. "${CURRENT_DIR}/helpers.sh"

session_name="${1}"

_supported_tmux_version_helper || return 0

if [ -z "${session_name}" ]; then
    exit 0
elif tmux has-session  -t "${session_name}" >/dev/null 2>&1; then
    tmux switch-client -t "${session_name}"
    tmux display-message "there is already a session called '${session_name}', switching ..."
else
    case "$(_get_tmux_option_global_helper "${tmux_option_new_dir}" "${default_key_bindings_new_dir}")" in
        y|Y) pane_current_path="$(_get_tmux_pane_current_path_helper)"
             _tmux_new_session_helper "${pane_current_path}" "${session_name}" >/dev/null ;;
          *) TMUX="" tmux new-session -d -s "${session_name}" ;;
    esac
    tmux switch-client -t "${session_name}"
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
