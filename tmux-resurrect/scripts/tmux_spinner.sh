#!/bin/sh

# This script shows tmux spinner with a message. It is intended to be running
# as a background process which should be `kill`ed at the end.
#
# Example usage:
#
#   ./tmux_spinner.sh "Working..." "End message!" &
#   SPINNER_PID=$!
#   ..
#   .. execute commands here
#   ..
#   kill $SPINNER_PID # Stops spinner and displays 'End message!'

MESSAGE="${1}"
END_MESSAGE="${2}"
SPIN='-\|/'

trap "tmux display-message '${END_MESSAGE}'; exit" 2 15 #SIGINT SIGTERM

i=0; while : ; do
        case "${i}" in
            0) tmux display-message " - ${MESSAGE}" ;;
            1) tmux display-message " \ ${MESSAGE}" ;;
            2) tmux display-message " | ${MESSAGE}" ;;
            3) tmux display-message " / ${MESSAGE}" ;;
        esac
    i="$(( (i+1) % 4 ))"
    sleep 0.1
done; unset i

# vim: set ts=8 sw=4 tw=0 ft=sh :
