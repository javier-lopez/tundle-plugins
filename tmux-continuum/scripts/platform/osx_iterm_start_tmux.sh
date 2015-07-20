#!/bin/sh

osascript << EOF
tell application "iTerm"
    activate

    # open iterm window
    try
        set _session to current session of current terminal
    on error
        set _term to (make new terminal)
        tell _term
            launch session "Tmux"
            set _session to current session
        end tell
    end try

    # start tmux
    tell _session
        write text "tmux"
    end tell
end tell
EOF

#for "true full screen" call the script with "fullscreen" as the first argument
if [ "${1}" = "fullscreen" ]; then
    osascript << EOF
tell application "iTerm"
    # wait for iTerm to start
    delay 1
    activate
    # short wait for iTerm to gain focus
    delay 0.1
    # Command + Enter for fullscreen
    tell i term application "System Events"
        key code 36 using {command down}
    end tell
end tell
EOF
else
    osascript << EOF
tell application "iTerm"
    set winID to id of window 1
    tell i term application "Finder"
        set desktopSize to bounds of window of desktop
    end tell
    set bounds of window id winID to desktopSize
end tell
EOF
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
