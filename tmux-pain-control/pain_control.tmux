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

    if [ "${CURRENT_TMUX_VERSION}" -ge "19" ]; then
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

default_pane_resize="5"

_pane_navigation_bindings() {
    tmux bind-key h   select-pane -L
    tmux bind-key C-h select-pane -L
    tmux bind-key j   select-pane -D
    tmux bind-key C-j select-pane -D
    tmux bind-key k   select-pane -U
    tmux bind-key C-k select-pane -U
    tmux bind-key l   select-pane -R
    tmux bind-key C-l select-pane -R
}

_window_move_bindings() {
    tmux bind-key -r "<" swap-window -t -1
    tmux bind-key -r ">" swap-window -t +1
}

_pane_resizing_bindings() {
    _prbindings__pane_resize="$(_get_tmux_environment_helper "@pane_resize")"
    [ -z "${_prbindings__pane_resize}" ] && \
    _prbindings__pane_resize="$(_get_tmux_option_helper "@pane_resize" "${default_pane_resize}")"
    tmux bind-key -r H resize-pane -L "$_prbindings__pane_resize"
    tmux bind-key -r J resize-pane -D "$_prbindings__pane_resize"
    tmux bind-key -r K resize-pane -U "$_prbindings__pane_resize"
    tmux bind-key -r L resize-pane -R "$_prbindings__pane_resize"
}

_pane_split_bindings() {
    if [ "${TMUX_VERSION}" -ge "19" ]; then
        tmux bind-key "|" split-window -h -c "#{pane_current_path}"
        tmux bind-key "-" split-window -v -c "#{pane_current_path}"
    else #tmux => 1.6 altough could work on even lower tmux versions
        tmux bind-key "|" split-window -h
        tmux bind-key "-" split-window -v
    fi
}

_improve_new_window_binding() {
    if [ "${TMUX_VERSION}" -ge "19" ]; then
        tmux bind-key "c" new-window -c "#{pane_current_path}"
    else #tmux => 1.6 altough could work on even lower tmux versions
        tmux bind-key "c" new-window
    fi
}

if _supported_tmux_version; then
    _pane_navigation_bindings
    _window_move_bindings
    _pane_resizing_bindings
    _pane_split_bindings
    _improve_new_window_binding
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
    #"Error, Tmux version unsupported! Please install Tmux version ${SUPPORTED_TMUX_VERSION} or greater!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
