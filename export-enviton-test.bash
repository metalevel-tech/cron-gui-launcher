#!/bin/bash

# Simple script to check if the appropriate process is choosen. Use the script through a remote SSH connection to a machine with GUI.
# Example that will launch gnome-calculator fron the SSH session into the GUI session: 
# ./export-enviton-test.bash gnome-session-b gnome-calculator

DE_SESSION="${1}"

# Check whether the user is logged in Mate
while [ -z "$(pgrep "$DE_SESSION" -n -U $UID)" ]; do
        sleep 3 && count=$((count+1)) && echo "$count"
done

# Get the content of the Current-Desktop-Session Environment File as an array:
EnvVarList=`cat -e "/proc/$(pgrep "$DE_SESSION" -n -U $UID)/environ" | sed 's/\^@/\n/g'`

# Export the Current-Desktop-Session Environment Variables:
for EnvVar in $EnvVarList; do
        echo "$EnvVar"
        export "$EnvVar"
done

# Execute the list of the input commands
nohup "${2}" >/dev/null 2>&1 &
