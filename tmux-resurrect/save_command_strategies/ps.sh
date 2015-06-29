#!/bin/sh

if [ -z "${1}" ]; then
    exit 0
else
    case "$(uname -s)" in
        FreeBSD|OpenBSD) ps_flags="-ao" ;;
                      *) ps_flags="-eo" ;;
    esac
    ps "${ps_flags}" "ppid command" | awk '$1 == "'"${1}"'" {$1=""; gsub(/^[ \t]+|[ \t]+$/, ""); print $0; exit}'
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
