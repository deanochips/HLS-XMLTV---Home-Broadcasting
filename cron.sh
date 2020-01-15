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
# HLS / XMLTV Home broadcasting 
# Cron script.
#
# HLS / XMLTV Home broadcasting : https://github.com/deanochips/HLS-XMLTV---Home-Broadcasting
#
# AUTHOR				DATE			DETAILS
# --------------------- --------------- --------------------------------
# Dean Butler           2020-01-05      Initial version
# --------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------

if [ "$1" = "CRON_USER" ];
then 
SPLASH_RUN_YET="yes"
fi

# --------------------------------------------------------------------------------------------------
# Call Config File
# --------------------------------------------------------------------------------------------------

cd $(dirname ${BASH_SOURCE[0]})
source ./config.cfg

# --------------------------------------------------------------------------------------------------
# FLOCK stopping multiple calls
# --------------------------------------------------------------------------------------------------
SCRIPT_NAME="cron"
SCRIPT_BIN="$(basename $0)"
LOCK_FILE="/${TMP_DIR}/${SCRIPT_BIN}.pid"
(
    # Check for the lock on $LOCK_FILE (fd 200) or exit
    flock -xn 200 || {
    if [ "$1" = "CRON_USER" ];
    then 
        logger -t crond.stop "$SCRIPT_NAME Script had FLock. Check running was $CHECK_RUNNING. Aborted this instance."
	else
	echo "$SCRIPT_NAME is already locked."
	fi
        exit 1
    }
    #No lock, OK, let's go on
    echo $$ 1>&200
    trap cleanup INT TERM EXIT QUIT KILL STOP # call cleanup() if script exits
    cleanup() {
          flock -u 200
    }

# --------------------------------------------------------------------------------------------------
# functions
# --------------------------------------------------------------------------------------------------
function generate_m3u {

	rm "$M3U_DIR"/"streams.m3u"
	echo "#EXTM3U HLS / XMLTV Home broadcasting" >> "$M3U_DIR"/"streams.m3u"

	for args in "${arg_array[@]}"
	do
		vars=( $args )
		echo '#EXTINF:-1 tvg-ID="'${vars[0]:1:-1}.tv'" tvg-name="'${vars[0]:1:-1}'" tvg-logo="" group-title="" ,"'${vars[0]:1:-1}'"'  >> "$M3U_DIR"/"streams.m3u"
		echo "$STREAM_HTTP_DIR"/"${vars[1]:1:-1}"".m3u8" >> "$M3U_DIR"/"streams.m3u"
	done

	touch -r ./config.cfg "$M3U_DIR"/"streams.m3u" # matching config and m3u files dates to detect changes to config.cfg and regen the m3u
	sleep 0.01 && ${ECHO} "$cyan "
	echo -e "Channel is running, regenerating epg"
	sleep 0.01 && ${ECHO} "$BYellow "
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /=}
	echo -e "M3U & XMLTV GENERATED"
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /=}

	echo "M3U FOLDER: ""$M3U_DIR"/"streams.m3u" 
	echo "M3U URL: ""$M3U_HTTP_DIR"/"streams.m3u"
	echo "XMLTV FOLDER: ""$XMLTV_DIR"/"xmltv.xml"
	echo "XMLTV URL: ""$XMLTV_HTTP_DIR"/"xmltv.xml"
	sleep 0.01 && ${ECHO} "$transparent "

}




for args in "${arg_array[@]}"
do
	source ./stream_laucher.sh $args
	#source ./gentest.sh $args

done


if [ "$CLEAN_STREAM_DIR" = "ON" ]
then
	find $STREAM_DIR  \( -name "*.m3u8" -o -name "*.ts" \) -type f -mmin +$STREAM_CLEANUP_TIME -exec rm -f {} +
	fi



	if [ "$M3U_DIR"/"streams.m3u" -ot "./config.cfg" ] # check if config it newer than m3u 
	then
	generate_m3u
	fi
	
		
    exit 0
) 200>"$LOCK_FILE"
