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

CONCAT_RENAME="$1"


touch $TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_idents.txt
touch $TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_runningorder.txt
chmod 777 $TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_idents.txt
chmod 777 $TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_runningorder.txt

if [ ! -f "$CACHE_DIR"/"$CONCAT_RENAME"_idents_cache.txt ];
then
	# Used On First Start before any caching has been done
	shuf $CONCAT_FILE  -o $TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_idents.txt

	rm $CONCAT_LIST_DIR"/""$CONCAT_RENAME"_idents.txt > /dev/null 2>&1
	cp $TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_idents.txt  $CONCAT_LIST_DIR"/""$CONCAT_RENAME"_idents.txt



	awk '{print}NR%2==0{getline<"'${CONCAT_FILE::-11}'.txt";print}' $TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_idents.txt > $TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_both_merged.txt

# Remove Dupes Awk command above has stange behaviour and some times includes a couple of dupes at end of file
cat ""$TMP_TVLISTS_DIR"/"$CONCAT_RENAME"_both_merged.txt" | uniq > ""$TMP_TVLISTS_DIR"/"$CONCAT_RENAME"_runningorder.txt"


rm $CONCAT_LIST_DIR"/""$CONCAT_RENAME"_runningorder.txt > /dev/null 2>&1
cp $TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_runningorder.txt  $CONCAT_LIST_DIR"/""$CONCAT_RENAME"_runningorder.txt


else


	cp $CONCAT_LIST_DIR"/""$CONCAT_RENAME"_idents.txt  $TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_idents.txt



# Join Idents Concat and Idents Cache and shuffle
paste -d "~" $TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_idents.txt $CACHE_DIR"/""$CONCAT_RENAME"_idents_cache.txt | shuf > "$TMP_TVLISTS_DIR""/""$CONCAT_RENAME"_idents_concat_cache_merged.txt

# Join show Concat and Idents show  NO shuffle
paste -d "~" $CONCAT_LIST_DIR"/""$CONCAT_RENAME".txt $CACHE_DIR"/""$CONCAT_RENAME"_cache.txt > "$TMP_TVLISTS_DIR""/""$CONCAT_RENAME"_concat_cache_merged.txt

# Mix Idents and Show every 2 lines
awk '{print}NR%2==0{getline<"'$TMP_TVLISTS_DIR'/'$CONCAT_RENAME'_concat_cache_merged.txt";print}' ""$TMP_TVLISTS_DIR"/"$CONCAT_RENAME"_idents_concat_cache_merged.txt" > ""$TMP_TVLISTS_DIR"/"$CONCAT_RENAME"_both_merged.txt"

# Remove Dupes Awk command above has stange behaviour and some times includes a couple of dupes at end of file
cat ""$TMP_TVLISTS_DIR"/"$CONCAT_RENAME"_both_merged.txt" | uniq > ""$TMP_TVLISTS_DIR"/"$CONCAT_RENAME"_both_merged_de-duped.txt"

# Split Concat and Cache back into files 
cat $TMP_TVLISTS_DIR/$CONCAT_RENAME"_both_merged_de-duped.txt" | awk -v FS='~' '{print $1 > '\"''$(echo $TMP_TVLISTS_DIR/$CONCAT_RENAME)'_runningorder.txt'\"' ; print $2 > '\"''$(echo $TMP_TVLISTS_DIR/$CONCAT_RENAME)'_runningorder_cache.txt'\"' ; }' 

mv "$CONCAT_LIST_DIR""/""$CONCAT_RENAME"_runningorder.txt "$CONCAT_LIST_DIR""/""$CONCAT_RENAME"_runningorder.txt.backup
mv "$CACHE_DIR""/""$CONCAT_RENAME"_runningorder_cache.txt "$CACHE_DIR""/""$CONCAT_RENAME"_runningorder_cache.txt.backup

cp "$TMP_TVLISTS_DIR""/""$CONCAT_RENAME"_runningorder.txt "$CONCAT_LIST_DIR""/""$CONCAT_RENAME"_runningorder.txt
cp "$TMP_TVLISTS_DIR""/""$CONCAT_RENAME"_runningorder_cache.txt "$CACHE_DIR""/""$CONCAT_RENAME"_runningorder_cache.txt


fi


# cleanup files
rm $TMP_TVLISTS_DIR/$CONCAT_RENAME"_idents_concat_cache_merged.txt"  > /dev/null 2>&1
rm $TMP_TVLISTS_DIR/$CONCAT_RENAME"_both_merged_de-duped.txt" > /dev/null 2>&1
rm $TMP_TVLISTS_DIR/$CONCAT_RENAME"_both_merged.txt" > /dev/null 2>&1
rm $TMP_TVLISTS_DIR/$CONCAT_RENAME"_concat_cache_merged.txt" > /dev/null 2>&1
rm $TMP_TVLISTS_DIR/$CONCAT_RENAME"_idents_cache.txt" > /dev/null 2>&1
rm $TMP_TVLISTS_DIR/$CONCAT_RENAME"_idents.txt" > /dev/null 2>&1
rm $TMP_TVLISTS_DIR/$CONCAT_RENAME"_cache.txt" > /dev/null 2>&1
rm $TMP_TVLISTS_DIR/$CONCAT_RENAME".txt" > /dev/null 2>&1
rm $TMP_TVLISTS_DIR/$CONCAT_RENAME"_runningorder_cache.txt" > /dev/null 2>&1
