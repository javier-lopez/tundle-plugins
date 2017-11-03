#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/scripts/vars.sh"
. "${CURRENT_DIR}/scripts/helpers.sh"

if _supported_tmux_version_helper; then
    open_key="$(_get_tmux_option_global_helper "${open_option}" "${default_open_key}")"
    editor_key="$(_get_tmux_option_global_helper "${open_editor_option}" "${default_open_editor_key}")"

    open_cmd="$(_get_tmux_option_global_helper "${open_override}" "$(_get_default_open_cmd_helper)")"
    open_cmd="$(command -v "${open_cmd}")" #ensure it's actually installed
    editor_cmd="$(_get_tmux_option_global_helper "${open_editor_override}" "$(_get_default_editor_cmd_helper)")"
    editor_cmd="$(command -v "${editor_cmd}")"

    verbose=$(_get_tmux_option_global_helper "${verbose_mode_option}" "${verbose_mode_default}")

    if [ "${open_cmd}" ]; then
        if [ "${TMUX_VERSION}" -ge "18" ]; then #copy-pipe appeared in tmux 1.8
            for mode in vi-copy emacs-copy; do
                tmux bind-key -t "${mode}" "${open_key}" copy-pipe \
                    "$([ "${verbose}" = "y" ] && printf "tmux display-message 'Opening selection ...';")
                    xargs -I {} tmux run-shell 'cd #{pane_current_path}; ${open_cmd} \"{}\" > /dev/null' "
            done

            #custom user internet searches, eg: @open-g 'https://www.google.com/search?q='
            for engine_binding in $(_get_user_defined_search_engines_bindings); do
                url="$(_get_tmux_option_global_helper "${engine_binding}")"
                #remove prefix, which could be either @open_ or @open-
                binding="${engine_binding##@open}"; binding=${binding#?}

                for mode in vi-copy emacs-copy; do
                    tmux bind-key -t "${mode}" "${binding}" copy-pipe \
                        "$([ "${verbose}" = "y" ] && printf "tmux display-message 'Searching selection on $(dirname "${url}") ...';")
                        xargs -I {} tmux run-shell 'cd #{pane_current_path}; ${open_cmd} ${url}\"{}\" > /dev/null'"
                done
            done
        else
            #due to tmux limitations on versions < 1.8 yanking to the system clipboard is only possible traditionally in two steps
            #1. copy to tmux-buffer in copy-mode
            #2. sync tmux-buffer with the system clipboard

            #radical hack to do the above in one keystroke, http://unix.stackexchange.com/a/44602/63300
            if [ "${verbose}" = "y" ]; then
                _tmux_copy_mode_add_helper "${open_key}" "msg:Opening selection ..." \
                    "tmux save-buffer - | xargs -I {} ${open_cmd} \"{}\" > /dev/null"
            else
                _tmux_copy_mode_add_helper "${open_key}" "tmux save-buffer - | xargs -I {} ${open_cmd} \"{}\" > /dev/null"
            fi

            #custom user internet searches, eg: @open-s 'https://www.google.com/search?q='
            for engine_binding in $(_get_user_defined_search_engines_bindings); do
                url="$(_get_tmux_option_global_helper "${engine_binding}")"
                #remove prefix, which could be either @open_ or @open-
                binding="${engine_binding##@open}"; binding=${binding#?}

                if [ "${verbose}" = "y" ]; then
                    _tmux_copy_mode_add_helper "${binding}" "msg:Searching selection on $(dirname "${url}") ..." \
                        "tmux save-buffer - | xargs -I {} ${open_cmd} ${url}\"{}\" > /dev/null"
                else
                    _tmux_copy_mode_add_helper "${open_key}" "tmux save-buffer - | xargs -I {} ${open_cmd} ${url}\"{}\" > /dev/null"
                fi
            done

            for copy_mode_key in $(_get_tmux_copy_mode_keys); do
                _tmux_copy_mode_generate_helper "${copy_mode_key}" #& #?
            done
        fi
    else
        if [ "${TMUX_VERSION}" -ge "18" ]; then
            for mode in vi-copy emacs-copy; do
                tmux bind-key -t "${mode}" "${open_key}" run-shell "$(_display_deps_error_helper)"
            done

            #custom user internet searches, eg: @open-g 'https://www.google.com/search?q='
            for engine_binding in $(_get_user_defined_search_engines_bindings); do
                #remove prefix, which could be either @open_ or @open-
                binding="${engine_binding##@open}"; binding=${binding#?}

                for mode in vi-copy emacs-copy; do
                    tmux bind-key -t "${mode}" "${binding}" run-shell "$(_display_deps_error_helper)"
                done
            done
        else
            _tmux_copy_mode_add_helper "${open_key}" "$(_display_deps_error_helper)"

            for engine_binding in $(_get_user_defined_search_engines_bindings); do
                #remove prefix, which could be either @open_ or @open-
                binding="${engine_binding##@open}"; binding=${binding#?}
                _tmux_copy_mode_add_helper "${binding}" "$(_display_deps_error_helper)"
            done

            for copy_mode_key in $(_get_tmux_copy_mode_keys); do
                _tmux_copy_mode_generate_helper "${copy_mode_key}" #& #?
            done
        fi
    fi

    if [ "${editor_cmd}" ]; then
        if [ "${TMUX_VERSION}" -ge "18" ]; then #copy-pipe appeared in tmux 1.8
            for mode in vi-copy emacs-copy; do
                #vim freezes terminal unless there's the '--' argument. Other editors seem
                #to be fine with it (textmate [mate], light table [table]).
                tmux bind-key -t "${mode}" "${editor_key}" copy-pipe \
                    "xargs -I {} tmux send-keys '${editor_cmd} -- \"{}\"'; tmux send-keys 'C-m'"
            done
        else
            _tmux_copy_mode_add_helper "${editor_key}" \
                "tmux save-buffer - | xargs -I {} tmux send-keys '${editor_cmd} -- \"{}\"'; tmux send-keys 'C-m'"

            for copy_mode_key in $(_get_tmux_copy_mode_keys); do
                _tmux_copy_mode_generate_helper "${copy_mode_key}" #& #?
            done
        fi
    else
        if [ "${TMUX_VERSION}" -ge "18" ]; then
            for mode in vi-copy emacs-copy; do
                tmux bind-key -t "${mode}" "${editor_key}" run-shell "$(_display_deps_error_helper)"
            done
        fi
    fi
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
    #"Error, tmux version ${TMUX_VERSION} unsupported! Please install tmux version >= ${SUPPORTED_TMUX_VERSION}!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
