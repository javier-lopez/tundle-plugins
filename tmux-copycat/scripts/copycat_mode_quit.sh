#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/vars.sh"
. "${CURRENT_DIR}/helpers.sh"

if _supported_tmux_version_helper; then
    if _in_copycat_mode_helper; then
        #reset position
        tmux set-environment -g "@copycat_position_$(_pane_unique_id_helper)" "0"
        _unset_copycat_mode_helper
        _decrease_internal_counter_helper
        # removing all bindings only if no panes are in copycat mode
        if _copycat_counter_zero_helper; then
            for key in $(_copycat_quit_copy_mode_keys_helper); do
                tmux unbind-key -n "${key}"
            done
            tmux unbind-key -n "$(_get_tmux_option_global_helper "${tmux_option_next}" "${default_next_key}")"
            tmux unbind-key -n "$(_get_tmux_option_global_helper "${tmux_option_prev}" "${default_prev_key}")"
        fi
    fi
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
    #"Error, tmux version ${TMUX_VERSION} unsupported! Please install tmux version >= ${SUPPORTED_TMUX_VERSION}!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
