#!/bin/sh

# "vim session strategy"
#
# Restores a vim session from 'Session.vim' file, if it exists.
# If 'Session.vim' does not exist, it falls back to invoking the original
# command (without the `-S` flag).

if [ -f "${2}/Session.vim" ]; then
    printf "%s\\n" "vim -S"
else
    case "${1}" in
        # Session file does not exist, yet the original nvim command contains
        # session flag `-S`. This will cause an error, so we're falling back to
        # starting plain vim.
        *"-S"*) printf "%s\\n" "vim";;
        *)      printf "%s\\n" "${1}" ;;
    esac
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
