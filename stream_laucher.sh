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
#  _    _  ____  __  __ ______   ____  _____   ____          _____   _____           _____ _______ _____ _   _  ___
# | |  | |/ __ \|  \/  |  ____| |  _ \|  __ \ / __ \   /\   |  __ \ / ____|   /\    / ____|__   __|_   _| \ | |/ ____|
# | |__| | |  | | \  / | |__    | |_) | |__) | |  | | /  \  | |  | | |       /  \  | (___    | |    | | |  \| | |  __
# |  __  | |  | | |\/| |  __|   |  _ <|  _  /| |  | |/ /\ \ | |  | | |      / /\ \  \___ \   | |    | | | . ` | | |_ |
# | |  | | |__| | |  | | |____  | |_) | | \ \| |__| / ____ \| |__| | |____ / ____ \ ____) |  | |   _| |_| |\  | |__| |
# |_|  |_|\____/|_|  |_|______| |____/|_|  \_\\____/_/    \_\_____/ \_____/_/    \_\_____/   |_|  |_____|_| \_|\_____|
#
# HLS / XMLTV Home broadcasting
# Stream Launcher script.
#
# can be called directly with 
# 'channel_name' 'streamsid' 'list' 'tvmaze_show_id'
#
#
# HLS / XMLTV Home broadcasting : https://github.com/deanochips/HLS-XMLTV---Home-Broadcasting
#
# AUTHOR				DATE			DETAILS
# --------------------- --------------- --------------------------------
# Dean Butler           2020-01-05      Initial version
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
# Call Config File
# --------------------------------------------------------------------------------------------------
cd $(dirname ${BASH_SOURCE[0]})
source ./config.cfg

# --------------------------------------------------------------------------------------------------
# define user defined working variables
# --------------------------------------------------------------------------------------------------
TVMAZE_SHOW_ID="${4:1:-1}"
CHANNEL_NAME="${1:1:-1}"
STREAMID="${2:1:-1}"

# --------------------------------------------------------------------------------------------------
# Tell user how to call script directly if arguments missing
# --------------------------------------------------------------------------------------------------
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
then
	echo "Its looks like you have not set any arguments, for a example see below: (note: \$TVMAZE_SHOW_ID is optional)"
	echo ""
	${ECHO} $red "$ bash ./stream_laucher.sh \"'CHANNEL_ID'\" \"'HOME_DIR'\" "'FFMPEG_CONCAT_LIST'"  \"'TVMAZE_SHOW_ID'\""
	echo ""
	${ECHO} $blue "Notice that the arguments are encased in both apostrophes and quotation mark"$yellow""
	echo ""
	echo "If you want to launch all streams simply start the cron.sh and it will pull all the info from the config.cfg file"
	echo "that is the expected use case, but you can launch individual streams with this script using the command above."
	echo ""
	exit
fi


# --------------------------------------------------------------------------------------------------
# lock file to stop multiple scripts running at once
# --------------------------------------------------------------------------------------------------
LOCK_FILE="$TMP_DIR"/"ffmpeg.lock"
if [ -f "$LOCK_FILE" ]; then
	# Lock file already exists, exit the script
	echo "An instance of this script is already running"
	echo "IF in error then you can simply remove - ""$TMP_DIR"/"ffmpeg.lock"
	exit 1
fi
# Create the lock file
echo "Locked" > "$LOCK_FILE"

# --------------------------------------------------------------------------------------------------
# Check if pid exists
# --------------------------------------------------------------------------------------------------

if [ ! -f "$PID_DIR"/"$CHANNEL_NAME"".pid" ]; then
	echo ""
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /-}
	echo -ne "First Start Detected, Creating...\033[31m$CHANNEL_NAME\033[0m"
	touch "$PID_DIR"/"$CHANNEL_NAME".pid
	chmod 777 "$PID_DIR"/"$CHANNEL_NAME".pid
fi

storedpid=$(<"$PID_DIR"/"$CHANNEL_NAME"".pid")

if ps -p $storedpid > /dev/null 2>&1
then

	sleep 0.01 && ${ECHO} "$green "
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /-}
	echo -e "\033[31m$CHANNEL_NAME\033[0m - PID found, Channel already running"

else
	sleep 0.01 && ${ECHO} "$green "
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /-}
	echo -e "\033[31m$CHANNEL_NAME\033[0m - PID not found, starting channel"


# --------------------------------------------------------------------------------------------------
# Concat List Advanced Processing "idents & randomize"
# --------------------------------------------------------------------------------------------------
# Add full path to file
if [[ "${3:1:-1}" == *\/* ]]
then
	CONCAT_FILE="${3:1:-1}"
else
	CONCAT_FILE="$CONCAT_LIST_DIR"/"${3:1:-1}"
fi

CONCAT_RENAME=$(basename "${CONCAT_FILE::-11}" ) 

case ${CONCAT_FILE:(-11)} #Get last 11 characters from string
	in
	"_random.txt")

	source ./plugins/randomize.sh "$CONCAT_RENAME"

	LIST=$TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_random.txt
	TYPE="RANDOMIZED"
	;;
"_idents.txt")

	source ./plugins/randomize_idents_only.sh "$CONCAT_RENAME"

	LIST=$TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_runningorder.txt
	TYPE="IDENTS"

	;;
*)
	LIST=$CONCAT_FILE
	TYPE="STANDARD"
	;;
esac


# --------------------------------------------------------------------------------------------------
# Main FFMPEG Launch command - Hint use htop to see whole command
# --------------------------------------------------------------------------------------------------
su -m $LAUNCH_USER -s /bin/bash -c ""$FFMPEG_BIN_LOCATION" -re -loglevel warning -fflags +genpts -f concat -safe 0 -i "$LIST" -map 0:a? -map 0:v? -strict -2 -dn -c copy -hls_flags delete_segments -hls_time "$HLS_TIME" -hls_list_size "$HLS_LIST_SIZE" "$STREAM_DIR"/"$STREAMID".m3u8 2>> "$FFMPEG_LOG_DIR"/ffmpeg_"$CHANNEL_NAME"_error.log & echo \$! >"$PID_DIR"/"$CHANNEL_NAME".pid"

sleep 10s

echo "Concat Used: ""$LIST"
echo "Concat Type: ""$TYPE"

# --------------------------------------------------------------------------------------------------
# Launching XMLTV Generation script
# --------------------------------------------------------------------------------------------------
echo "No" | source ./generate_epg.sh "$CHANNEL_NAME" "$HOME_DIR" "$LIST" "$TVMAZE_SHOW_ID" 2>> "$EPG_LOG_DIR"/epg_"$CHANNEL_NAME"_error.log

# echo "XMLTV Command: generate_epg.sh" "$CHANNEL_NAME" "$HOME_DIR" "$LIST" "$TVMAZE_SHOW_ID" 2>> "$EPG_LOG_DIR"/epg_"$CHANNEL_NAME"_error.log

echo "M3U8 File: ""$STREAM_HTTP_DIR"/"$STREAMID".m3u8


updatedstoredpid=$(<"$PID_DIR"/"$CHANNEL_NAME"".pid");
echo -e "PID File: "$updatedstoredpid;
timestamp=$(date +%s);


fi
rm "$LOCK_FILE"
