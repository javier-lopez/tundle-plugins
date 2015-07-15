#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

tmux command-prompt -p "copycat search:" "run-shell \"${CURRENT_DIR}/copycat_mode_start.sh '%1'\""
