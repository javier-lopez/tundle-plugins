#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/scripts/vars.sh"
. "${CURRENT_DIR}/scripts/helpers.sh"

save_command_hook="#(${CURRENT_DIR}/scripts/continuum_save.sh)"

_current_tmux_server_pid() {
    #input: /tmp/tmux-1000/default,20993,0
    #output: 20993
    _ctspid__tmux="${TMUX%,*}"
    printf "%s" "${_ctspid__tmux#*,}"
}

_number_tmux_processes_except_current() {
    #ignores `tmux source-file .tmux.conf` commands used to reload tmux.conf
    ps -Ao "command pid" | awk '/^tmux/ {if ($0 != "^tmux source") print}' | \
        awk '!/'"$(_current_tmux_server_pid)"'/ {total=total+1}; END {print total}'
}

_another_tmux_server_running() {
    if [ "$(tmux list-sessions | awk 'END {print NR}')" = "0" ]; then
        [ "$(_number_tmux_processes_except_current)" -gt "1" ]
    else
        #script loaded after tmux server start can have multiple clients attached
        [ "$(_number_tmux_processes_except_current)" -gt "$(tmux list-clients | awk 'END {print NR}')" ]
    fi
}

_continuum_restore() {
    #auto restore only if this is the only tmux server and the user has manually enabled this plugin
    #if another tmux server exists, it is assumed auto-restore is not wanted
    if [ "$(_get_tmux_option_global_helper "${continuum_restore_option}" "${continuum_restore_default}")" = "on" ]; then
        if [ ! -f "${continuum_restore_halt_file}" ] && [ "$(_number_tmux_processes_except_current)" = "1" ]; then
            #give tmux some time to start and source all the plugins
            #required for getting resurrect_restore_path_option set by the resurrect plugin
            #this can also be accomplished using the TMUX_PLUGIN_MANAGER_PATH variable without sleeping
            sleep 1
            _crestore__resurrect_script="$(_get_tmux_option_global_helper "${resurrect_restore_path_option}")"
            [ -n "${_crestore__resurrect_script}" ] && "${_crestore__resurrect_script}"
        fi
    fi
}

if _supported_tmux_version_helper; then
    #enable/disable tmux autostart per platform
    platform="$(uname)"
    if [ "$(_get_tmux_option_global_helper "${continuum_boot_option}" "${continuum_boot_default}")" = "on" ]; then
        case "${platform}" in
            Darwin) "${CURRENT_DIR}/platform/osx_enable.sh" ;;
        esac
    else
        case "${platform}" in
            Darwin) "${CURRENT_DIR}/platform/osx_disable.sh" ;;
        esac
    fi

    #start auto-saving only if this is the only tmux server
    #we don't want saved files from more environments to overwrite each other
    if ! _another_tmux_server_running; then
        #give user a chance to restore previously saved session
        if [ -z "$(_get_tmux_option_global_helper "${last_auto_save_option}")" ]; then
            tmux set-environment -g "${last_auto_save_option}" "$(date +%s)"
        fi

        status_right_value="$(_get_tmux_option_helper "status-right")"
        #check if hook hasn't been added
        case "${status_right_value}" in
            *"${save_command_hook}"*) : ;;
            *) tmux set-option -g "status-right" "${save_command_hook}${status_right_value}" ;;
        esac
    fi

    #just after starting tmux with the default behavour the number of sessions is 0
    #in that case asume we want to restore the previous session.
    #if [ "$(tmux list-sessions | awk 'END {print NR}')" = "0" ]; then

    #sadly this behavor isn't consistent between tmux versions, so I'm gonna use
    #a global variable and will restore only on the first invocation
    continuum_counter="$(_get_tmux_option_global_helper "${continuum_counter_option}" "0")"
    if [ "${continuum_counter}" = "0" ]; then
        _continuum_restore &
        tmux set-environment -g "${continuum_counter_option}" "1"
    fi
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
        #"Error, Tmux version unsupported! Please install Tmux version ${SUPPORTED_TMUX_VERSION} or greater!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
