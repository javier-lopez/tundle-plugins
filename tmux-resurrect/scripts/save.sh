#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/vars.sh"
. "${CURRENT_DIR}/helpers.sh"

_grouped_sessions_format() {
    #TODO 25-06-2015 23:29 >> add ":" to all fields to know which ones are
    #supported and guess the others
    printf "%s%s%s%s"        \
    "#{session_grouped}${d}" \
    "#{session_group}${d}"   \
    "#{session_id}${d}"      \
    "#{session_name}"
}

_pane_format_19() {
    printf "%s%s%s%s%s%s%s%s%s%s%s%s" \
    "pane${d}"                        \
    "#{session_name}${d}"             \
    "#{window_index}${d}"             \
    ":#{window_name}${d}"             \
    "#{window_active}${d}"            \
    ":#{window_flags}${d}"            \
    "#{pane_index}${d}"               \
    ":#{pane_current_path}${d}"       \
    "#{pane_active}${d}"              \
    "#{pane_current_command}${d}"     \
    "#{pane_pid}${d}"                 \
    "#{history_size}"
}

_pane_format_16() {
    printf "%s%s%s%s%s%s%s%s%s%s%s%s" \
    "pane${d}"                        \
    "#{session_name}${d}"             \
    "#{window_index}${d}"             \
    ":#{window_name}${d}"             \
    "#{window_active}${d}"            \
    ":#{window_flags}${d}"            \
    "#{pane_index}${d}"               \
    "#{pane_active}${d}"              \
    "#{pane_pid}${d}"                 \
    "#{history_size}"
}

_window_format() {
    printf "%s%s%s%s%s%s"  \
    "window${d}"           \
    "#{session_name}${d}"  \
    "#{window_index}${d}"  \
    "#{window_active}${d}" \
    ":#{window_flags}${d}" \
    "#{window_layout}"
}

_dump_panes_raw() {
    _dump_panes_raw_error()
    {
        _display_message_helper \
        "Your OS is not supported on tmux 1.6, please either upgrade to at least 1.9 or report a bug in tundle-plugins/tmux-resurrect"
        exit 1
    }
    if [ "${TMUX_VERSION}" -ge "19" ]; then
        tmux list-panes -a -F "$(_pane_format_19)"
    else #tmux => 1.6
        #may be incorrect in some corner cases but was fine in my tests
        tmux list-panes -a -F "$(_pane_format_16)" | while IFS="${d}" read           \
        _dpraw__type _dpraw__session_name _dpraw__window_index _dpraw__window_name   \
        _dpraw__window_active _dpraw__window_flags _dpraw__pane_index                \
        _dpraw__pane_active _dpraw__pane_pid _dpraw__history_size; do

        case "$(uname)" in
            Linux|Darwin)
                _dpraw__pane_current_path="$(lsof -p "${_dpraw__pane_pid}"|awk '/cwd/ {print $9; exit}')"
                _dpraw__pane_current_cmd="$(ps -eo "ppid command"|awk '$1 == "'"${_dpraw__pane_pid}"'" {print $2; exit}')"
                [ -z "${_dpraw__pane_current_cmd}" ] && { \
                _dpraw__pane_current_cmd="$(ps aux|awk '$2 == "'"${_dpraw__pane_pid}"'" {print $11; exit}')"; \
                _dpraw__pane_current_cmd="${_dpraw__pane_current_cmd#-}"; }

                [ -z "${_dpraw__pane_current_path}" ] && [ -z "${_dpraw__pane_current_cmd}" ] && _dump_panes_raw_error

                #freebsd
                #fstat -p $process | awk '/?/'
                ;;
            *)  _dump_panes_raw_error
                ;;
        esac

        printf "%b%b%b%b%b%b%b%b%b%b%b%b\\n" \
        "${_dpraw__type}${d}"                \
        "${_dpraw__session_name}${d}"        \
        "${_dpraw__window_index}${d}"        \
        "${_dpraw__window_name}${d}"         \
        "${_dpraw__window_active}${d}"       \
        "${_dpraw__window_flags}${d}"        \
        "${_dpraw__pane_index}${d}"          \
        ":${_dpraw__pane_current_path}${d}"  \
        "${_dpraw__pane_active}${d}"         \
        "${_dpraw__pane_current_cmd}${d}"    \
        "${_dpraw__pane_pid}${d}"            \
        "${_dpraw__history_size}"
        done
    fi
}

_dump_windows_raw(){
    tmux list-windows -a -F "$(_window_format)"
}

_toggle_window_zoom() {
    tmux resize-pane -Z -t "${1}"
}

_save_command_strategy_file() {
    _scsfile__strategy="$(_get_tmux_option_global_helper "${save_command_strategy_option}" "${default_save_command_strategy}")"
    _scsfile__strategy_definition="${CURRENT_DIR}/../save_command_strategies/${_scsfile__strategy}.sh"
    _scsfile__default_strategy_definition="${CURRENT_DIR}/../save_command_strategies/${default_save_command_strategy}.sh"
    if [ -e "${_scsfile__strategy_definition}" ]; then # strategy file exists?
        printf "%s\\n" "${_scsfile__strategy_definition}"
    else
        printf "%s\\n" "${_scsfile__default_strategy_definition}"
    fi
}

_pane_full_command() {
    "$(_save_command_strategy_file)" "${1}"
}

_capture_pane_contents() {
    _cpcontents__start_line="-${2}"
    if [ "${3}" = "visible" ]; then
        _cpcontents__start_line="0"
    fi
    #-epJ aren supported on tmux >= 1.8
    #-e: the output includes escape sequences for text and background attributes, what does tmux 1.6 do by default?
    #-p: output goes to stdout, in tmux 1.6 output could be written to a new buffer and the buffer saved to file
    #    save-buffer [-a] [-b buffer-index] path
    #-J: joins wrapped lines and preserves trailing spaces at each line's end, what does tmux 1.6 do by default?
    tmux capture-pane -epJ -S "${_cpcontents__start_line}" -t "${1}" > "$(_resurrect_pane_file_helper "${1}")"
}

_save_shell_history() {
    # $1 => pane_id
    # $2 => pane_command
    # $3 => full_command
    if [ "${2}" = "bash" ] && [ "${3}" = ":" ]; then
        # leading space prevents the command from being saved to history
        # (assuming default HISTCONTROL settings)
        _sshistory__write_command=" history -w '$(_resurrect_history_file_helper "${1}")'"
        # C-e C-u is a Bash shortcut sequence to clear whole line. It is necessary to
        # delete any pending input so it does not interfere with our history command.
        tmux send-keys -t "${1}" C-e C-u "${_sshistory__write_command}" C-m
    fi
}

_get_active_window_index() {
    tmux list-windows -t "${1}" -F "#{window_flags} #{window_index}" | \
    awk '$1 ~ /\*/ { print $2; }'
}

_get_alternate_window_index() {
    tmux list-windows -t "${1}" -F "#{window_flags} #{window_index}" | \
    awk '$1 ~ /-/ { print $2; }'
}

_dump_grouped_sessions() {
    tmux list-sessions -F "$(_grouped_sessions_format)" | \
    grep "^1" | cut -c 3- | sort | \
    while IFS="${d}" read _dgsessions__group _dgsessions__id _dgsessions__name; do
        if [ "${_dgsessions__group}" != "${_dgsessions__current_group}" ]; then
            # this session is the original/first session in the group
            _dgsessions__original="${_dgsessions__name}"
            _dgsessions__current_group="${_dgsessions__group}"
        else
            # this session "points" to the original session
            _dgsessions__active_window_index="$(_get_active_window_index "${_dgsessions__name}")"
            _dgsessions__alternate_window_index="$(_get_alternate_window_index "${_dgsessions__name}")"
            printf "%s%s%s%s%s\\n"                        \
            "grouped_session${d}"                         \
            "${_dgsessions__name}${d}"                    \
            "${_dgsessions__original}${d}"                \
            ":${_dgsessions__alternate_window_index}${d}" \
            ":${_dgsessions__active_window_index}"
        fi
    done
}

_fetch_and_dump_grouped_sessions(){
    _fadgsessions__sessions="$(_dump_grouped_sessions)"
    _get_grouped_sessions_helper "${_fadgsessions__sessions}"
    [ -n "${_fadgsessions__sessions}" ] && printf "%s\\n" "${_fadgsessions__sessions}"
}

# translates pane pid to process command running inside a pane
_dump_panes() {
    _dump_panes_raw | while IFS="${d}" read _dpanes__type _dpanes__session_name \
    _dpanes__window_number _dpanes__window_name _dpanes__window_active        \
    _dpanes__window_flags _dpanes__pane_index _dpanes__dir _dpanes__active    \
    _dpanes__command _dpanes__id _dpanes__history_size; do
        # not saving panes from grouped sessions
        if _is_session_grouped_helper "${_dpanes__session_name}"; then
            continue
        fi
        _dpanes__full_command="$(_pane_full_command "${_dpanes__id}")"

        printf "%s%s%s%s%s%s%s%s%s%s%s\\n" \
        "${_dpanes__type}${d}"             \
        "${_dpanes__session_name}${d}"     \
        "${_dpanes__window_number}${d}"    \
        "${_dpanes__window_name}${d}"      \
        "${_dpanes__window_active}${d}"    \
        "${_dpanes__window_flags}${d}"     \
        "${_dpanes__pane_index}${d}"       \
        "${_dpanes__dir}${d}"              \
        "${_dpanes__active}${d}"           \
        "${_dpanes__command}${d}"          \
        ":${_dpanes__full_command}"
    done
}

_dump_windows() {
    _dump_windows_raw | while IFS="$d" read _dwindows__type _dwindows__session_name \
    _dwindows__window_index  _dwindows__window_active _dwindows__window_flags       \
    _dwindows__window_layout; do
        # not saving windows from grouped sessions
        if _is_session_grouped_helper "${_dwindows__session_name}"; then
            continue
        fi
        # window_layout is not correct for zoomed windows
        case "${_dwindows__window_flags}" in
            *Z*) # unmaximize the window
                _toggle_window_zoom "${_dwindows__session_name}:${_dwindows__window_index}"
                # get correct window layout
                # TODO 26-06-2015 12:19 >> tmux 1.6 doesn't have -F in display-message
                _dwindows__window_layout="$(tmux display-message -p -t "${_dwindows__session_name}:${_dwindows__window_index}" -F "#{window_layout}")"
                # maximize window again
                _toggle_window_zoom "${_dwindows__session_name}:${_dwindows__window_index}"
            ;;
        esac
        printf "%s%s%s%s%s%s\\n"          \
        "${_dwindows__type}${d}"          \
        "${_dwindows__session_name}${d}"  \
        "${_dwindows__window_index}${d}"  \
        "${_dwindows__window_active}${d}" \
        "${_dwindows__window_flags}${d}"  \
        "${_dwindows__window_layout}"
    done
}

_dump_state() {
    if [ "${TMUX_VERSION}" -ge "18" ]; then
        #only available on tmux >= 1.8
        tmux display-message -p "state${d}#{client_session}${d}#{client_last_session}"
    else #tmux => 1.6
        #may be incorrect in some corner cases but it was all fine on my tests
        tmux display-message -p "state${d}#S${d}#S"
    fi
}

_dump_pane_contents() {
    _dpcontents__area="$(_get_tmux_option_global_helper "${pane_contents_area_option}" "${default_pane_contents_area}")"

    _dump_panes_raw | while IFS="$d" read _dpcontents__type _dpcontents__session_name \
    _dpcontents__window_number _dpcontents__window_name _dpcontents__window_active    \
    _dpcontents__window_flags _dpcontents__pane_index _dpcontents__dir                \
    _dpcontents__pane_active _dpcontents__pane_command _dpcontents__pane_pid          \
    _dpcontents__history_size; do
        _capture_pane_contents "${_dpcontents__session_name}:${_dpcontents__window_number}.${_dpcontents__pane_index}" "${_dpcontents__history_size}" "${_dpcontents__area}"
    done
}

_dump_bash_history() {
    _dump_panes | while IFS="$d" read _dbhistory__type _dbhistory__session_name \
    _dbhistory__window_number _dbhistory__window_name _dbhistory__window_active \
    _dbhistory__window_flags _dbhistory__pane_index _dbhistory__dir             \
    _dbhistory__pane_active _dbhistory__pane_command _dbhistory__full_command; do
        _save_shell_history "${_dbhistory__session_name}:${_dbhistory__window_number}.${_dbhistory__pane_index}" "${_dbhistory__pane_command}" "${_dbhistory__full_command}"
    done
}

if _supported_tmux_version_helper; then
    # if "quiet" script produces no output
    if [ "${1}" != "quiet" ]; then
        _start_spinner_helper "Saving..." "Tmux environment saved!"
    fi

    resurrect_file_path="$(_resurrect_file_path_helper)"
    _mkdir_p_helper "$(_resurrect_dir_helper)"
    _fetch_and_dump_grouped_sessions > "${resurrect_file_path}"
    _dump_panes   >> "${resurrect_file_path}"
    _dump_windows >> "${resurrect_file_path}"
    _dump_state   >> "${resurrect_file_path}"

    #point to last session file
    ln -fs "$(_basename_helper "${resurrect_file_path}")" "$(_last_resurrect_file_helper)"

    if _capture_pane_contents_option_on_helper; then
        _dump_pane_contents
    fi

    if _save_bash_history_option_on_helper; then
        _dump_bash_history
    fi

    if [ "${1}" != "quiet" ]; then
        _stop_spinner_helper
        _display_message_helper "Tmux environment saved!"
    fi
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
