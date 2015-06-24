#!/bin/sh

###################################################################################
################################## General utils ##################################
###################################################################################

SUPPORTED_TMUX_VERSION="1.6"

_get_digits_from_string_helper() {
    [ -n "${1}" ] &&  printf "%s\\n" "${1}" | tr -dC '0123456789'
}

_get_tmux_option_helper() {
    [ -z "${1}" ] && return 1

    case "${CURRENT_TMUX_VERSION}" in
        19) _gtohelper__value="$(tmux show-option -gqv "${1}")" ;;
        *)  #tmux => 1.6 && < 1.9, altough could work on even lower tmux versions
            _gtohelper__value="$(tmux show-option -g|awk "/^${1}/ {gsub(/\'/,\"\");gsub(/\"/,\"\"); print \$2; exit;}")" ;;
    esac

    if [ -z "${_gtohelper__value}" ]; then
        [ -z "${2}" ] && return 1 || printf "%s\\n" "${2}"
    else
        printf "%s" "${_gtohelper__value}"
    fi
}

_get_tmux_server_option_helper() {
    [ -z "${1}" ] && return 1

    case "${CURRENT_TMUX_VERSION}" in
        19) _gtsohelper__value="$(tmux show-option -sv "${1}")" ;;
        *)  #tmux => 1.6 && < 1.9, altough could work on even lower tmux versions
            _gtsohelper__value="$(tmux show-option -s|awk "/^${1}/ {print \$2; exit;}")" ;;
    esac

    if [ -z "${_gtsohelper__value}" ]; then
        [ -z "${2}" ] && return 1 || printf "%s\\n" "${2}"
    else
        printf "%s\\n" "${_gtsohelper__value}"
    fi
}

_get_tmux_environment_helper() {
    [ -z "${1}" ] && return 1

    _gtehelper__value="$(tmux show-environment -g|awk -F"=" "/^${1}=/ {print \$2}")"

    if [ -z "${_gtehelper__value}" ]; then
        [ -z "${2}" ] && return 1 || printf "%s\\n" "${2}"
    else
        printf "%s\\n" "${_gtehelper__value}"
    fi
}

_supported_tmux_version() {
    _stversion__supported="$(_get_digits_from_string_helper "${SUPPORTED_TMUX_VERSION}")"
    if [ -z "${CURRENT_TMUX_VERSION}" ] || [ -z "$(_get_tmux_environment_helper "TMUX_VERSION")" ]; then
        CURRENT_TMUX_VERSION="$(_get_digits_from_string_helper "$(tmux -V)")"
        export CURRENT_TMUX_VERSION #speed up consecutive calls
        tmux set-environment -g TMUX_VERSION "${CURRENT_TMUX_VERSION}"
    fi

    [ "${CURRENT_TMUX_VERSION}" -lt "${_stversion__supported}" ] && return 1 || return 0
}

###################################################################################
############################# Plugin specific utils ###############################
###################################################################################

# used to match output from `tmux list-keys`
KEY_BINDING_REGEX="bind-key[[:space:]]\+\(-r[[:space:]]\+\)\?\(-T prefix[[:space:]]\+\)\?"

_is_osx() {
    [ "$(uname)" = "Darwin" ]
}

# returns prefix key, e.g. 'C-a'
_prefix() {
    _get_tmux_option_helper "prefix"
}

# if prefix is 'C-a', this function returns 'a'
_prefix_without_ctrl() {
    _prefix | cut -d '-' -f2
}

_option_value_not_changed() {
    [ "$(_get_tmux_option_helper "${1}")" = "${2}" ]
}

_server_option_value_not_changed() {
    [ "$(_get_tmux_server_option_helper "${1}")" = "${2}" ]
}

_key_binding_not_set() {
    [ -z "${1}" ] && return 1
    if tmux list-keys | grep "${KEY_BINDING_REGEX}${1}[[:space:]]" >/dev/null; then
        return 1
    else
        return 0
    fi
}

_key_binding_not_changed() {
    [ -z "${2}" ] && return 1
    if tmux list-keys | grep "${KEY_BINDING_REGEX}${1}[[:space:]]\+${2}" >/dev/null; then
        # key still has the default binding
        return 0
    else
        return 1
    fi
}

_set_tmux_sensible_settings() {
    # enable utf8
    tmux set-option -g utf8 on

    # enable utf8 in tmux status-left and status-right
    tmux set-option -g status-utf8 on

    # address vim mode switching delay (http://superuser.com/a/252717/65504)
    if _server_option_value_not_changed "escape-time" "500"; then
        tmux set-option -s escape-time 0
    fi

    # increase scrollback buffer size
    if _option_value_not_changed "history-limit" "2000"; then
        tmux set-option -g history-limit 50000
    fi

    # tmux messages are displayed for 4 seconds
    if _option_value_not_changed "display-time" "750"; then
        tmux set-option -g display-time 4000
    fi

    # refresh 'status-left' and 'status-right' more often
    if _option_value_not_changed "status-interval" "15"; then
        tmux set-option -g status-interval 5
    fi

    # required (only) on OS X
    if _is_osx && command -v "reattach-to-user-namespace" >/dev/null 2>&1 && \
        _option_value_not_changed "default-command" ""; then
        tmux set-option -g default-command "reattach-to-user-namespace -l $SHELL"
    fi

    # upgrade $TERM
    if _option_value_not_changed "default-terminal" "screen"; then
        tmux set-option -g default-terminal "screen-256color"
    fi

    # emacs key bindings in tmux command prompt (prefix + :) are better than
    # vi keys, even for vim users
    tmux set-option -g status-keys emacs

    # focus events enabled for terminals that support them
    tmux set-option -g focus-events on

    # super useful when using "grouped sessions" and multi-monitor setup
    tmux set-window-option -g aggressive-resize on

    # C-a should be the Tmux default prefix, really
    if _option_value_not_changed "prefix" "C-b"; then
        tmux set-option -g prefix C-a
    fi

    tmux set-option -g mode-keys vi

    # enable mouse features for terminals that support it
    tmux set-option -g mouse-resize-pane on
    tmux set-option -g mouse-select-pane on
    tmux set-option -g mouse-select-window on

    # DEFAULT KEY BINDINGS

    _stssettings__prefix="$(_prefix)"
    _stssettings__prefix_without_ctrl="$(_prefix_without_ctrl)"

    # if C-b is not prefix
    if [ "${_stssettings__prefix}" != "C-b" ]; then
        # unbind obsolte default binding
        if _key_binding_not_changed "C-b" "send-prefix"; then
            tmux unbind-key C-b
        fi

        # pressing `prefix + prefix` sends <prefix> to the shell
        if _key_binding_not_set "${_stssettings__prefix}"; then
            tmux bind-key "${_stssettings__prefix}" send-prefix
        fi
    fi

    # If Ctrl-a is prefix then `Ctrl-a + a` switches between alternate windows.
    # Works for any prefix character.
    if _key_binding_not_set "${_stssettings__prefix_without_ctrl}"; then
        tmux bind-key "$_stssettings__prefix_without_ctrl" last-window
    fi

    # easier switching between next/prev window
    if _key_binding_not_set "C-p"; then
        tmux bind-key C-p previous-window
    fi
    if _key_binding_not_set "C-n"; then
        tmux bind-key C-n next-window
    fi

    # source `.tmux.conf` file - as suggested in `man tmux`
    if _key_binding_not_set "R"; then
        tmux bind-key R run-shell '
            tmux source-file ~/.tmux.conf > /dev/null;
            tmux display-message "Sourced .tmux.conf!"'
    fi
}

if _supported_tmux_version; then
    _set_tmux_sensible_settings
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
    #"Error, Tmux version unsupported! Please install Tmux version ${SUPPORTED_TMUX_VERSION} or greater!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
