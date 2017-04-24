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

_get_tmux_server_option_helper() {
    [ -z "${1}" ] && return 1

    if [ "${TMUX_VERSION}" -ge "18" ]; then
        _gtsohelper__value="$(tmux show-option -sv "${1}")"
    else #tmux => 1.6 altough could work on even lower tmux versions
        _gtsohelper__value="$(tmux show-option -s|awk "/^${1}/ {gsub(/\'/,\"\");gsub(/\"/,\"\"); print \$2; exit;}")"
    fi

    if [ -z "${_gtsohelper__value}" ]; then
        [ -z "${2}" ] && return 1 || printf "%s\\n" "${2}"
    else
        printf "%s\\n" "${_gtsohelper__value}"
    fi
}

_supported_tmux_version() {
    _stversion__supported="$(_get_digits_from_string_helper "${SUPPORTED_TMUX_VERSION}")"
    if [ -z "${TMUX_VERSION}" ] || [ -z "$(_get_tmux_environment_helper "TMUX_VERSION")" ]; then
        TMUX_VERSION="$(_get_digits_from_string_helper "$(tmux -V)")"
        export TMUX_VERSION #speed up consecutive calls
        tmux set-environment -g TMUX_VERSION "${TMUX_VERSION}"
    fi

    [ "${TMUX_VERSION}" -lt "${_stversion__supported}" ] && return 1 || return 0
}

###################################################################################
############################# Plugin specific utils ###############################
###################################################################################

# used to match output from `tmux list-keys`
KEY_BINDING_REGEX="bind-key[[:space:]]\+\(-r[[:space:]]\+\)\?\(-T prefix[[:space:]]\+\)\?"
# used to match output from `tmux list-keys -t key-table`
KEY_BINDING_REGEX_KEY_TABLE="bind-key[[:space:]]\+-t[[:space:]]\+\(vi\|emacs\)-copy[[:space:]]\+"

sensible_mouse_default="y"
sensible_mouse_option="@sensible_mouse"

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
    if [ -z "${3}" ]; then
        tmux list-keys | grep "${KEY_BINDING_REGEX}${1}[[:space:]]\+${2}" >/dev/null
    else
        tmux list-keys -t "${3}"| grep "${KEY_BINDING_REGEX_KEY_TABLE}${1}[[:space:]]\+${2}" >/dev/null
    fi
}

_set_tmux_sensible_settings() {
    # enable utf8
    tmux set-option -g utf8 on

    # enable utf8 in tmux status-left and status-right
    tmux set-option -g status-utf8 on

    # start windows and panes at 1, not 0, to match with vim, bspwm and i3
    if _option_value_not_changed "base-index" "0"; then
        tmux set-option -g base-index      1
    fi

    if _option_value_not_changed "pane-base-index" "1"; then
        tmux set-option -g pane-base-index 1
    fi

    if [ "$(tmux -V | tr -dC '0123456789')" -ge "17" ]; then
        #renumber when window is closed
        if _option_value_not_changed "renumber-windows" "off"; then
            tmux set-option -g renumber-windows on
        fi
    fi

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
    if [ "$(uname)" = "Darwin" ] && command -v "reattach-to-user-namespace" >/dev/null 2>&1 && \
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

    # default to vi-copy mode
    tmux set-option -g mode-keys vi

    # enable mouse features for terminals that support it
    if [ "$(_get_tmux_option_global_helper "${sensible_mouse_option}" "${sensible_mouse_default}")" = "y" ]; then
        tmux set-option -g mouse-resize-pane on
        tmux set-option -g mouse-select-pane on
        tmux set-option -g mouse-select-window on
    fi

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
    for key in r R; do
        if _key_binding_not_set "${key}"; then
            tmux bind-key       "${key}"  run-shell '
                tmux source-file ~/.tmux.conf > /dev/null;
                tmux display-message "Sourced .tmux.conf!"'
        fi
    done; unset key

    # vi like experience for vi-copy mode
    if _key_binding_not_set "Escape"; then
        tmux bind Escape copy-mode

        tmux bind -t vi-copy Home start-of-line
        tmux bind -t vi-copy End end-of-line
    fi

    if _key_binding_not_changed Space begin-selection "vi-copy"; then
        tmux bind -t vi-copy v begin-selection
        tmux bind -t vi-copy V begin-selection
    fi

    if _key_binding_not_changed Enter copy-selection "vi-copy"; then
        tmux bind -t vi-copy y copy-selection
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
