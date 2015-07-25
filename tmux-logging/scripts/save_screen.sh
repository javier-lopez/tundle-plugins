#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/vars.sh"
. "${CURRENT_DIR}/helpers.sh"

if _supported_tmux_version_helper; then
    if [ "$(_get_tmux_option_global_helper "${logging_interactive_option}" "${default_logging_interactive}")" = "y" ]; then
        tmux command-prompt -p "Save screen to:" "run-shell \"${CURRENT_DIR}/capture_pane.sh 'Screen' '%1'\""
    else
        "${CURRENT_DIR}/capture_pane.sh" 'Screen'
    fi
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
        #"Error, Tmux version unsupported! Please install Tmux version ${SUPPORTED_TMUX_VERSION} or greater!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
