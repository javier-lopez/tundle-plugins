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

_get_user_defined_search_engines_bindings() {
    _gudsebindings__vars="$(tmux show-environment -g | awk -F"=" '/^'"@open[-_]"'/ {print $1}')"
    [ -z "${_gudsebindings__vars}" ] && _gudsebindings__vars="$(tmux show-options -g | awk '/^'"@open[-_]"'/ {print $1}')"
    printf "%s" "${_gudsebindings__vars}"
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

_display_deps_error_helper() {
    printf '%s\n' "tmux display-message 'Error! tmux-open dependencies (open|xdg-open) not installed!'"
}

_get_default_open_cmd_helper() {
    case "$(uname)" in
        Darwin) printf "%s" "open"     ;;
         Linux) printf "%s" "xdg-open" ;;
       CYGWIN*) printf "%s" "cygstart" ;;
    esac
}

_get_default_editor_cmd_helper() {
    if [ "${EDITOR}" ]; then
        printf "%s" "${EDITOR}"
    else
        if command -v "vim" >/dev/null; then
            printf "vim"
        else
            printf "vi"
        fi
    fi
}

# vim: set ts=8 sw=4 tw=0 ft=sh :
