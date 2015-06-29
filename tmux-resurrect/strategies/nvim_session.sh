#!/bin/sh

# "nvim session strategy"
#
# Same as vim strategy, see file 'vim_session.sh'

if [ -f "${2}/Session.vim" ]; then
    printf "%s\\n" "nvim -S"
else
    case "${1}" in
        # Session file does not exist, yet the original nvim command contains
        # session flag `-S`. This will cause an error, so we're falling back to
        # starting plain nvim.
        *"-S"*) printf "%s\\n" "nvim";;
        *)      printf "%s\\n" "${1}" ;;
    esac
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
