#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/../helpers.sh"
. "${CURRENT_DIR}/../vars.sh"

_print_template() {
    if [ "${2}" = "true" ]; then
        # newline and spacing so tag is aligned with other tags in template
        _ptemplate__fullscreen_tag="$(printf "\\n")        <string>fullscreen</string>"
    fi

    _ptemplate__content="$(cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict> <key>Label</key>
<string>${osx_auto_start_file_name}</string>
<key>ProgramArguments</key>
<array>
<string>${1}</string>${_ptemplate__fullscreen_tag}
</array>
<key>RunAtLoad</key>
<true/>
</dict>
</plist>
EOF
    )"

    _ptemplate__content="$(printf "%s" "${_ptemplate__content}" | sed 's:DOCTYPE:!DOCTYPE')"
    printf "%s\\n" "${_ptemplate__content}"
}

_get_terminal() {
    case "${1}" in
        *iterm*) printf "%s" "iterm" ;;
            #Terminal.app is the default console app
            *) printf "%s" "terminal" ;;
    esac
}

_get_fullscreen_option() {
    case "${1}" in
        *fullscreen*) printf "%s" "true"  ;;
                   *) printf "%s" "false" ;;
    esac
}

options="$(_get_tmux_option_global_helper "${continuum_boot_options_option}" "${continuum_boot_options_default}")"
terminal="$(_get_terminal "${options}")"
fullscreen_option="$(_get_fullscreen_option "${options}")"
tmux_start_script="${CURRENT_DIR}/osx_${terminal}_start_tmux.sh"

_print_template "${tmux_start_script}" "${fullscreen_option}" > "${osx_boot_start_file_path}"

# vim: set ts=8 sw=4 tw=0 ft=sh :
