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
# XMLTV epg generation script.
#
# it works as a sub script to the main scipt,
# but it can be called directly if for example
# you have a custom JSON file and want to 
# regenerate the EPG on a running channel
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

# --------------------------------------------------------------------------------------------------
# define user defined working variables
# --------------------------------------------------------------------------------------------------
CHANNEL_ID="$1"
MOVIEFOLDER="$2"
FFMPEG_CONCAT_LIST="$3"
TVMAZE_SHOW_ID="$4"

# --------------------------------------------------------------------------------------------------
# Extended variables (do not edit unless you know what your doing)
# --------------------------------------------------------------------------------------------------
XMLTV_FILENAME="$XMLTV_DIR"/"$CHANNEL_ID.xml"
PID_FULLPATH="$PID_DIR"/"$CHANNEL_ID.pid";
LISTNAME=$(basename "$FFMPEG_CONCAT_LIST" )
FFPROBE_SLEEPTIME="2" # This is to control the requests to the harddrive to stop it hammering it and effecting runnung streams

CHANNELNAME="$CHANNEL_ID.tv"
CHANNELLANG="en"
TIMEZONE="+0000"

CACHE_FILE_FULLPATH="$CACHE_DIR"/"${LISTNAME%.*}"_cache.txt

case ${FFMPEG_CONCAT_LIST:(-11)} #Get last 11 characters from string
	in
	"_random.txt")
CONCAT_NAME_TRIMMED=${LISTNAME:0:-17}
	;;
"_idents.txt")
CONCAT_NAME_TRIMMED=${LISTNAME:0:-17}
	;;
*)
CONCAT_NAME_TRIMMED=${LISTNAME%.*}
	;;
esac

# --------------------------------------------------------------------------------------------------
# Enable extended globing (closed once script has run)
# --------------------------------------------------------------------------------------------------
shopt -s extglob


# --------------------------------------------------------------------------------------------------
# Tell user how to call script directly if arguments missing
# --------------------------------------------------------------------------------------------------
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
then
	echo "Its looks like you have not set any arguments, for a example see below: (note: \$TVMAZE_SHOW_ID is optional)"
	echo '$ bash generate_epg.sh "CHANNEL_ID"  "HOME_DIR"/ "FFMPEG_CONCAT_LIST" "TVMAZE_SHOW_ID"'
	exit
	fi


# --------------------------------------------------------------------------------------------------
# Check show running, and regenerating epg if it is
# --------------------------------------------------------------------------------------------------
PID_RUNNING_TIME_CHECK=$(ps -p $(cat "$PID_FULLPATH") -o etimes | sed '2q;d' | sed "s/ //g")

if ps -p $(cat "$PID_FULLPATH") > /dev/null && [[ "$PID_RUNNING_TIME_CHECK" -gt 30 ]]
then

	sleep 0.01 && ${ECHO} "$cyan "
	echo -e "Channel is running, regenerating epg"
	sleep 0.01 && ${ECHO} "$green "


# Extracting running channel start time info from existing XMLTV file
CURRENTTIME=$(cat "$XMLTV_DIR"/$CHANNEL_ID".xml" | sed -n 8p | cut -d '"' -f 2 | sed 's/^\(.\{4\}\)/\1-/'| sed 's/^\(.\{7\}\)/\1-/'| sed 's/^\(.\{10\}\)/\1 /'| sed 's/^\(.\{13\}\)/\1:/' | sed 's/^\(.\{16\}\)/\1:/')
else
	CURRENTTIME=$(date -u +'%Y-%m-%d %H:%M:%S')
fi

# --------------------------------------------------------------------------------------------------
# XMLTV Building functions
# --------------------------------------------------------------------------------------------------
function header {
	echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>" > "$XMLTV_FILENAME"
	echo "<!DOCTYPE tv SYSTEM \"xmltv.dtd\">" >> "$XMLTV_FILENAME"
	echo '<tv>' >> "$XMLTV_FILENAME"
}

function channel {

	CHANNELNAME=${CHANNELNAME//&/und}

	echo "<channel id=\"$CHANNELNAME\">" >> "$XMLTV_FILENAME"
	echo "<display-name lang=\"$CHANNELLANG\">$CHANNELNAME</display-name>" >> "$XMLTV_FILENAME"
	echo "</channel>" >> "$XMLTV_FILENAME"
	echo "" >> "$XMLTV_FILENAME"
}

function program {

	CHANNELNAME=${CHANNELNAME//&/und}
	PROGRAMNAME=${PROGRAMNAME//&/und}
	PROGRAMSUBNAME=${PROGRAMSUBNAME//&/und}
	PROGRAMDESCRIPTION=${PROGRAMDESCRIPTION//&/und}

	echo "<programme start=\"$PROGRAMSTART $TIMEZONE\" stop=\"$PROGRAMEND $TIMEZONE\" channel=\"$CHANNELNAME\">" >> "$XMLTV_FILENAME"
	echo "<title lang=\"$PROGRAMLANG\">$PROGRAMNAME</title>" >> "$XMLTV_FILENAME"
	echo "<sub-title lang=\"$PROGRAMLANG\">$PROGRAMSUBNAME</sub-title>" >> "$XMLTV_FILENAME"
	echo "<desc lang=\"$PROGRAMLANG\">" >> "$XMLTV_FILENAME"
	echo "$PROGRAMDESCRIPTION" >> "$XMLTV_FILENAME"
	echo "</desc>" >> "$XMLTV_FILENAME"
	echo "</programme>" >> "$XMLTV_FILENAME"
}

function footer {
	echo '</tv>' >> "$XMLTV_FILENAME"
}

function generateepg {

	rm "$XMLTV_FILENAME"

	header
	channel

	cat "$CACHE_FILE_FULLPATH" | while read CACHE_LINE; do

	HOURS=$(echo "$CACHE_LINE" | cut -d ':' -f 1)
	MINUTES=$(echo "$CACHE_LINE" | cut -d ':' -f 2)
	SECONDS=$(echo "$CACHE_LINE" | cut -d ':' -f 3)
	FILENAME=$(echo "$CACHE_LINE" | cut -d ':' -f 4)
	LINENAME=$(echo "$CACHE_LINE" | cut -d ':' -f 5 | sed -r "s|_| |g")
	LINESUMMERY=$(echo "$CACHE_LINE" | cut -d ':' -f 6 | sed -r "s|_| |g" | sed 's/<[^>]*>/\n/g')
	LINEIMAGE=$(echo "$CACHE_LINE" | cut -d ':' -f 7)


	if [ -z "$LINESUMMERY" ]
	then
		PROGRAMNAME="${FILENAME%.*}"
		PROGRAMDESCRIPTION="${FILENAME%.*}"
		PROGRAMSUBNAME="${FILENAME%.*}"
	else
		PROGRAMNAME="$LINENAME"
		PROGRAMDESCRIPTION=$LINESUMMERY
		PROGRAMSUBNAME="${FILENAME%.*}"
		fi

		PROGRAMLANG="$CHANNELLANG"
		PROGRAMSTART="$(date -d "$CURRENTTIME" +'%Y%m%d%H%M%S')"
		CURRENTTIME=$(date -d "$CURRENTTIME $HOURS hours $MINUTES minutes $SECONDS seconds" +'%Y-%m-%d %H:%M:%S')
		PROGRAMEND="$(date -d "$CURRENTTIME" +'%Y%m%d%H%M%S')"
		program
	done
	footer
}

function get_json_file {
	if [ -f '$CACHE_DIR'/'$CHANNEL_ID''.json' ];
	then
		${ECHO} "$blue "
		echo -e "JSON: Found"
		${ECHO} "$green "

	else

		if [ -z "$TVMAZE_SHOW_ID" ]
		then
			echo "\$TVMAZE_SHOW_ID is empty"
		else
			echo -ne "$blue "
			echo -e "JSON: Not Found"
			echo -ne "$green "
			# echo -ne " - Creating......"

	# TODO: add TVDB support https://thetvdb.com/api/B89CE93890E9419B/series/72248/all/en.xml

	wget "http://api.tvmaze.com/shows/"$TVMAZE_SHOW_ID"/episodes" -O ""$CACHE_DIR"/"$CHANNEL_ID".json.tmp"
	$PYTHON -m json.tool ""$CACHE_DIR"/"$CHANNEL_ID".json.tmp" >>""$CACHE_DIR"/"$CHANNEL_ID".json"
	sleep 2
	rm "$CACHE_DIR"/"$CHANNEL_ID"".json.tmp"



	# echo "Please wait......"
	sleep 0.01 && ${ECHO} "$BPurple"
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /-}	
	sleep 0.01 && ${ECHO} "$green "

	sleep 3
	fi

	fi
}

function extract_metadata {
	echo -e "$BBlue "
	echo -e "Building Metadata:"
	echo -ne "$white "

	M=0   # start loop counter
	cat "$CACHE_FILE_FULLPATH" | while read LINE; do
	M=$((M + 1))  # loop counter
	GET_EPISODE=$(echo "$LINE" | sed -r "s|.*([Ee]([0-9].{1,2})).*|\1|g")
	GET_SEASON=$(echo "$LINE" | sed -r "s|.*([Ss]([0-9].{1,2})).*|\1|g")
	SEASON=$(echo ${GET_SEASON:1:-1} | sed 's/^0*//')
	EPISODE=$(echo ${GET_EPISODE:1:-1} | sed 's/^0*//')


	cat "$CACHE_DIR"/$CHANNEL_ID".json" > "$TMP_DIR"/$CHANNEL_ID".json"
	if (($EPISODE >= 1 && number <= 999)); then

	  #jq v1.3 fix create temp json file  in 1.5, could be done with a variable in later verson
	  touch "$TMP_DIR"/"tmp.json"
	  json= echo $(cat "$CACHE_DIR"/"$CHANNEL_ID"".json" | jq '.[] | select(.season == '$SEASON' and .number == '$EPISODE') | .') > "$TMP_DIR"/"tmp.json"

	  JSON_NAME=$(jq -r '.name' <<< cat "$TMP_DIR"/"tmp.json" 2>/dev/null)
	  JSON_SUMMARY=$(jq -r '.summary' <<< cat "$TMP_DIR"/"tmp.json" 2>/dev/null)
	  JSON_AIRDATE=$(jq -r '.airdate' <<< cat "$TMP_DIR"/"tmp.json" 2>/dev/null)
	  JSON_IMAGE=$(jq -r '.image .original' <<< "$TMP_DIR"/"tmp.json" 2>/dev/null)
	  
      # remove html code from summary
      SUMMARY=$(echo $JSON_SUMMARY | sed -r 's;</p>;\n;g' |sed -r 's;<p>;;g'| sed -r "s|:| - |g")

      METADATA=$(echo ":"$JSON_NAME":"$SUMMARY":"$JSON_AIRDATE":"$JSON_IMAGE | sed -r "s|http://||g" | sed -r "s|'|\x27|g" | sed -r "s| |_|g" | sed -r "s|/|\/|g")

      sed -i ''$M's;$;'$METADATA';' "$CACHE_FILE_FULLPATH"
      echo "Parsing: $JSON_NAME"
      rm "$TMP_DIR"/"tmp.json"
else
	echo "Match Not Found - Using Filename"
	fi

	rm "$TMP_DIR"/"$CHANNEL_ID"".json"
done


if [ "${FFMPEG_CONCAT_LIST:(-17)}" = "_runningorder.txt" ]; then

	 # only required for spliting cache for channels with idents for everthing else it does nothing and can be removed if not used
	 source ./plugins/split_finished_cache_file.sh "$CONCAT_NAME_TRIMMED" 2>> "$CACHE_SPLITTER_LOG_DIR"/split_"$CHANNEL_NAME"_error.log

fi

}


# --------------------------------------------------------------------------------------------------
# Caching functions, to save needlessly reprobing video files
# --------------------------------------------------------------------------------------------------
function build_cache {
	echo -e "$BBlue "
	echo -e "Building Cache:"
	echo -ne "$white "
	cp $CACHE_FILE_FULLPATH "$TMP_TVLISTS_DIR"/"${LISTNAME%.*}"_cache.txt
	TMP_CACHE_FILE_FULLPATH="$TMP_TVLISTS_DIR"/"${LISTNAME%.*}"_cache.txt

	IFS=$'\n'
	I=0  # start loop counter
	while read P <&3; do
		I=$((I + 1))   # loop counter

		if [[ $P = \#* ]] ; then
			# Ignoring lines with a hash # to mirror the behaviour of ffmpeg
					echo "# Detected Skipping..."
				else
					FILE=$(echo "${P:6:-1}" | sed "s/'''/'/g" | sed -r "s|'(.{1})'|\1|g")
					FILENAME=$(basename "$FILE" )

					if [ -f "$FILE" ]; then
						FILENAME_WO_EXT=${FILENAME%.*}
						VIDEO_DURATION=$(ffprobe -i "$FILE" -show_entries format=duration -v quiet -of csv="p=0" -sexagesimal)
						VIDEO_DURATION=$(echo "$VIDEO_DURATION" | cut -d '.' -f 1)

						echo "$VIDEO_DURATION"":""$FILENAME_WO_EXT" >> "$TMP_CACHE_FILE_FULLPATH" # write to cache file

						echo "Probing file number "$I" - "$FILENAME" for duration - ( "$VIDEO_DURATION" )"
						sleep "$FFPROBE_SLEEPTIME"s
					else
						echo "File " $FILENAME " Missing, commenting out"
						sed -i ''$I's/^/#/' $FFMPEG_CONCAT_LIST
					fi
					fi


				done 3< $FFMPEG_CONCAT_LIST
				cp "$TMP_TVLISTS_DIR"/"${LISTNAME%.*}"_cache.txt $CACHE_FILE_FULLPATH
				rm "$TMP_TVLISTS_DIR"/"${LISTNAME%.*}"_cache.txt

				touch -r $FFMPEG_CONCAT_LIST $CACHE_FILE_FULLPATH # matching concat & cache file dates so we can detect changes in future

			}

# TODO: create function to remove metadata from cache file and so it can be passed back to the function "extract_metadata" to get fresh data 

# --------------------------------------------------------------------------------------------------
# User Input on JSON handling on EPG Regeneration
# --------------------------------------------------------------------------------------------------
while true
do
	read -r -p "Do you wish delete the cached files for "$1"? [Y/n] " input
	case $input in
		[yY][eE][sS]|[yY])
			echo -e "Delete Cache: Yes" &
			rm "$CACHE_DIR"/"$CHANNEL_ID"".json"  2>/dev/null;
			rm "$CACHE_FILE_FULLPATH"  2>/dev/null;
			rm "$CACHE_DIR"/"${LISTNAME%.*}"_runningorder.txt > /dev/null 2>&1
			rm "$CACHE_DIR"/"${LISTNAME%.*}}"_cache.txt > /dev/null 2>&1
			break 
			;;
		[nN][oO]|[nN])
			echo -e "Delete Cache: No" &
			break 
			;;
		*)
			echo "Invalid input..."
			;;
	esac
done


# TODO: User input on handling cache file (removing meta data but reusing existing saved ffprobe duration info)


# --------------------------------------------------------------------------------------------------
# Body of script
# --------------------------------------------------------------------------------------------------
if [ ! -f "$CACHE_DIR"/"$CHANNEL_ID"".json" ]; # download Json if missing
then 
	echo "JSON File: Does Not Exist"
	get_json_file
else
	echo "JSON File: Exists"
fi

					if [ ! -f "$CACHE_FILE_FULLPATH" ] || [ "$CACHE_FILE_FULLPATH" -ot "$FFMPEG_CONCAT_LIST" ] # Rebuild cache if missing or concat file updated
					then
						rm "$CACHE_FILE_FULLPATH"  2>/dev/null
						echo "Cache File: Does Not Exist"
						build_cache
						echo "Metadata: Does Not Exist"
						extract_metadata
					else
						echo "Cache File: Exists"
						echo "Metadata: File Exists"
					fi

					generateepg

# --------------------------------------------------------------------------------------------------
# Merge all XMLTV files
# ---------------------
# notes:
#
# if you have xmltv-util installed:
#
# you can use tv_cat to merge xmltv files:
# $ tv_cat !(xmltv.xml)   > xmltv.xml
#
# And tv_validate_file to check files for errors
# $ tv_validate_file xmltv.xml 2>/dev/null
# --------------------------------------------------------------------------------------------------

cat $XMLTV_DIR/!(xmltv.xml) | $PYTHON "$PLUGIN_DIR"/xmltv-join > $XMLTV_DIR/xmltv.xml


shopt -u extglob # disable extended globing
echo "XMLTV File: "$XMLTV_FILENAME

# IF TVheadend Link detected push EPG data to it
if [[ -e "/epggrab/xmltv.sock" ]]; then
cat $XMLTV_DIR/xmltv.xml | socat - UNIX-CONNECT:/epggrab/xmltv.sock
fi


