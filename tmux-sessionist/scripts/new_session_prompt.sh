#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

tmux command -p "new session name:" "run \"${CURRENT_DIR}/new_session.sh '%1'\""

# vim: set ts=8 sw=4 tw=0 ft=sh :
