#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

#TMUX messaging is weird
#you only get a nice clean pane if you do it with the `run-shell` command
if [ "${TMUX_VERSION-16}" -ge "32" ]; then
    #run-shell gives its output to the client that ran it unless it's told a pane (tmux 3.2, and again
    #from 3.5 on): that client is this script, and tmux only shows what a script printed when the
    #script is over, which with tmux 3.6 is after the prompt is answered
    tmux run-shell -t "$(tmux display-message -p "#{pane_id}")" "${CURRENT_DIR}/list_sessions.sh"
else
    tmux run-shell "${CURRENT_DIR}/list_sessions.sh"
fi
"${CURRENT_DIR}/goto_session_prompt.sh"

# vim: set ts=8 sw=4 tw=0 ft=sh :
