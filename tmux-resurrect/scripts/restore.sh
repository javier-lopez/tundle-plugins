#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/vars.sh"
. "${CURRENT_DIR}/helpers.sh"

###############################################################################
# Global variables Used during the restore: if a pane already exists from
# before, it is saved in the array in this variable. Later, process running in
# existing pane is also not restored. That makes the restoration process more
# idempotent.
###############################################################################
EXISTING_PANES_VAR=""
RESTORING_FROM_SCRATCH="false"
RESTORE_PANE_CONTENTS="false"

###############################################################################
########### Auxiliar functions, not general enough for helpers.sh #############
###############################################################################
_restore_pane_processes_enabled() {
    [ "$(_get_tmux_option_global_helper "${restore_processes_option}" "${restore_processes}")" != "false" ]
}

_is_pane_registered_as_existing() {
    # $1 => session_name
    # $2 => window_number
    # $3 => pane_index
    case "${EXISTING_PANES_VAR}" in
        *"${1}:${2}:${3}"*) return 0 ;;
                         *) return 1 ;;
    esac
}

_pane_exists() {
    # $1 => session_name
    # $2 => window_number
    # $3 => pane_index
    tmux list-panes -t "${1}:${2}" -F "#{pane_index}" 2>/dev/null | grep "^${3}$" >/dev/null
}

_restore_all_processes() {
    [ "$(_get_tmux_option_global_helper "${restore_processes_option}" "${restore_processes}")" = ":all:" ]
}

_restore_list() {
    _rlist__user_processes="$(_get_tmux_option_global_helper "${restore_processes_option}" "${restore_processes}")"
    _rlist__default_processes="$(_get_tmux_option_global_helper "${default_proc_list_option}" "${default_proc_list}")"
    if [ -z "${_rlist__user_processes}" ]; then
        # user didn't define any processes
        printf "%s\\n" "${_rlist__default_processes}"
    else
        printf "%s\\n" "${_rlist__default_processes} ${_rlist__user_processes}"
    fi
}

_get_proc_match_element() {
    printf "%s\\n" "${1}" | sed "s/${inline_strategy_token}.*//"
}

_proc_matches_full_command() {
    _pmfcommand__match="${2}"
    case "${_pmfcommand__match}" in
        '~'*) _pmfcommand__match="${_pmfcommand__match#?}" #remove first char
            # makes sure ${_pmfcommand__match} string is somewhere in the command string
            case "${1}" in
                *"${_pmfcommand__match}"*) return 0 ;;
            esac
            ;;
        *) # regex matching the command makes sure process is a "word"
            case "${1}" in
                "${_pmfcommand__match}") return 0 ;;
            esac
            ;;
    esac
    return 1
}

_process_on_the_restore_list() {
    # TODO: make this work without eval
    eval set $(_restore_list)
    for i in "$@"; do
        _potrlist__match="$(_get_proc_match_element "${i}")"
        if _proc_matches_full_command "${1}" "${_potrlist__match}"; then
            return 0
        fi
    done; unset i
    return 1
}

_process_should_be_restored() {
    # $1 => pane_full_command
    # $2 => session_name
    # $3 => window_number
    # $4 => pane_index
    if _is_pane_registered_as_existing "${2}" "${3}" "${4}"; then
        # Scenario where pane existed before restoration, so we're not
        # restoring the proces either.
        return 1
    elif ! _pane_exists "${2}" "${3}" "${4}"; then
        # pane number limit exceeded, pane does not exist
        return 1
    elif _restore_all_processes; then
        return 0
    elif _process_on_the_restore_list "${1}"; then
        return 0
    else
        return 1
    fi
}

_get_command_strategy() {
    _get_tmux_option_global_helper "${restore_process_strategy_option}${1%% *}"
}

_get_strategy_file() {
    printf "%s\\n" "${CURRENT_DIR}/../strategies/${1%% *}_$(_get_command_strategy "${1}").sh"
}

_strategy_exists() {
    [ -e "$(_get_strategy_file "${1}")" ]
}

_get_proc_restore_element() {
    printf "%s\\n" "${1}" | sed "s/.*${inline_strategy_token}//"
}

_get_inline_strategy() {
    # TODO: make this work without eval
    eval set $(_restore_list)
    for i in "$@"; do
        case "${i}" in
            *"${inline_strategy_token}"*)
                _gistrategy__match="$(_get_proc_match_element "${i}")"
                if _proc_matches_full_command "${1}" "${_gistrategy__match}"; then
                    printf "%s\\n" "$(_get_proc_restore_element "${i}")"
                fi
                ;;
        esac
    done; unset i
}

_restore_pane_process() {
    # $1 => pane_full_command
    # $2 => session_name
    # $3 => window_number
    # $4 => pane_index
    # $5 => dir
    if _process_should_be_restored "${1}" "${2}" "${3}" "${4}"; then
        if [ "${TMUX_VERSION}" -ge "19" ]; then
            tmux switch-client -t "${2}:${3}"
        else
            #TODO 29-06-2015 00:07 >> fix this
            #switch-client seems broken in tmux 1.6 and maybe 1.7/1.8
            #this alternative allows to recover single sessions but breaks multiple ones
            tmux select-window -t "${2}:${3}"
        fi
        tmux select-pane   -t "${4}"

        _rpprocess__inline_strategy="$(_get_inline_strategy "${1}")" # might not be defined
        if [ -n "${_rpprocess__inline_strategy}" ]; then
            # inline strategy exists
            # check for additional "expansion" of inline strategy, e.g. `vim` to `vim -S`
            if _strategy_exists "${_rpprocess__inline_strategy}"; then
                _rpprocess__strategy_file="$(_get_strategy_file "${_rpprocess__inline_strategy}")"
                _rpprocess__inline_strategy="$(${_rpprocess__strategy_file} "${1}" "${5}")"
            fi
            tmux send-keys "${_rpprocess__inline_strategy}" "C-m"
        elif _strategy_exists "${1}"; then
            _rpprocess__strategy_file="$(_get_strategy_file "${1}")"
            _rpprocess__strategy_cmd="$(${_rpprocess__strategy_file} "${1}" "${5}")"
            tmux send-keys "${_rpprocess__strategy_cmd}" "C-m"
        else
            # just invoke the command
            tmux send-keys "${1}" "C-m"
        fi
    fi
}

_check_saved_session_exists() {
    if [ ! -f "$(_last_resurrect_file_helper)" ]; then
        _display_message_helper "Tmux resurrect file not found!"
        return 1
    fi
}

_register_existing_pane() {
    # $1 => session_name
    # $2 => window_number
    # $3 => pane_index
    EXISTING_PANES_VAR="${EXISTING_PANES_VAR}${d}${1}:${2}:${3}"
}

_window_exists() {
    # $1 => session_name
    # $2 => window_number
    tmux list-windows -t "${1}" -F "#{window_index}" 2>/dev/null | grep "^${2}$" >/dev/null
}

_pane_creation_command() {
    printf "%s\\n" "cat '$(_resurrect_pane_file_helper "${1}:${2}.${3}")'; exec ${TMUX_DEFAULT_COMMAND})"
}

_new_window() {
    # $1 => session_name
    # $2 => window_number
    # $3 => window_name
    # $4 => dir
    # $5 => pane_index
    if [ "${RESTORE_PANE_CONTENTS}" = "true" ]; then
        _nwindow__pane_creation_command="$(_pane_creation_command "${1}" "${2}" "${5}")"
        tmux new-window -d -t "${1}:${2}" -n "${3}" -c "${4}" "${_nwindow__pane_creation_command}"
    else
        if [ "${TMUX_VERSION}" -ge "19" ]; then
            tmux new-window -d -t "${1}:${2}" -n "${3}" -c "${4}"
        else #tmux => 1.6
            tmux set -g default-path "${4}" >/dev/null 2>&1
            tmux new-window -d -t "${1}:${2}" -n "${3}"
            tmux set -u default-path >/dev/null 2>&1
        fi
    fi
}

_new_session() {
    # $1 => session_name
    # $2 => window_number
    # $3 => window_name
    # $4 => dir
    # $5 => pane_index
    if [ "${RESTORE_PANE_CONTENTS}" = "true" ]; then
        _nsession__pane_creation_command="$(_pane_creation_command "${1}" "${2}" "${5}")"
        TMUX="" tmux -S "${TMUX%%,*}" new-session -d -s "${1}" -n "${3}" -c "${4}" "${_nsession__pane_creation_command}"
    else
        TMUX="" tmux -S "${TMUX%%,*}" new-session -d -s "${1}" -n "${3}" -c "${4}"
    fi
    # change first window number if necessary
    _nsession__created_window_num="$(_get_tmux_option_helper "base-index")"
    if [ "${_nsession__created_window_num}" != "${2}" ]; then
        tmux move-window -s "${1}:${_nsession__created_window_num}" -t "${1}:${2}"
    fi
}

_new_pane() {
    # $1 => session_name
    # $2 => window_number
    # $3 => window_name
    # $4 => dir
    # $5 => pane_index
    if [ "${RESTORE_PANE_CONTENTS}" = "true" ]; then
        _npane__creation_command="$(_pane_creation_command "${1}" "${2}" "${5}")"
        tmux split-window -t "${1}:${2}" -c "${4}" "${_npane__creation_command}"
    else
        if [ "${TMUX_VERSION}" -ge "19" ]; then
            tmux split-window -t "${1}:${2}" -c "${4}"
        else #tmux => 1.6
            tmux set -g default-path "${4}" >/dev/null 2>&1
            tmux split-window -t "${1}:${2}"
            tmux set -u default-path >/dev/null 2>&1
        fi
    fi
    # minimize window so more panes can fit
    tmux resize-pane -t "${1}:${2}" -U "999"
}

_restore_pane() {
    # $1 => pane
    printf "%s\\n" "${1}" | while IFS="$d" read _rpane__type _rpane__session_name        \
    _rpane__window_number _rpane__window_name _rpane__window_active _rpane__window_flags \
    _rpane__index _rpane__dir _rpane__active _rpane__cmd _rpane__full_cmd; do
        _rpane__dir="${_rpane__dir#?}" #remove first char
        _rpane__window_name="${_rpane__window_name#?}" #remove first char
        if _pane_exists "${_rpane__session_name}" "${_rpane__window_number}" "${_rpane__index}"; then
            if [ "${RESTORING_FROM_SCRATCH}" = "true" ]; then
                # overwrite the pane
                # happens only for the first pane if it's the only registered pane for the whole tmux server
                #_rpane__id="$(tmux display-message -p -F "#{pane_id}" -t "${_rpane__session_name}:${_rpane__window_number}")"
                _rpane__id="$(tmux list-panes -F "#{pane_id}" -t "${_rpane__session_name}:${_rpane__window_number}")"
                _new_pane "${_rpane__session_name}" "${_rpane__window_number}" "${_rpane__window_name}" "${_rpane__dir}" "${_rpane__index}"
                tmux kill-pane -t "${_rpane__id}"
            else
                # Pane exists, no need to create it!
                # Pane existence is registered. Later, its process also won't be restored.
                _register_existing_pane "${_rpane__session_name}" "${_rpane__window_number}" "${_rpane__index}"
            fi
        elif _window_exists "${_rpane__session_name}" "${_rpane__window_number}"; then
            _new_pane "${_rpane__session_name}" "${_rpane__window_number}" "${_rpane__window_name}" "${_rpane__dir}" "${_rpane__index}"
        elif tmux has-session -t "${_rpane__session_name}" 2>/dev/null; then
            _new_window "${_rpane__session_name}" "${_rpane__window_number}" "${_rpane__window_name}" "${_rpane__dir}" "${_rpane__index}"
        else
            _new_session "${_rpane__session_name}" "${_rpane__window_number}" "${_rpane__window_name}" "${_rpane__dir}" "${_rpane__index}"
        fi
    done
}

_restore_state() {
    printf "%s\\n" "${1}" | while IFS="${d}" read _rstate__type _rstate__client_session _rstate__client_last_session; do
        tmux switch-client -t "${_rstate__client_last_session}"
        tmux switch-client -t "${_rstate__client_session}"
    done
}

_restore_grouped_session() {
    printf "%s\\n" "${1}" | while IFS="${d}" read _rgsession__type _rgsession__grouped_session \
    _rgsession__original_session _rgsession__alternate_window _rgsession__active_window; do
        TMUX="" tmux -S "${TMUX%%,*}" new-session -d -s "${_rgsession__grouped_session}" \
        -t "${_rgsession__original_session}"
    done
}

_restore_active_and_alternate_windows_for_grouped_sessions() {
    printf "%s\\n" "${1}" | while IFS="${d}" read _raaawfgsessions__type _raaawfgsessions__grouped_session \
    _raaawfgsessions__original_session _raaawfgsessions__alternate_window_index \
    _raaawfgsessions__active_window_index; do
        _raaawfgsessions__alternate_window_index="${_raaawfgsessions__alternate_window_index#?}"
        _raaawfgsessions__active_window_index="${_raaawfgsessions__active_window_index#?}"
        if [ -n "${_raaawfgsessions__alternate_window_index}" ]; then
            if [ "${TMUX_VERSION}" -ge "19" ]; then
                tmux switch-client -t "${_raaawfgsessions__grouped_session}:${_raaawfgsessions__alternate_window_index}"
            else
                #TODO 29-06-2015 00:07 >> fix this
                #switch-client seems broken in tmux 1.6 and maybe 1.7/1.8
                #this alternative allows to recover single sessions but breaks multiple ones
                tmux select-window -t "${_raaawfgsessions__grouped_session}:${_raaawfgsessions__alternate_window_index}"
            fi
        fi
        if [ -n "${_raaawfgsessions__active_window_index}" ]; then
            if [ "${TMUX_VERSION}" -ge "19" ]; then
                tmux switch-client -t "${_raaawfgsessions__grouped_session}:${_raaawfgsessions__active_window_index}"
            else
                #TODO 29-06-2015 00:07 >> fix this
                #switch-client seems broken in tmux 1.6 and maybe 1.7/1.8
                #this alternative allows to recover single sessions but breaks multiple ones
                tmux select-window -t "${_raaawfgsessions__grouped_session}:${_raaawfgsessions__active_window_index}"
            fi
        fi
    done
}

_detect_if_restoring_from_scratch() {
    if _get_tmux_option_global_helper "${overwrite_option}" >/dev/null; then
        return 0
    fi
    #there is only one pane
    if [ "$(tmux list-panes -a | awk 'END {print NR}')" = "1" ]; then
        RESTORING_FROM_SCRATCH="true"
    fi
}

_detect_if_restoring_pane_contents() {
    if _capture_pane_contents_option_on_helper; then
        # cache tmux default command so that we don't have to "ask" server each time
        _dirpcontents_shell="$(_get_tmux_option_global_helper  "default-shell")"
        TMUX_DEFAULT_COMMAND="$(_get_tmux_option_global_helper "default-command" "${_dirpcontents_shell}")"
        export TMUX_DEFAULT_COMMAND
        RESTORE_PANE_CONTENTS="true"
    fi
}

_layout_checksum(){
    #https://github.com/tmux/tmux/blob/1.7/layout-custom.c#L44
    [ -z "${1}" ] && return 1

    _cwltt16__layout="${1}"
    _lchecksum__csum="0"; while [ "${_cwltt16__layout}" ]; do
        _lchecksum__int="$(printf "%d" "'$(expr substr "${_cwltt16__layout}" 1 1)")"
        _cwltt16__layout="${_cwltt16__layout#?}"
        _lchecksum__csum1="$(($_lchecksum__csum >> 1))"
        _lchecksum__csum_and_1="$(($_lchecksum__csum & 1))"
        _lchecksum__csum_and_1="$(($_lchecksum__csum_and_1 << 15))"
        _lchecksum__csum="$(($_lchecksum__csum1 + $_lchecksum__csum_and_1))"
        _lchecksum__csum="$(($_lchecksum__csum + $_lchecksum__int))"
    done

    printf '%x\n' "${_lchecksum__csum}"
}

_convert_window_layout_to_tmux_16() {
    [ -z "${1}" ] && return 1

    _cwltt16__layout="${1#*,}" #remove checksum
    _cwltt16__new_layout=""
    _cwltt16__counter="1"

    while [ "${_cwltt16__layout}" ]; do
        #going char by char may be slow, but I don't know how to use multiple
        #IFS values without losing the matching IFS value in the process
        _cwltt16__char="$(expr substr "${_cwltt16__layout}" 1 1)"
        case "${_cwltt16__char}" in
                ',') _cwltt16__counter="$(($_cwltt16__counter + 1))" ;;
            '{'|'[') _cwltt16__counter="1" ;;
        esac

        if [ "${_cwltt16__counter}" -lt "4" ]; then
            _cwltt16__new_layout="${_cwltt16__new_layout}${_cwltt16__char}"
            _cwltt16__layout="${_cwltt16__layout#?}" #remove char
        else
            _cwltt16__layout="${_cwltt16__layout#?}" #remove char
            #and keep removing chars till an special character is found
            while [ "${_cwltt16__layout}" ]; do
                _cwltt16__char="$(expr substr "${_cwltt16__layout}" 1 1)"
                case "${_cwltt16__char}" in
                    ','|'}'|']') _cwltt16__counter="0"; break   ;;
                    *) _cwltt16__layout="${_cwltt16__layout#?}" ;;
                esac
            done
        fi
    done

    #prepend checksum
    printf "%s" "$(_layout_checksum "${_cwltt16__new_layout}"),${_cwltt16__new_layout}"
}

################################################
################ main functions ################
################################################

_restore_all_panes() {
    _detect_if_restoring_from_scratch   # sets a global variable
    _detect_if_restoring_pane_contents  # sets a global variable
    while read _rap__line; do
        case "${_rap__line}" in
            pane*) _restore_pane "${_rap__line}" ;;
        esac
    done < "$(_last_resurrect_file_helper)"
}

_restore_layout_for_each_window() {
    \grep '^window' "$(_last_resurrect_file_helper)" |                \
    while IFS="${d}" read _rlfewindow__type _rlfewindow__session_name \
    _rlfewindow__window_number _rlfewindow__window_active           \
    _rlfewindow__window_flags _rlfewindow__window_layout; do
        if [ "${TMUX_VERSION}" -ge "17" ]; then
            tmux select-layout -t "${_rlfewindow__session_name}:${_rlfewindow__window_number}" \
            "${_rlfewindow__window_layout}" >/dev/null 2>&1
        else #tmux <= 1.6
            _rlfewindow__fields="$(printf "%s" "${_rlfewindow__window_layout}"|awk -F'[,[{]' '{print NF}')"
            _rlfewindow__fields="$(($_rlfewindow__fields - 1))"
            if [ "$(( $_rlfewindow__fields % 3 ))" != "0" ]; then
                _rlfewindow__window_layout="$(_convert_window_layout_to_tmux_16 "${_rlfewindow__window_layout}")"
            fi
            tmux select-layout -t "${_rlfewindow__session_name}:${_rlfewindow__window_number}" \
            "${_rlfewindow__window_layout}" >/dev/null 2>&1
        fi
    done
}

_restore_shell_history() {
    awk 'BEGIN { FS="\t"; OFS="\t" } /^pane/ { print $2, $3, $7, $10; }' "$(_last_resurrect_file_helper)" | \
    while IFS="${d}" read _rshistory__session_name _rshistory__window_number _rshistory__pane_index \
    _rshistory__pane_command; do
        if ! _is_pane_registered_as_existing "${_rshistory__session_name}" "${_rshistory__window_number}" \
        "${_rshistory__pane_index}"; then
            if [ "${pane_command}" = "bash" ]; then
                _rshistory__pane_id="${_rshistory__session_name}:${_rshistory__window_number}.${_rshistory__pane_index}"
                # tmux send-keys has -R option that should reset the terminal.
                # However, appending 'clear' to the command seems to work more reliably.
                _rshistory__read_cmd="history -r '$(_resurrect_history_file_helper "${_rshistory__pane_id}")'; clear"
                tmux send-keys -t "${pane_id}" "${_rshistory__read_cmd}" C-m
            fi
        fi
    done
}

_restore_all_pane_processes() {
    if _restore_pane_processes_enabled; then
        awk 'BEGIN { FS="\t"; OFS="\t" } /^pane/ && $11 !~ "^:$" { print $2, $3, $7, $8, $11; }' \
        "$(_last_resurrect_file_helper)" | while IFS="${d}" read \
        _rapprocesses__session_name _rapprocesses__window_number _rapprocesses__pane_index \
        _rapprocesses__dir _rapprocesses__pane_full_cmd; do
            _rapprocesses__dir="${_rapprocesses__dir#?}" #remove first char
            _rapprocesses__pane_full_cmd="${_rapprocesses__pane_full_cmd#?}"
            _restore_pane_process "${_rapprocesses__pane_full_cmd}" "${_rapprocesses__session_name}" \
            "${_rapprocesses__window_number}" "${_rapprocesses__pane_index}" "${_rapprocesses__dir}"
        done
    fi
}

_restore_active_pane_for_each_window() {
    awk 'BEGIN { FS="\t"; OFS="\t" } /^pane/ && $9 == 1 { print $2, $3, $7; }' "$(_last_resurrect_file_helper)" | \
    while IFS="${d}" read _rapfewindow__session_name _rapfewindow__window_number _rapfewindow__active_pane; do
        if [ "${TMUX_VERSION}" -ge "19" ]; then
            tmux switch-client -t "${_rapfewindow__session_name}:${_rapfewindow__window_number}"
        else
            #TODO 29-06-2015 00:07 >> fix this
            #switch-client seems broken in tmux 1.6 and maybe 1.7/1.8
            #this alternative allows to recover single sessions but breaks multiple ones
            tmux select-window -t "${_rapfewindow__session_name}:${_rapfewindow__window_number}"
        fi
        tmux select-pane   -t "${_rapfewindow__active_pane}"
    done
}

_restore_zoomed_windows() {
    awk 'BEGIN { FS="\t"; OFS="\t" } /^pane/ && $6 ~ /Z/ && $9 == 1 { print $2, $3; }' \
    "$(_last_resurrect_file_helper)" | while IFS="${d}" read _rzwindows__session_name  \
    _rzwindows__window_number; do
        tmux resize-pane -t "${_rzwindows__session_name}:${_rzwindows__window_number}" -Z
    done
}

_restore_grouped_sessions() {
    while read _rgsessions__line; do
        case "${_rgsessions__line}" in
            grouped_session*)
                _restore_grouped_session "${_rgsessions__line}"
                _restore_active_and_alternate_windows_for_grouped_sessions "${_rgsessions__line}"
                ;;
        esac
    done < "$(_last_resurrect_file_helper)"
}

_restore_active_and_alternate_windows() {
    awk 'BEGIN { FS="\t"; OFS="\t" } /^window/ && $5 ~ /[*-]/ { print $2, $4, $3; }' \
    "$(_last_resurrect_file_helper)" | sort -u | while IFS="${d}" read _raaawindows__session_name \
    _raaawindows__active_window _raaawindows__window_number; do

        if [ "${TMUX_VERSION}" -ge "19" ]; then
            tmux switch-client -t "${_raaawindows__session_name}:${_raaawindows__window_number}"
        else
            #TODO 29-06-2015 00:07 >> fix this
            #switch-client seems broken in tmux 1.6 and maybe 1.7/1.8
            #this alternative allows to recover single sessions but breaks multiple ones
            tmux select-window -t "${_raaawindows__session_name}:${_raaawindows__window_number}"
        fi
    done
}

_restore_active_and_alternate_sessions() {
    while read _raaasessions__line; do
        case "${_raaasessions__line}" in
            state*) _restore_state "${_raaasessions__line}" ;;
        esac
    done < "$(_last_resurrect_file_helper)"
}

if _supported_tmux_version_helper && _check_saved_session_exists; then
    _start_spinner_helper "Restoring..." "Tmux restore complete!"
    _restore_all_panes
    _restore_layout_for_each_window
    if _save_bash_history_option_on_helper; then
        _restore_shell_history
    fi
    _restore_all_pane_processes
    # below functions restore exact cursor positions
    _restore_active_pane_for_each_window
    _restore_zoomed_windows
    _restore_grouped_sessions  # also restores active and alt windows for grouped sessions
    _restore_active_and_alternate_windows
    _restore_active_and_alternate_sessions
    _stop_spinner_helper
    _display_message_helper "Tmux restore complete!"
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
