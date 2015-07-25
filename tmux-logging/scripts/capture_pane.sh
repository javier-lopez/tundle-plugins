#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/vars.sh"
. "${CURRENT_DIR}/helpers.sh"

_get_env_fname() {
    _gefname__fname="$(printf "%s" "${1}" | sed "s:\$HOME:${HOME}:g;s:~/:${HOME}/:;s:\"::g;s:\'::g;")"
    case "${_gefname__fname}" in
        */*) : ;;
          *) _gefname__fname="${HOME}/${_gefname__fname}" ;;
    esac

    printf "%s" "${_gefname__fname}"
}

_capture_log() {
    if [ -z "${1}" ]; then
        _clog__fname="$(_get_fname_helper "@logging")"
    else
        _clog__fname="$(_get_env_fname "${1}")"
    fi

    if command -v "ansifilter" >/dev/null 2>&1; then
        #pipe pane + shell command is funnily supported in old tmux releases
        #at least between 1.6 and 1.9, that's weird considering poor tmux
        #features in earlier versions
        tmux pipe-pane "exec cat - | ansifilter >> ${_clog__fname}"
    else
        case "$(uname)" in
            Darwin) #Warning, very complex regex ahead.
                #Some characters below might not be visible from github web view.
                #OSX uses sed '-E' flag and a slightly different regex
                _clog__regex="(\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]||]0;[^]+|[[:space:]]+$)"
                tmux pipe-pane "exec cat - | sed -E \"s/${_clog__regex}//g\" >> ${_clog__fname}"
                ;;
            *)  _clog__regex="(\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]|)"
                tmux pipe-pane "exec cat - | sed -r \"s/${_clog__regex}//g\" >> ${_clog__fname}"
                ;;
        esac
    fi

    _display_message_helper "Started logging to ${_clog__fname}"
    tmux set-environment -g "@logging_$(_pane_unique_id_helper)" "logging" > /dev/null
    tmux set-environment -g "@logging_fname" "${_clog__fname}" > /dev/null
}

_capture_screen_history() {
    [ -z "${1}" ] && return 1 || _cshistory__scope="${1}"

    if [ -z "${2}" ]; then
        case "${_cshistory__scope}" in
             Screen) _cshistory__fname="$(_get_fname_helper "@screen-capture")" ;;
            History) _cshistory__fname="$(_get_fname_helper "@save-complete-history")" ;;
        esac
    else
        _cshistory__fname="$(_get_env_fname "${2}")"
    fi

    case "${_cshistory__scope}" in
        Screen*)
            if [ "${TMUX_VERSION-16}" -ge "18" ]; then
                tmux capture-pane -J -p > "${_cshistory__fname}"
            else
                tmux capture-pane && tmux save-buffer "${_cshistory__fname}" && tmux delete-buffer
            fi
            ;;
        History)
            if [ "${TMUX_VERSION-16}" -ge "18" ]; then #because of -p/-J
                tmux capture-pane -J -S "-$(tmux list-panes -F "#{history_limit}")" -p > "${_cshistory__fname}"
            else
                tmux capture-pane -S "-$(tmux list-panes -F "#{history_limit}")"
                tmux save-buffer "${_cshistory__fname}" && tmux delete-buffer
            fi
            ;;
        *) return 1 ;;
    esac

    #remove empty lines from the end of a file, http://unix.stackexchange.com/a/81689
    printf '%s\n' "$(cat "${_cshistory__fname}")" > "${_cshistory__fname}"
    _display_message_helper "${_cshistory__scope} saved to ${_cshistory__fname}"
}

case "${1}" in
                Log) _capture_log "${2}" ;;
     Screen|History) _capture_screen_history "${1}" "${2}" ;;
esac

# vim: set ts=8 sw=4 tw=0 ft=sh :
