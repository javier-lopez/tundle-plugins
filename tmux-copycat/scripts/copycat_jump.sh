#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/vars.sh"
. "${CURRENT_DIR}/helpers.sh"

#'next' or 'prev'
NEXT_PREV="${1}"

#'vi' or 'emacs'
TMUX_COPY_MODE="$(tmux show-option -gw | awk "/^mode-keys/ {gsub(/\'/,\"\");gsub(/\"/,\"\"); print \$2; exit;}")"

_number_of_lines_in_file() {
    [ -f "${1}" ] || return 1
    awk '{i++} END {print i}' "${1}"
}

_get_line() {
    [ -f "${1}" ] || return 1
    [ "${2}" ]    || return 1
    awk 'NR == '"${2}"'' "${1}"
}

_jump_to_line() {
    [ -z "${1}" ] && return 0
    [ "${1}" -eq "0" ] && return 0

    #first jumps to the "bottom" in copy mode so that jumps are consistent
    if [ "${TMUX_COPY_MODE}" = "vi" ]; then
        tmux send-keys G 0 :
    else
        tmux send-keys "M->" C-a g
    fi
    tmux send-keys "0" C-m

    #go to line
    if [ "${TMUX_COPY_MODE}" = "vi" ]; then
        tmux send-keys "${1}" k 0
    else
        c=1; while [ "${c}" -le "${1}" ]; do
            tmux send-keys C-p
            c="$(($c + 1))"
        done; unset c
        tmux send-keys C-a
    fi
}

_jump_to_char() {
    [ -z "${1}" ] && return 0
    [ "${1}" -eq "0" ] && return 0

    if [ "${TMUX_COPY_MODE}" = "vi" ]; then
        tmux send-keys "${1}" l
    else
        #emacs doesn't have repeat, so we're manually looping :(
        c=1; while [ "${c}" -le "${1}" ]; do
            tmux send-keys C-f
            c="$(($c + 1))"
        done; unset c
    fi
}

_select() {
    _select__length="${#1}"
    if [ "${TMUX_COPY_MODE}" = "vi" ]; then
        tmux send-keys Space "${_select__length}" l h
    else
        tmux send-keys C-Space
        c=1; while [ "${c}" -le "${_select__length}" ]; do
            tmux send-keys C-f
            c="$(($c + 1))"
        done; unset c
        #NO selection correction for emacs mode
    fi
}

_get_next_search_position() {
    #$1 => copycat results file
    #$2 => current search position
    if [ "${NEXT_PREV}" = "next" ]; then
        _gnpnumber__total_results="$(_number_of_lines_in_file "${1}")"
        if [ "${2}" -eq "${_gnpnumber__total_results}" ]; then
            #position can't go beyond the last result
            _gnpnumber__new_position="${2}"
        else
            _gnpnumber__new_position="$(($2 + 1))"
        fi
    elif [ "${NEXT_PREV}" = "prev" ]; then
        if [ "${2}" -eq "1" ]; then
            #position can't go below 1
            _gnpnumber__new_position="1"
        else
            _gnpnumber__new_position="$(($2 - 1))"
        fi
    fi

    printf "%s" "${_gnpnumber__new_position}"
}

_jump() {
    [ -z "${2}" ] && return 1
    _jump__search_file="${1}"
    _jump__search_position="${2}"

    _jump__result_line="$(_get_line "${_jump__search_file}" "${_jump__search_position}")" #xnumber:ynumber:string
    _jump__x="${_jump__result_line%%:*}" #get first number in xnumber:ynumber:string
    _jump__x="$((_jump__x - 1))" #tmux starts counting at 0

    _jump__string="${_jump__result_line#*:}"
    _jump__string="${_jump__string#*:}" #get string in xnumber:ynumber:string

    _jump__y="${_jump__result_line#*:}"
    _jump__y="${_jump__y%%:*}" #get second number in xnumber:ynumber:string
    _jump__y="$((_jump__y - 1))"

    #enter copy mode
    tmux copy-mode

    #clears selection from a previous match
    if [ "${TMUX_COPY_MODE}" = "vi" ]; then
        tmux send-keys Escape
    else
        tmux send-keys C-g
    fi

    _jump_to_line "${_jump__x}"
    _jump_to_char "${_jump__y}"
    _select "${_jump__string}"
}

_notify_first_last_match() {
    _nflmatch__msg_duration="1500"
    #if position didn't change, we are either on a 'first' or 'last' match
    if [ "${1}" -eq "${2}" ]; then
        if [ "${NEXT_PREV}" = "next" ]; then
            _display_message_helper "Last match!"  "${_nflmatch__msg_duration}"
        elif [ "${NEXT_PREV}" = "prev" ]; then
            _display_message_helper "First match!" "${_nflmatch__msg_duration}"
        fi
    fi
}

if _in_copycat_mode_helper; then
    copycat_fname="$(_get_copycat_filename_helper)"
    current_search_position="$(_get_tmux_option_global_helper "@copycat_position_$(_pane_unique_id_helper)" "0")"
    next_search_position="$(_get_next_search_position "${copycat_fname}" "${current_search_position}")"

    #export PS4=">> "; set -x #help debugging
    _jump "${copycat_fname}" "${next_search_position}"
    #set +x
    _notify_first_last_match "${current_search_position}" "${next_search_position}"

    tmux set-environment -g "@copycat_position_$(_pane_unique_id_helper)" "${next_search_position}"
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
