#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/scripts/vars.sh"
. "${CURRENT_DIR}/scripts/helpers.sh"

if _supported_tmux_version_helper; then
    #set default bindings
    key=""; for key in $(_get_tmux_option_global_helper "${tmux_option_goto}" "${default_key_bindings_goto}"); do
        tmux bind "${key}" run "${CURRENT_DIR}/scripts/goto_session.sh"
    done

    #switch to the last/alternate session
    key=""; for key in $(_get_tmux_option_helper "${tmux_option_alternate}" "${default_key_bindings_alternate}"); do
        tmux bind "${key}" switch-client -l
    done

    #prompt for creating a new session. If the session with the same name exists, it will switch to the existing session
    key=""; for key in $(_get_tmux_option_helper "$tmux_option_new" "$default_key_bindings_new"); do
        tmux bind "${key}" run "${CURRENT_DIR}/scripts/new_session_prompt.sh"
    done

    #"promote" current pane to a new session
    key=""; for key in $(_get_tmux_option_helper "${tmux_option_promote_pane}" "${default_key_bindings_promote_pane}"); do
        tmux bind "${key}" run "${CURRENT_DIR}/scripts/promote_pane.sh"
    done

    key=""; for key in $(_get_tmux_option_helper "${tmux_option_kill_session}" "${default_key_bindings_kill_session}"); do
        tmux bind "${key}" run "${CURRENT_DIR}/scripts/kill_session_prompt.sh"
    done
else
    #should errors will be displayed per plugin?
    #_display_message_helper "$(printf "%s\\n" \
        #"Error, Tmux version unsupported! Please install Tmux version ${SUPPORTED_TMUX_VERSION} or greater!")"
    exit 1
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
