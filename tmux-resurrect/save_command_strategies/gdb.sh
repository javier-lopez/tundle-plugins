#!/bin/sh

if [ -z "${1}" ]; then
    exit 0
else
    gdb -batch --eval \
    "attach ${1}" --eval "call write_history(\"/tmp/bash_history-${1}.txt\")" \
    --eval 'detach' --eval 'q' >/dev/null 2>&1
    \tail -1 "/tmp/bash_history-${1}.txt"
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
