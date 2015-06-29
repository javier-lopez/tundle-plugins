#!/bin/sh

# "irb default strategy"
#
# Example irb process with junk variables:
#   irb RBENV_VERSION=1.9.3-p429 GREP_COLOR=34;47 TERM_PROGRAM=Apple_Terminal
#
# When executed, the above will fail. This strategy handles that.

printf "%s\\n" "${1}" | awk '{gsub(/(RBENV_VERSION|GREP_COLOR|TERM_PROGRAM)[^ ]*/,""); print $0; exit}'

# vim: set ts=8 sw=4 tw=0 ft=sh :
