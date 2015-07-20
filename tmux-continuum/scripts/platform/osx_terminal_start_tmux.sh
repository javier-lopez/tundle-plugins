#!/bin/sh

osascript << EOF
tell application "Terminal"
if not (exists window 1) then reopen
    activate
    set winID to id of window 1
do script "tmux" in window id winID
    end tell
EOF

# for "true full screen" call the script with "fullscreen" as the first argument
if [ "${1}" = "fullscreen" ]; then
    osascript << EOF
tell application "Terminal"
# waiting for Terminal.app to start
delay 1
activate
# short wait for Terminal to gain focus
delay 0.1
tell application "System Events"
keystroke "f" using {control down, command down}
end tell
end tell
EOF
else
    osascript << EOF
tell application "Terminal"
set winID to id of window 1
tell application "Finder"
set desktopSize to bounds of window of desktop
end tell
set bounds of window id winID to desktopSize
end tell
EOF
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
