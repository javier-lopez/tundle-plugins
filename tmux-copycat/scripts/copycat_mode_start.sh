#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/vars.sh"
. "${CURRENT_DIR}/helpers.sh"

_copycat_generate_results(){
    if ! _in_copycat_mode_helper; then
        [ -z "${1}" ] && return 1
        _cgresults__copycat_fname="$(_get_copycat_filename_helper)"

        #remove old files and reset settings
        rm -f "${_cgresults__copycat_fname}"
        tmux set-environment -g "@copycat_first_invocation" "0"

        #generate copycat directory
        _mkdir_p_helper "$(_get_tmp_copycat_dir_helper)"

        #9M lines back will hopefully fetch the whole scrollback
        tmux capture-pane -S -"${2-9000000}"

        #sort file in reverse order makes jumping lines from bottom to top cheaper
        tmux save-buffer - | (tac 2>/dev/null || awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--]}' 2>/dev/null) | \
            #create a x:y:regex file, so copycat_jump.sh knows where to jump to select the desired regex
            #http://www.unix.com/shell-programming-and-scripting/259372-how-get-index-values-multiple-matches-same-line-awk.html
            awk -vsearch="${1}" 'match(tolower($0),search) {
            string=tolower($0); m=0;
            while((n=match(string,search))>0)
                {
                    m+=n;
                    printf ("%s:%s:%s\n", FNR, m, substr($0, m, RLENGTH))
                    string=substr(string, n+RLENGTH)
                    m+=RLENGTH - 1;
                }
            }' > "${_cgresults__copycat_fname}"

        [ -s "${_cgresults__copycat_fname}" ] || return 1

        tmux set-environment -g "@copycat_mode_$(_pane_unique_id_helper)" "true"
        _increase_internal_counter_helper
    fi
}

_copycat_mode_bindings(){
    _extend_key_helper "$(_get_tmux_option_global_helper "${tmux_option_next}" "${default_next_key}")" \
        "${CURRENT_DIR}/copycat_jump.sh 'next'"
    _extend_key_helper "$(_get_tmux_option_global_helper "${tmux_option_prev}" "${default_prev_key}")" \
        "${CURRENT_DIR}/copycat_jump.sh 'prev'"

    #keys that quit copy mode are enhanced to quit copycat mode as well.
    for _cmbindings__key in $(_copycat_quit_copy_mode_keys_helper); do
        _extend_key_helper "${_cmbindings__key}" "${CURRENT_DIR}/copycat_mode_quit.sh"
    done

    #yank integration for older tmux versions without copy-pipe
    if [ "${TMUX_VERSION-16}" -lt "18" ]; then
        TMUX_PLUGIN_MANAGER_PATH="$(_get_tmux_environment_helper "TMUX_PLUGIN_MANAGER_PATH")"

        #default case with tundle git subdirectories
        if [ -f "${TMUX_PLUGIN_MANAGER_PATH}/tmux-yank/tmux-yank/yank.tmux" ]; then
            tmux_yank_dir="${TMUX_PLUGIN_MANAGER_PATH}/tmux-yank/tmux-yank/"
        elif [ -f "${TMUX_PLUGIN_MANAGER_PATH}/tmux-yank/yank.tmux" ]; then
            tmux_yank_dir="${TMUX_PLUGIN_MANAGER_PATH}/tmux-yank/"
        fi

        if [ -f "${TMUX_PLUGIN_MANAGER_PATH}/tmux-copycat/tmux-copycat/copycat.tmux" ]; then
            tmux_copycat_dir="${TMUX_PLUGIN_MANAGER_PATH}/tmux-copycat/tmux-copycat/"
        elif [ -f "${TMUX_PLUGIN_MANAGER_PATH}/tmux-copycat/copycat.tmux" ]; then
            tmux_copycat_dir="${TMUX_PLUGIN_MANAGER_PATH}/tmux-copycat/"
        fi

        . "${tmux_yank_dir}/scripts/yank_copycat_16.sh"
    fi
}

if _supported_tmux_version_helper; then
    #9M lines back will hopefully fetch the whole scrollback
    if ! _copycat_generate_results "${1}" "9000000"; then
        _display_message_helper "No results!"
        exit 0
    fi
    _copycat_mode_bindings
    "${CURRENT_DIR}/copycat_jump.sh" 'next'
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
        #"Error, Tmux version unsupported! Please install Tmux version ${SUPPORTED_TMUX_VERSION} or greater!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
