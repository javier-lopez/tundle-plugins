#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/vars.sh"
. "${CURRENT_DIR}/helpers.sh"

interval_option_minutes="$(_get_tmux_option_global_helper "${continuum_save_interval_option}" "${continuum_save_interval_default}")"
interval_option_seconds="$(($interval_option_minutes * 60))"

if [ "$(_get_tmux_option_global_helper "${continuum_restore_option}" "${continuum_restore_default}")" = "on" ]; then
    printf "%s\\n" "${interval_option_minutes}"
else
    printf "%s\\n" "off"
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
