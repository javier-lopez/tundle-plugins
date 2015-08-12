#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

#TMUX messaging is weird
#you only get a nice clean pane if you do it with the `run-shell` command
tmux run-shell "${CURRENT_DIR}/list_sessions.sh"
"${CURRENT_DIR}/goto_session_prompt.sh"

# vim: set ts=8 sw=4 tw=0 ft=sh :
