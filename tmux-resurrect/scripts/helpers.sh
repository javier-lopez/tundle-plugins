d="$(printf "%b" "\t")"

_basename_helper()
{   #alternative basename portable version, faster! but with possible drawbacks
    [ -z "${1}" ] && return 1 || _bhelper__name="${1}"
    [ -z "${2}" ] || _bhelper__suffix="${2}"
    case "${_bhelper__name}" in
        /*|*/*) _bhelper__name="${_bhelper__name##*/}"
    esac

    if [ -n "${_bhelper__suffix}" ] && [ "${#_bhelper__name}" -gt "${#2}" ]; then
        _bhelper__name="${_bhelper__name%$_bhelper__suffix}"
    fi

    printf "%s" "${_bhelper__name}"
}

_mkdir_p_helper() { #portable mkdir -p
    for _mphelper__dir; do
        _mphelper__IFS="${IFS}"
        IFS="/"
        set -- ${_mphelper__dir}
        IFS="${_mphelper__IFS}"
        (
        case "${_mphelper__dir}" in
            /*) cd /; shift ;;
        esac
        for _mphelper__subdir; do
            [ -z "${_mphelper__subdir}" ] && continue
            if [ -d "${_mphelper__subdir}" ] || mkdir "${_mphelper__subdir}"; then
                if cd "${_mphelper__subdir}"; then
                    :
                else
                    printf "%s\\n" "_mkdir_p_helper: Can't enter ${_mphelper__subdir} while creating ${_mphelper__dir}"
                    exit 1
                fi
            else
                exit 1
            fi
        done
        )
    done
}

_get_digits_from_string_helper() {
    [ -n "${1}" ] &&  printf "%s\\n" "${1}" | tr -dC '0123456789'
}

_get_tmux_option_helper() {
    [ -z "${1}" ] && return 1

    if [ "${TMUX_VERSION-16}" -ge "19" ]; then
        _gtohelper__value="$(tmux show-option -gqv "${1}")"
    else #tmux => 1.6 altough could work on even lower tmux versions
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
    if [ -z "${_gtoghelper__option}" ]; then
        if [ -z "${2}" ]; then
            _get_tmux_option_helper "${1}"
        else
            _get_tmux_option_helper "${1}" "${2}"
        fi
    else
        printf "%s" "${_gtoghelper__option}"
    fi
}

_supported_tmux_version_helper() {
    _stvhelper__supported="$(_get_digits_from_string_helper "${SUPPORTED_TMUX_VERSION}")"
    if [ -z "${TMUX_VERSION}" ] || [ -z "$(_get_tmux_environment_helper "TMUX_VERSION")" ]; then
        TMUX_VERSION="$(_get_digits_from_string_helper "$(tmux -V)")"
        export TMUX_VERSION #speed up consecutive calls
        tmux set-environment -g TMUX_VERSION "${TMUX_VERSION}"
    fi

    [ "${TMUX_VERSION}" -lt "${_stvhelper__supported}" ] && return 1 || return 0
}

# Ensures a message is displayed for 5 seconds in tmux prompt.
# Does not override the 'display-time' tmux option.
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

_capture_pane_contents_option_on_helper() {
    [ "$(_get_tmux_option_global_helper "${pane_contents_option}" "off")" = "on" ]
}

_save_bash_history_option_on_helper() {
    [ "$(_get_tmux_option_global_helper "${bash_history_option}" "off")" = "on" ]
}

_get_grouped_sessions_helper() {
    export GROUPED_SESSIONS="${d}$(printf "%s\\n" "${1}" | cut -f2 -d"$d" | tr "\\n" "$d")"
}

_is_session_grouped_helper() {
    case "${GROUPED_SESSIONS}" in
        *"${d}${1}${d}"*) return 0 ;;
                       *) return 1 ;;
    esac
}

# path helpers

_resurrect_dir_helper() {
    printf "%s\\n" "$(_get_tmux_option_global_helper "${resurrect_dir_option}" "${default_resurrect_dir}")"
}

_resurrect_file_path_helper() {
    _rfphelper__timestamp="$(date +"%Y-%m-%dT%H:%M:%S")"
    printf "%s\\n" "$(_resurrect_dir_helper)/tmux_resurrect_${_rfphelper__timestamp}.txt"
}

_last_resurrect_file_helper() {
    printf "%s\\n" "$(_resurrect_dir_helper)/last"
}

_resurrect_pane_file_helper() {
    printf "%s\\n" "$(_resurrect_dir_helper)/pane_contents-${1}"
}

_resurrect_history_file_helper() {
    printf "%s\\n" "$(_resurrect_dir_helper)/bash_history-${1}"
}

# spinner helpers
_start_spinner_helper() {
    "${CURRENT_DIR}/tmux_spinner.sh" "${1}" "${2}" &
    export SPINNER_PID="${!}"
}

_stop_spinner_helper() {
    kill "${SPINNER_PID}"
}

# vim: set ts=8 sw=4 tw=0 ft=sh :
