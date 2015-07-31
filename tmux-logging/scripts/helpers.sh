#!/bin/sh

_get_digits_from_string_helper() {
    [ -n "${1}" ] &&  printf "%s\\n" "${1}" | tr -dC '0123456789'
}

_get_tmux_option_helper() {
    [ -z "${1}" ] && return 1

    if [ "${TMUX_VERSION-16}" -ge "18" ]; then
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

    #restores original 'display-time' value
    tmux set-option -g display-time "${_dmhelper__saved_time}" >/dev/null
}

_get_fname_helper() {
    case "${1}" in
        @logging|@screen-capture|@save-complete-history)
            _gfhelper__dir="$(_get_tmux_option_global_helper   "${1}-path" "${HOME}")"
            _gfhelper__fname="$(_get_tmux_option_global_helper "${1}-filename")"
            if [ -z "${_gfhelper__fname}" ]; then
                case "${1}" in
                    @logging*) _gfhelper__fname="tmux" ;;
                     @screen*) _gfhelper__fname="tmux-screen"  ;;
                       @save*) _gfhelper__fname="tmux-history" ;;
                esac
                _gfhelper__fname="${_gfhelper__fname}-$(_pane_unique_id_helper)-$(date "+%Y%m%dT%H%M%S")"
            fi
            ;;
        *) return 1 ;;
    esac

    printf "%s" "${_gfhelper__dir}/${_gfhelper__fname}"
}

_pane_unique_id_helper() {
    if [ "${TMUX_VERSION-16}" -ge "18" ]; then
        #sed removes `$` sign because `session_id` contains it
        tmux display-message -p "#{session_id}-#{window_index}-#{pane_index}" | sed 's/\$//'
    else
        _puid__session_id="$(tmux list-sessions | awk '/attached/ {sub(/:/,""); print $1}')"
        _puid__window_id="$(tmux list-windows   | awk '/active/   {sub(/:/,""); print $1}')"
        _puid__pane_id="$(tmux list-panes       | awk '/active/   {sub(/:/,""); print $1}')"
        printf "%s" "${_puid__session_id}-${_puid__window_id}-${_puid__pane_id}"
    fi
}

# vim: set ts=8 sw=4 tw=0 ft=sh :
