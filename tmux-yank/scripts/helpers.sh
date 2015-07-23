#!/bin/sh

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

_get_tmux_copy_mode_keys() {
    _gtcmkeys__enter="$(tmux show-environment -g | awk -F"=" '/^@copy-mode-enter-/ {sub(/@copy-mode-enter-/, ""); print $1}')"
    if [ -z "${_gtcmkeys__enter}" ]; then
        for _gtcmkeys__enter in $(tmux list-keys | awk '/copy-mode$/ {print $2}'); do
            tmux set-environment -g "@copy-mode-enter-${_gtcmkeys__enter}" "1" >/dev/null 2>&1
        done
        _get_tmux_copy_mode_keys
    else
        printf "%s" "${_gtcmkeys__enter}"
    fi
}

_tmux_copy_mode_add_helper() {
    [ -z "${1}" ] && return 0
    [ -z "${2}" ] && return 0
    case "${2}" in
        msg:*) tmux set-environment -g "@copy-mode-verbose-before-${1}" "${2##msg:}" ;;
            *) tmux set-environment -g "@copy-mode-key-${1}" "${2}" ;;
    esac

    [ -z "${3}" ] && return 0
    case "${3}" in
        msg:*) tmux set-environment -g "@copy-mode-verbose-after-${1}" "${3##msg:}" ;;
            *) tmux set-environment -g "@copy-mode-key-${1}" "${3}" ;;
    esac
}

_tmux_copy_mode_generate_helper() {
    _tcmghelper__keys="$(tmux show-environment -g | awk -F"=" '/^@copy-mode-key/ {print $1}')"
    [ -z "${_tcmghelper__keys}" ] && return 0
    _tcmghelper__header=""; _tcmghelper__body=""; _tcmghelper__footer=""

    _tcmghelper__header='tmux bind-key '"${1}"' run "tmux copy-mode;'

    for _tcmghelper__key in ${_tcmghelper__keys}; do
        _tcmghelper__body="${_tcmghelper__body}"' tmux bind-key -n '"${_tcmghelper__key##@copy-mode-key-}"' run \"tmux send-keys Enter;'

        _tcmghelper__msg_before="$(_get_tmux_environment_helper "@copy-mode-verbose-before-${_tcmghelper__key##@copy-mode-key-}")"
        if [ "${_tcmghelper__msg_before}" ]; then
            _tcmghelper__body="${_tcmghelper__body} tmux display-message '${_tcmghelper__msg_before}';"
        fi
        _tcmghelper__body="${_tcmghelper__body} $(_get_tmux_environment_helper "${_tcmghelper__key}");"
        _tcmghelper__msg_after="$(_get_tmux_environment_helper "@copy-mode-verbose-after-${_tcmghelper__key##@copy-mode-key-}")"
        if [ "${_tcmghelper__msg_after}" ]; then
            _tcmghelper__body="${_tcmghelper__body} tmux display-message '${_tcmghelper__msg_after}';"
        fi

        for _tcmghelper__key in ${_tcmghelper__keys}; do
            _tcmghelper__body="${_tcmghelper__body} tmux unbind-key -n ${_tcmghelper__key##@copy-mode-key-}; "
        done
        _tcmghelper__body="${_tcmghelper__body} "'\";'
    done

    for _tcmghelper__quit_key in q C-c; do
        _tcmghelper__footer="${_tcmghelper__footer}"' tmux bind-key -n '" ${_tcmghelper__quit_key}"' run \"tmux send-keys '"${_tcmghelper__quit_key};"
        for _tcmghelper__key in ${_tcmghelper__keys}; do
            _tcmghelper__footer="${_tcmghelper__footer} tmux unbind-key -n ${_tcmghelper__key##@copy-mode-key-}; "
        done
        _tcmghelper__footer="${_tcmghelper__footer}"'\";'
    done
    _tcmghelper__footer="${_tcmghelper__footer}"'"'

    #don't try this at home
    sh -c "${_tcmghelper__header} ${_tcmghelper__body} ${_tcmghelper__footer}"
}

_clipboard_cmd_helper() {
    if command -v "xclip" >/dev/null 2>&1; then
        printf "%s" "xclip -selection $(_get_tmux_option_global_helper "${yank_selection_option}" "${yank_selection_default}")"
    elif command -v "xsel" >/dev/null 2>&1; then
        printf "%s" "xsel -i --$(_get_tmux_option_global_helper "${yank_selection_option}" "${yank_selection_default}")"
    elif command -v "pbcopy" >/dev/null 2>&1; then
        # installing reattach-to-user-namespace is recommended on OS X
        if command -v "reattach-to-user-namespace" >/dev/null 2>&1; then
            printf "%s" "reattach-to-user-namespace pbcopy"
        else
            printf "%s" "pbcopy"
        fi
    else
        return 1
    fi
}

# vim: set ts=8 sw=4 tw=0 ft=sh :
