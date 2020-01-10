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
# Plugin Script.
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
cd ..

source ./config.cfg

CONCAT_NAME_TRIMMED=$1

# start IDENT functions write two files for series and idents that can be used for quick launching channels with random idents

if [ -f "$CONCAT_LIST_DIR"/"$CONCAT_NAME_TRIMMED"_idents.txt ]; then
	echo "IDENTS: Concat Files Detected"



# if its not already in tmp folder then copy it there
# copy show concat  to tmpfs
if [ ! -f "$TMP_TVLISTS_DIR"/"$CONCAT_NAME_TRIMMED".txt ]; then cp "$CONCAT_LIST_DIR"/"$CONCAT_NAME_TRIMMED".txt "$TMP_TVLISTS_DIR"/"$CONCAT_NAME_TRIMMED".txt; fi
if [ ! -f "$TMP_TVLISTS_DIR"/"$CONCAT_NAME_TRIMMED"_runningorder_cache.txt ]; then cp "$CACHE_DIR"/"$CONCAT_NAME_TRIMMED"_runningorder_cache.txt "$TMP_TVLISTS_DIR"/"$CONCAT_NAME_TRIMMED"_runningorder_cache.txt; fi
rm "$CACHE_DIR"/"$CONCAT_NAME_TRIMMED"_cache.txt
rm "$CACHE_DIR"/"$CONCAT_NAME_TRIMMED"_idents_cache.txt

while read RUNNING_ORDER_LINE; do

 # cat "$TMP_TVLISTS_DIR"/"$CONCAT_NAME_TRIMMED"_runningorder_cache.txt | while read RUNNING_ORDER_LINE; do

 EXRACTED_FILENAME=$(echo "$RUNNING_ORDER_LINE" | cut -d ':' -f 4 |  sed -r "s|'|'\\\''|g")

 EXRACTED_FILENAME_WO_EXT="${EXRACTED_FILENAME%.*}"



 if [ ! -z "$EXRACTED_FILENAME_WO_EXT" ] 
 then
	 if grep -Fq "$EXRACTED_FILENAME_WO_EXT" "$TMP_TVLISTS_DIR"/"$CONCAT_NAME_TRIMMED".txt
	 then
		 #echo -ne "STANDARD cache" "$TMP_TVLISTS_DIR"/"$CONCAT_NAME_TRIMMED"_cache.txt
		 #echo -ne "STANDARD cache" "$CONCAT_NAME_TRIMMED"_cache.txt" - "

		 echo -e "$RUNNING_ORDER_LINE" >> "$TMP_TVLISTS_DIR"/"$CONCAT_NAME_TRIMMED"_cache.txt # write to cache file
	 else
		 # echo "IDENTS cache" "$TMP_TVLISTS_DIR"/"$CONCAT_NAME_TRIMMED"_idents_cache.txt
		 #echo -ne "IDENTS cache" "$CONCAT_NAME_TRIMMED"_cache.txt" - "

		 echo -e "$RUNNING_ORDER_LINE" >> "$TMP_TVLISTS_DIR"/"$CONCAT_NAME_TRIMMED"_idents_cache.txt # write to cache file
fi
fi
echo "$EXRACTED_FILENAME_WO_EXT"


done < "$TMP_TVLISTS_DIR"/"$CONCAT_NAME_TRIMMED"_runningorder_cache.txt

rm "$CACHE_DIR"/"$CONCAT_NAME_TRIMMED"_cache.txt
rm "$CACHE_DIR"/"$CONCAT_NAME_TRIMMED"_cache.txt

cp "$TMP_TVLISTS_DIR"/"$CONCAT_NAME_TRIMMED"_cache.txt "$CACHE_DIR"/"$CONCAT_NAME_TRIMMED"_cache.txt
cp "$TMP_TVLISTS_DIR"/"$CONCAT_NAME_TRIMMED"_idents_cache.txt "$CACHE_DIR"/"$CONCAT_NAME_TRIMMED"_idents_cache.txt

fi
# end IDENT functions
