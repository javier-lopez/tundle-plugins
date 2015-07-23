#!/bin/sh

#copycat integration for older tmux versions without copy-pipe
#this script is source from tmux-copycat/scripts/copycat_mode_start.sh
. "${tmux_open_dir}/scripts/vars.sh"
. "${tmux_open_dir}/scripts/helpers.sh"

open_key="$(_get_tmux_option_global_helper "${open_option}" "${default_open_key}")"
editor_key="$(_get_tmux_option_global_helper "${open_editor_option}" "${default_open_editor_key}")"

open_cmd="$(_get_tmux_option_global_helper "${open_override}" "$(_get_default_open_cmd_helper)")"
open_cmd="$(command -v "${open_cmd}")" #ensure it's actually installed
editor_cmd="$(_get_tmux_option_global_helper "${open_editor_override}" "$(_get_default_editor_cmd_helper)")"
editor_cmd="$(command -v "${editor_cmd}")"

verbose=$(_get_tmux_option_global_helper "${verbose_mode_option}" "${verbose_mode_default}")

if [ "${open_cmd}" ]; then
    if [ "${verbose}" = "y" ]; then
        _copycat_mode_add_helper "${open_key}" "msg:Opening selection ..." \
            "tmux save-buffer - | xargs -I {} ${open_cmd} \"{}\" > /dev/null"
    else
        _copycat_mode_add_helper "${open_key}" "tmux save-buffer - | xargs -I {} ${open_cmd} \"{}\" > /dev/null"
    fi

    #custom user internet searches, eg: @open-s 'https://www.google.com/search?q='
    for engine_binding in $(_get_user_defined_search_engines_bindings); do
        url="$(_get_tmux_option_global_helper "${engine_binding}")"
        #remove prefix, which could be either @open_ or @open-
        binding="${engine_binding##@open}"; binding=${binding#?}

        if [ "${verbose}" = "y" ]; then
            _copycat_mode_add_helper "${binding}" "msg:Searching selection on $(dirname "${url}") ..." \
                "tmux save-buffer - | xargs -I {} ${open_cmd} ${url}\"{}\" > /dev/null"
        else
            _copycat_mode_add_helper "${open_key}" "tmux save-buffer - | xargs -I {} ${open_cmd} ${url}\"{}\" > /dev/null"
        fi
    done

    _copycat_mode_generate_helper #& #?
else
    _copycat_mode_add_helper "${open_key}" "$(_display_deps_error_helper)"

    for engine_binding in $(_get_user_defined_search_engines_bindings); do
        #remove prefix, which could be either @open_ or @open-
        binding="${engine_binding##@open}"; binding=${binding#?}
        _copycat_mode_add_helper "${binding}" "$(_display_deps_error_helper)"
    done

    _copycat_mode_generate_helper #& #?
fi

if [ "${editor_cmd}" ]; then
    _copycat_mode_add_helper "${editor_key}" \
        "tmux save-buffer - | xargs -I {} tmux send-keys '${editor_cmd} -- \"{}\"'; tmux send-keys 'C-m'"
    _copycat_mode_generate_helper #& #?
else
    _copycat_mode_add_helper "${editor_key}" "$(_display_deps_error_helper)"
    _copycat_mode_generate_helper #& #?
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
