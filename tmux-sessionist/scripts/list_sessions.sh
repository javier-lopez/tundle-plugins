#!/bin/sh

if [ ! -t 0 ]; then
    #there is input comming from pipe or file, add to the end of $@
    #helpful to debug
    set -- "${@}" $(cat)
fi

if [ "${#}" -eq "0" ]; then
    session_list="$(tmux list-sessions -F "#{session_name}")"
else
    session_list="$(printf "%s\\n" "${@}")"
fi

pane_num="$(tmux list-panes | awk '/active/  {print NR; exit}')"
pane_width="$(tmux list-panes  -F '#{pane_width}'  | awk "NR == ${pane_num}")"
pane_height="$(tmux list-panes -F "#{pane_height}" | awk "NR == ${pane_num}")"
pane_height="$((pane_height - 5))" #take in consideration status lines

output_height="$(printf "%s" "${session_list}" | awk 'END {print NR}')"

#mark current session
current_session="$(tmux list-sessions | awk '/attached/ {sub(/:/,""); print $1}')"
session_list="$(printf "%s" "${session_list}" | sed "s:^${current_session}$:${current_session} (attached):")"

printf "%s\\n \\n" "Avalaible sessions:"

if [ "${output_height}" -gt "${pane_height}" ]; then
    cols="$(($output_height / $pane_height))"
    [ "$(($output_height % $pane_height))" -gt "0" ] && cols="$(($cols + 1))"

    #add 2 space paddings
    longest_word_len="$(printf "%s" "${session_list}" | awk 'length > max {max=length} END {print max+2}')"

    printf "%s" "${session_list}" | awk -v col="${cols}" \
        '{ if (NR % col == 0 ) {printf "%-'"${longest_word_len}"'s\n", $0 }
        else { printf "%-'"${longest_word_len}"'s", $0} } END { printf (NR % col == 0 )? "" : "\n" }' | \
        awk '{print "  - \"" $0 "\""}' | sed 's: (attached)"$:" (attached):'
    #TODO 11-08-2015 09:12 >> optionally transpose cols/raws
else
    printf "%s\\n" "${session_list}" | awk '{print "  - \"" $0 "\""}' | sed 's: (attached)"$:" (attached):'
fi

# vim: set ts=8 sw=4 tw=0 ft=sh :
