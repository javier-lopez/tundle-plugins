#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

#starts a loop: the command is invoked until a correct session name is typed
tmux command -p "session (press Enter to dismiss):" "run \"${CURRENT_DIR}/switch_or_loop.sh '%1'\""

# vim: set ts=8 sw=4 tw=0 ft=sh :
