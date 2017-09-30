#!/bin/bash

# Create log file. Use "$2" to leave a description within the name.
if [ -z "${2+x}" ]; then DESCRIPTION=""; else DESCRIPTION="-$2"; fi
LOG="/tmp/$USER-cron-gui-launcher$DESCRIPTION.log"
printf "\n$(date +%Y-%m-%d_%H:%M:%S)\n\n\nDetected environment variables:\n\n" > $LOG

# Get the value of the $DISPLAY variable for the current user. Unset it just in case this is a `ssh -X` connection
unset DISPLAY
while [ -z $DISPLAY ]; do
        DISPLAY=$(w $USER | awk 'NF > 7 && $2 ~ /tty[0-9]+/ {print $3; exit}' 2>/dev/null)
        if [ "$DISPLAY" == "" ]; then sleep 30; else export DISPLAY=$DISPLAY; fi
done; printf "DISPLAY=$DISPLAY\n" >> $LOG

# --------------------

# Get the most frequent value from an array any array - https://stackoverflow.com/a/43440769/6543935
get_frequent(){
        awk 'BEGIN{ FS=" " } { for(i=1;i<=NF;i++) print $i }' | \
        awk '{ n=++hsh[$1]; if(n>max_occ){ max_occ=n; what=$1 } else if(n==max_occ){ if(what>$1) what=$1 } } END{ print what }'
}

# Get certain envvar value ("$1") from any "/proc/$ProcessNumber/environ" file ("$2")
get_environ(){
	EnvVar=$(sed -zne "s/^$1=//p" "/proc/$2/environ" 2>/dev/null); printf "$EnvVar";
}

#
export_environ(){
        printf "\n\nExported environment (source file /proc/$1/environ):\n\n" >> $LOG
	for EnvVar in $(cat -e "/proc/$1/environ" | sed 's/\^@/\n/g'); do echo "export $EnvVar" >> $LOG; export "$EnvVar"; done
}

execute_input_commands(){
	printf "$1" | awk 'BEGIN{ FS=" && "; print "\n\nInput command list:" } {for(i=1;i<=NF;i++) system("echo \"Command: " $i "\" && nohup " $i " >/dev/null 2>&1 &")}' >> $LOG
}

# Get the values of $XDG_CURRENT_DESKTOP from each "/proc/$ProcessNumber/environ" file - create an array.
# Get the most frequent name of any desctop environment - within the created array # This is a way to find the current DE when it is changed a little bit ago
for PN in $(pgrep -U "$UID"); do XDG_CURRENT_DESKTOP+=$(get_environ "XDG_CURRENT_DESKTOP" "$PN"; echo " "); done
XDG_CURRENT_DESKTOP=$(echo -e ${XDG_CURRENT_DESKTOP[@]} | get_frequent)
declare -l DE && export DE="${XDG_CURRENT_DESKTOP/:*/}" && printf "XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP\nDE=$DE\n" >> $LOG

# ---------------------------

# Export the Desktop Environment Variables:
if   [ "$DE" = "unity" ];               then export_environ "$(pgrep gnome-session -n -U $UID)"
elif [ "$DE" = "gnome" ];               then export_environ "$(pgrep gnome-session -n)"
elif [ "$DE" = "gnome-classic" ];       then export_environ "$(pgrep gnome-session -n)"
elif [ "$DE" = "kde" ];                 then export_environ "$(pgrep startkde -n)"
elif [ "$DE" = "mate" ];                then export_environ "$(pgrep mate-session  -n)"
elif [ "$DE" = "lxde" ];                then export_environ "$(pgrep lxsession -n)"
elif [ "$DE" = "xfce" ];                then export_environ "$(pgrep xfce4-session -n)"
elif [ "$DE" = "xfce4" ];               then export_environ "$(pgrep xfce4-session -n)"
else printf "Your current Desktop Environment is not supported!\n Please contribute to https://github.com/pa4080/cron-gui-launcher\n" >> $LOG
fi

if [ -z "${1+x}" ]; then
	printf "\n\nThere is not any input command!\n"
else
	execute_input_commands "$1"
fi

# Debug --------
cat $LOG

