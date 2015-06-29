#!/bin/sh

[ -z "${1}" ] ||  pgrep -lf -P "${1}" | cut -d' ' -f2-

# vim: set ts=8 sw=4 tw=0 ft=sh :
