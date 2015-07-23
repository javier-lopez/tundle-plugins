#!/bin/sh

#awk vs gawk, https://github.com/tmux-plugins/tmux-copycat/issues/61
AWK_CMD='awk'
if command -v "gawk" > /dev/null 2>&1; then
    AWK_CMD='gawk'
fi

#general helpers
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
    [ -z "${_gtoghelper__option}" ] && _get_tmux_option_helper "${1}" "${2}" || printf "%s" "${_gtoghelper__option}"
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

#copycat mode specific helpers
_get_copycat_search_vars_helper() {
    _gcsvars__vars="$(tmux show-environment -g | awk -F"=" '/^'"${COPYCAT_VAR_PREFIX}_"'/ {print $1}')"
    [ -z "${_gcsvars__vars}" ] && _gcsvars__vars="$(tmux show-options -g | awk '/^'"${COPYCAT_VAR_PREFIX}_"'/ {print $1}')"
    printf "%s" "${_gcsvars__vars}"
}

_unset_copycat_mode_helper() {
    tmux set-environment -g "@copycat_mode_$(_pane_unique_id_helper)" "false"
}

_in_copycat_mode_helper() {
    [ "$(_get_tmux_option_global_helper "@copycat_mode_$(_pane_unique_id_helper)" "false")" = "true" ]
}

_extend_key_helper() {
    #$1 => key
    #$2 => script

    #1. 'key' is sent to tmux. This ensures the default key action is done.
    #2. Script is executed.
    #3. `true` command ensures an exit status 0 is returned to ensures the
    #user never gets an error msg
    tmux bind-key -n "${1}" run-shell "tmux send-keys '${1}'; ${2}; true"
}

_get_copycat_filename_helper() {
    printf "%s" "$(_get_tmp_copycat_dir_helper)/results-$(_pane_unique_id_helper)"
}

_increase_internal_counter_helper() {
    _cichelper__i="$(_get_tmux_option_global_helper "${tmux_option_counter}" "0")"
    _cichelper__i="$(($_cichelper__i + 1))"
    tmux set-environment -g "${tmux_option_counter}" "${_cichelper__i}"
}

_decrease_internal_counter_helper() {
    _cdchelper__i="$(_get_tmux_option_global_helper "${tmux_option_counter}" "0")"
    if [ "${_cdchelper__i}" -gt "0" ]; then
        # decreasing the counter only if it won't go below 0
        _cichelper__i="$(($_cdchelper__i - 1))"
        tmux set-environment -g "${tmux_option_counter}" "${_cichelper__i}"
    fi
}

_copycat_counter_zero_helper() {
    [ "$(_get_tmux_option_global_helper "${tmux_option_counter}" "0")" -eq "0" ]
}

#expected output: 'C-c C-j Enter q'
_copycat_quit_copy_mode_keys_helper() {
    tmux list-keys -t "$(tmux show-option -gw | awk "/^mode-keys/ {gsub(/\'/,\"\");gsub(/\"/,\"\"); print \$2; exit;}")-copy" | \
        $AWK_CMD '/(cancel|copy-selection|copy-pipe)/ {print $4}'
}

_pane_unique_id_helper() {
    if [ "${TMUX_VERSION-16}" -ge "19" ]; then
        # sed removes `$` sign because `session_id` contains it
        tmux display-message -p "#{session_id}-#{window_index}-#{pane_index}" | sed 's/\$//'
    else
        _puid__session_id="$(tmux list-sessions | awk '/attached/ {sub(/:/,""); print $1}')"
        _puid__window_id="$(tmux list-windows | awk '/active/ {sub(/:/,""); print $1}')"
        _puid__pane_id="$(tmux list-panes | awk '/active/ {sub(/:/,""); print $1}')"
        printf "%s" "${_puid__session_id}-${_puid__window_id}-${_puid__pane_id}"
    fi
}

_copycat_mode_var_helper() {
    printf "%s" "@copycat_mode_$(_pane_unique_id_helper)"
}

_get_tmp_copycat_dir_helper() {
    printf "%s" "${TMPDIR:-/tmp}/tmux-$(id -u)-copycat"
}

#copycat integration functions for tmux <= 1.7, without copy-pipe
#these functions are used by external scripts, eg: tmux-yank, tmux-open

#create virtual keybindings, eg: @copycat-mode-key-y => "tmux save-buffer - | ${clipboard_cmd}"
_copycat_mode_add_helper() {
    [ -z "${1}" ] && return 0
    [ -z "${2}" ] && return 0
    case "${2}" in
        msg:*) tmux set-environment -g "@copycat-mode-verbose-before-${1}" "${2##msg:}" ;;
            *) tmux set-environment -g "@copycat-mode-key-${1}" "${2}" ;;
    esac

    [ -z "${3}" ] && return 0
    case "${3}" in
        msg:*) tmux set-environment -g "@copycat-mode-verbose-after-${1}" "${3##msg:}" ;;
            *) tmux set-environment -g "@copycat-mode-key-${1}" "${3}" ;;
    esac
}

#create a gigantic keybinding mixing the virtual keybindings upon copycat_mode start/quit
_copycat_mode_generate_helper() {
    _tcmghelper__keys="$(tmux show-environment -g | awk -F"=" '/^@copycat-mode-key/ {print $1}')"
    _tcmghelper__body=""; _tcmghelper__footer=""

    for _tcmghelper__key in ${_tcmghelper__keys}; do
        _tcmghelper__body="${_tcmghelper__body}"' tmux bind-key -n '"${_tcmghelper__key##@copycat-mode-key-}"' run "tmux send-keys Enter;'

        _tcmghelper__msg_before="$(_get_tmux_environment_helper "@copycat-mode-verbose-before-${_tcmghelper__key##@copycat-mode-key-}")"
        if [ "${_tcmghelper__msg_before}" ]; then
            _tcmghelper__body="${_tcmghelper__body} tmux display-message '${_tcmghelper__msg_before}';"
        fi
        _tcmghelper__body="${_tcmghelper__body} $(_get_tmux_environment_helper "${_tcmghelper__key}");"
        _tcmghelper__body="${_tcmghelper__body} ${tmux_copycat_dir}/scripts/copycat_mode_quit.sh;"
        _tcmghelper__msg_after="$(_get_tmux_environment_helper "@copycat-mode-verbose-after-${_tcmghelper__key##@copycat-mode-key-}")"
        if [ "${_tcmghelper__msg_after}" ]; then
            _tcmghelper__body="${_tcmghelper__body} tmux display-message '${_tcmghelper__msg_after}';"
        fi

        for _tcmghelper__key in ${_tcmghelper__keys}; do
            _tcmghelper__body="${_tcmghelper__body} tmux unbind-key -n ${_tcmghelper__key##@copycat-mode-key-}; "
        done
        _tcmghelper__body="${_tcmghelper__body} "'";'
    done

    for _tcmghelper__quit_key in q C-c; do
        _tcmghelper__footer="${_tcmghelper__footer}"' tmux bind-key -n '" ${_tcmghelper__quit_key}"' run "tmux send-keys '"${_tcmghelper__quit_key};"
        for _tcmghelper__key in ${_tcmghelper__keys}; do
            _tcmghelper__footer="${_tcmghelper__footer} tmux unbind-key -n ${_tcmghelper__key##@copycat-mode-key-}; "
        done
        _tcmghelper__footer="${_tcmghelper__footer} ${tmux_copycat_dir}/scripts/copycat_mode_quit.sh;"'";'
    done

    #don't try this at home
    sh -c "${_tcmghelper__header} ${_tcmghelper__body} ${_tcmghelper__footer}"
}

# vim: set ts=8 sw=4 tw=0 ft=sh :
