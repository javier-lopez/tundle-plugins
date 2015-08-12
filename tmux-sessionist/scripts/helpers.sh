#!/bin/sh

SUPPORTED_TMUX_VERSION="1.6"

_get_digits_from_string_helper() {
    [ -n "${1}" ] &&  printf "%s\\n" "${1}" | tr -dC '0123456789'
}

_get_tmux_option_helper() {
    [ -z "${1}" ] && return 1

    if [ "${TMUX_VERSION-16}" -ge "18" ]; then
        _gtohelper__value="$(tmux show-option -gqv "${1}")"
    else
        _gtohelper__value="$(tmux show-option -g|awk "/^${1}/ {gsub(/\'/,\"\");gsub(/\"/,\"\"); print \$2; exit;}")"
    fi

    if [ -z "${_gtohelper__value}" ]; then
        [ -z "${2}" ] && return 1 || printf "%s\\n" "${2}"
    else
        printf "%s" "${_gtohelper__value}"
    fi
}

_get_tmux_environment_helper() {
    [ -z "${1}" ] && return 1
    _gtehelper__value="$(tmux show-environment -g|awk "/^${1}=/ {sub(/^${1}=/, \"\");print}")"
    if [ -z "${_gtehelper__value}" ]; then
        [ -z "${2}" ] && return 1 || printf "%s\\n" "${2}"
    else
        printf "%s\\n" "${_gtehelper__value}"
    fi
}

_get_tmux_option_global_helper() {
    [ -z "${1}" ] && return 1
    _gtoghelper__option="$(_get_tmux_environment_helper "${1}")"
    [ -z "${_gtoghelper__option}" ] && \
        _get_tmux_option_helper "${1}" "${2}" || \
        printf "%s" "${_gtoghelper__option}"
}

_supported_tmux_version_helper() {
    _stversion__supported="$(_get_digits_from_string_helper "${SUPPORTED_TMUX_VERSION}")"
    if [ -z "${TMUX_VERSION}" ] || [ -z "$(_get_tmux_environment_helper "TMUX_VERSION")" ]; then
        TMUX_VERSION="$(_get_digits_from_string_helper "$(tmux -V)")"
        export TMUX_VERSION #speed up consecutive calls
        tmux set-environment -g TMUX_VERSION "${TMUX_VERSION}"
    fi

    [ "${TMUX_VERSION}" -lt "${_stversion__supported}" ] && return 1 || return 0
}

_display_message_helper() {
    if [ "${#}" -eq 2 ]; then
        _dmhelper__time="${2}"
    else
        _dmhelper__time="5000"
    fi

    _dmhelper__saved_time="$(_get_tmux_option_helper "display-time" "750")"
    tmux set-option -g display-time "${_dmhelper__time}" >/dev/null
    tmux display-message "${1}"

    # restores original 'display-time' value
    tmux set-option -g display-time "${_dmhelper__saved_time}" >/dev/null
}


_strdiff__helper() {
    [ -z "${1}" ] && return 1
    [ -z "${2}" ] && return 1

    mkfifo "/tmp/${$}".fifo1 && mkfifo "/tmp/${$}".fifo2
    if [ -e "/tmp/${$}".fifo1 ] && [ -e "/tmp/${$}".fifo2 ]; then
        _strdiff__1st_string="$(printf "%s" "${1}" | sed 's: :\n:g')"
        _strdiff__2nd_string="$(printf "%s" "${2}" | sed 's: :\n:g')"
        printf "%s\\n" "${_strdiff__1st_string}" > "/tmp/${$}".fifo1 &
        printf "%s\\n" "${_strdiff__2nd_string}" > "/tmp/${$}".fifo2 &
        _strdiff__diff="$(awk 'NR == FNR { A[$0]=1; next } !A[$0]' "/tmp/${$}".fifo1 "/tmp/${$}".fifo2)"
        rm -rf "/tmp/${$}".fifo1; rm -rf "/tmp/${$}".fifo2
        printf "%s\\n" "${_strdiff__diff}"
    else
        return 1
    fi
}

_get_tmux_pane_current_path_helper() {
    _gtpcphelper__path="$(tmux display-message -p -F '#{pane_current_path}' 2>/dev/null)"

    if [ -z "${_gtpcphelper__path}" ]; then
        case "$(uname)" in
            Linux|Darwin)
                _gtpcphelper__pane_num="$(tmux list-panes | awk '/active/  {print NR; exit}')"
                _gtpcphelper__pane_pid="$(tmux list-panes -F '#{pane_pid}' | awk "NR == ${_gtpcphelper__pane_num}")"
                _gtpcphelper__path="$(lsof -p "${_gtpcphelper__pane_pid}"|awk '/cwd/ {print $9; exit}')"

                #freebsd
                #fstat -p $process | awk '/?/'
                ;;
            *)  _gtpcphelper__path="${HOME}" ;;
        esac
    fi

    printf "%s" "${_gtpcphelper__path}"
}

_tmux_new_session_helper() {
    #$1 => string, path, required
    #$2 => string, name
    [ -z "${1}" ] && return 1 || _tnshelper__path="${1}"
    [ -z "${2}" ] || _tnshelper__name="${2}"

    if [ "${TMUX_VERSION-16}" -ge "19" ]; then
        if [ -z "${2}" ]; then
            _tnshelper__name="$(TMUX="" tmux new-session -d -c "${_tnshelper__path}" -P -F "#{session_name}")"
        else
            TMUX="" tmux new-session -d -s "${_tnshelper__name}" -c "${_tnshelper__path}"
        fi
    elif [ "${TMUX_VERSION-16}" -ge "18" ]; then
        if [ -z "${2}" ]; then
            _tnshelper__name="$(TMUX="" tmux new-session -d -P -F "#{session_name}" \
                "cd \"${_tnshelper__path}\"; exec $(_get_tmux_option_helper default-shell)")"
        else
            TMUX="" tmux new-session -d -s "${_tnshelper__name}" \
                "cd \"${_tnshelper__path}\"; exec $(_get_tmux_option_helper default-shell)"
        fi
    elif [ "${TMUX_VERSION-16}" -ge "16" ]; then
        if [ -z "${2}" ]; then
            _tnshelper__old_sessions="$(tmux list-sessions | awk '{sub(/:/,""); print $1}')"
            TMUX="" tmux new-session -d "cd \"${_tnshelper__path}\"; exec $(_get_tmux_option_helper default-shell)"
            _tnshelper__new_sessions="$(tmux list-sessions | awk '{sub(/:/,""); print $1}')"
            _tnshelper__name="$(_strdiff__helper \
                "${_tnshelper__old_sessions}" "${_tnshelper__new_sessions}" 2>/dev/null)"
        else
            TMUX="" tmux new-session -d -s "${_tnshelper__name}" \
                "cd \"${_tnshelper__path}\"; exec $(_get_tmux_option_helper default-shell)"
        fi
    fi

    printf "%s" "${_tnshelper__name}"
}

# vim: set ts=8 sw=4 tw=0 ft=sh :
