#!/bin/bash
#--------------------------------------------------------------------------------------------------
#  _    _ _       _____        __  __   ____  __ _   _________      __
# | |  | | |     / ____|      / /  \ \ / /  \/  | | |__   __\ \    / /
# | |__| | |    | (___       / /    \ V /| \  / | |    | |   \ \  / / 
# |  __  | |     \___ \     / /      > < | |\/| | |    | |    \ \/ /  
# | |  | | |____ ____) |   / /      / . \| |  | | |____| |     \  /   
# |_|  |_|______|_____/   /_/      /_/ \_\_|  |_|______|_|      \/     
#                                                                                                                 
#                                                                                                                 
#  _    _  ____  __  __ ______   ____  _____   ____          _____   _____           _____ _______ _____ _   _  _____ 
# | |  | |/ __ \|  \/  |  ____| |  _ \|  __ \ / __ \   /\   |  __ \ / ____|   /\    / ____|__   __|_   _| \ | |/ ____|
# | |__| | |  | | \  / | |__    | |_) | |__) | |  | | /  \  | |  | | |       /  \  | (___    | |    | | |  \| | |  __ 
# |  __  | |  | | |\/| |  __|   |  _ <|  _  /| |  | |/ /\ \ | |  | | |      / /\ \  \___ \   | |    | | | . ` | | |_ |
# | |  | | |__| | |  | | |____  | |_) | | \ \| |__| / ____ \| |__| | |____ / ____ \ ____) |  | |   _| |_| |\  | |__| |
# |_|  |_|\____/|_|  |_|______| |____/|_|  \_\\____/_/    \_\_____/ \_____/_/    \_\_____/   |_|  |_____|_| \_|\_____|               
#
# Easy Concat List Maker Scipt.
#
#
# HLS / XMLTV Home broadcasting : https://github.com/deanochips/HLS-XMLTV---Home-Broadcasting
#
# AUTHOR				DATE			DETAILS
# --------------------- --------------- --------------------------------
# Dean Butler           2020-01-05      Initial version
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
# define folder locations
# --------------------------------------------------------------------------------------------------
cd $(dirname ${BASH_SOURCE[0]})
source ./config.cfg


shopt -s extglob


menu_items() {
	M=0   # start loop counter

	for args in $CHANNELS_DIR/*; do 
		echo "	"$M") ""$(basename "${args}" )"
		M=$((M + 1))  # loop counter
	done

}
countdown () {
	sleep 1 && ${ECHO} -ne "5..."
	sleep 1 && ${ECHO} -ne "4..."
	sleep 1 && ${ECHO} -ne "3..."
	sleep 1 && ${ECHO} -ne "2..."
	sleep 1 && ${ECHO} -ne "1"
}
action() {
	M=0   # start loop counter

	for args in $CHANNELS_DIR/*; do 
		if [ "$1" == "$M" ];
		then


                        SHOWNAME=$(basename "${args}"  | sed -r "s| |_|g")

			find "$args" -name '*.mkv' -o -name '*.mp4' -o -name '*.avi' -o -name '*.m4v' -o -name '*.mov'|while read fname; do
			FULLPATH=$(realpath "$fname")

			FFMPEG_COMPAT_FILE=$(echo $FULLPATH | sed -e "s/'/'\\\''/g" | sed "s|-|'\\\-'|g"  )
			echo -ne "file '" >> "$TMP_TVLISTS_DIR""/""$SHOWNAME"".txt";
			echo -ne "$FFMPEG_COMPAT_FILE" >> "$TMP_TVLISTS_DIR""/""$SHOWNAME"".txt";
			echo "'" >> "$TMP_TVLISTS_DIR""/""$SHOWNAME"".txt";

		done

		sort "$TMP_TVLISTS_DIR""/""$SHOWNAME"".txt" > "$CONCAT_LIST_DIR""/""$SHOWNAME"".txt"

		echo "$CONCAT_LIST_DIR""/""$SHOWNAME"".txt Created"

		sleep 2

		rm "$TMP_TVLISTS_DIR""/""$SHOWNAME"".txt"

		fi
		M=$((M + 1))  # loop counter
	done
	countdown
	clear
	unset $SPLASH_RUN_YET
	load_splash_screen
}

show_menus() {
	sleep 0.01 && ${ECHO} "$green "
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /-}
	sleep 0.01 && ${ECHO} -ne "$BGreen "
	echo -ne "\033[1mEASY CONCAT LIST MAKER\033"
	sleep 0.01 && ${ECHO} "$green "
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /-}
	echo ""
	menu_items
	echo ""
	echo "CTRL-C to Exit"
	echo ""

}

read_options(){
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /-}
	local choice
	read -p "Enter choice: " choice
	action $choice
}


while true
do
	show_menus
	read_options
done




shopt -u extglob
