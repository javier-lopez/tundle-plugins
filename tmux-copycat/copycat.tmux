#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/scripts/vars.sh"
. "${CURRENT_DIR}/scripts/helpers.sh"

if _supported_tmux_version_helper; then
    file_search="$(_get_tmux_option_global_helper  "${copycat_file_search_option}"  "${default_file_search_key}")"
    url_search="$(_get_tmux_option_global_helper   "${copycat_url_search_option}"   "${default_url_search_key}")"
    digit_search="$(_get_tmux_option_global_helper "${copycat_digit_search_option}" "${default_digit_search_key}")"
    hash_search="$(_get_tmux_option_global_helper  "${copycat_hash_search_option}"  "${default_hash_search_key}")"
    ip_search="$(_get_tmux_option_global_helper    "${copycat_ip_search_option}"    "${default_ip_search_key}")"
    git_search="$(_get_tmux_option_global_helper   "${copycat_git_search_option}"   "${default_git_search_key}")"

    if _get_tmux_option_global_helper "${COPYCAT_VAR_PREFIX}_${url_search}" >/dev/null; then
        tmux setenv -g "${COPYCAT_VAR_PREFIX}_${url_search}" "(https?://|git@|git://|ssh://|ftp://|file:///)[0-9a-z_./~:,;()!?%*#$%&+=@-]+"
    fi

    if _get_tmux_option_global_helper "${COPYCAT_VAR_PREFIX}_${file_search}" >/dev/null; then
        tmux setenv -g "${COPYCAT_VAR_PREFIX}_${file_search}" "[0-9a-z_.~#$%&+=@-]*/[0-9a-z_./~#$%&+=@-]*"
    fi

    if _get_tmux_option_global_helper "${COPYCAT_VAR_PREFIX}_${digit_search}" >/dev/null; then
        tmux setenv -g "${COPYCAT_VAR_PREFIX}_${digit_search}" "[0-9]+"
    fi

    if _get_tmux_option_global_helper "${COPYCAT_VAR_PREFIX}_${hash_search}" >/dev/null; then
        #repeat intervals requires --posix in gawk and other posix compliant awk implementations which may be not be available
        #see scripts/copycat_mode_start.sh:26 to change this
        #tmux setenv -g "${COPYCAT_VAR_PREFIX}_${hash_search}" "[0-9a-f]{7,40}"
        tmux setenv -g "${COPYCAT_VAR_PREFIX}_${hash_search}" "[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?[0-9a-f]?"
    fi

    if _get_tmux_option_global_helper "${COPYCAT_VAR_PREFIX}_${ip_search}" >/dev/null; then
        tmux setenv -g "${COPYCAT_VAR_PREFIX}_${ip_search}" "[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+"
    fi

    if _get_tmux_option_global_helper "${COPYCAT_VAR_PREFIX}_${git_search}" >/dev/null; then
        tmux setenv -g "${COPYCAT_VAR_PREFIX}_${git_search}" "[0-9a-z_./~#$%&+=@-]+$"
    fi

    for var in $(_get_copycat_search_vars_helper); do
        pattern="$(_get_tmux_option_global_helper "${var}")"
        tmux bind-key "${var##${COPYCAT_VAR_PREFIX}_}" run-shell "${CURRENT_DIR}/scripts/copycat_mode_start.sh '${pattern}'"
    done

    #copycat search default bindings
    for key in $(_get_tmux_option_global_helper "${copycat_search_option}" "${default_copycat_search_key}"); do
        tmux bind-key "${key}" run-shell "${CURRENT_DIR}/scripts/copycat_search.sh"
    done
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
        #"Error, Tmux version unsupported! Please install Tmux version ${SUPPORTED_TMUX_VERSION} or greater!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
