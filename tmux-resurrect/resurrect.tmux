#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/scripts/vars.sh"
. "${CURRENT_DIR}/scripts/helpers.sh"

_set_default_key_bindings() {
    _sdkbindings__save_key="$(_get_tmux_option_global_helper "${save_option}" "${default_save_key}")"
    tmux bind-key "${_sdkbindings__save_key}" run-shell "${CURRENT_DIR}/scripts/save.sh"
    _sdkbindings__restore_key="$(_get_tmux_option_global_helper "${restore_option}" "${default_restore_key}")"
    tmux bind-key "${_sdkbindings__restore_key}" run-shell "${CURRENT_DIR}/scripts/restore.sh"
}

_set_default_options() {
    tmux set-environment -g "${restore_process_strategy_option}irb" "default_strategy"   >/dev/null
    tmux set-environment -g "${save_path_option}"    "${CURRENT_DIR}/scripts/save.sh"    >/dev/null
    tmux set-environment -g "${restore_path_option}" "${CURRENT_DIR}/scripts/restore.sh" >/dev/null
    if [ "${TMUX_VERSION-16}" -ge "19" ]; then #compatibility layer with tpm/tmux-resurrect
        tmux set-option -g "${save_path_option}"    "${CURRENT_DIR}/scripts/save.sh"    >/dev/null
        tmux set-option -g "${restore_path_option}" "${CURRENT_DIR}/scripts/restore.sh" >/dev/null
    fi
}

if _supported_tmux_version_helper; then
    _set_default_key_bindings
    _set_default_options
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
    #"Error, tmux version ${TMUX_VERSION} unsupported! Please install tmux version >= ${SUPPORTED_TMUX_VERSION}!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
