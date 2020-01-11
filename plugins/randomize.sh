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


# detect if cached randomized file exists, join to existing randomized concat and randomize again
if [ ! -f $CACHE_DIR/$CONCAT_RENAME"_random_cache.txt" ];
then
	# echo "not found"
	touch $TMP_TVLISTS_DIR/$CONCAT_RENAME.txt
	chmod 777 $TMP_TVLISTS_DIR/$CONCAT_RENAME.txt

	shuf "$CONCAT_FILE"  -o "$TMP_TVLISTS_DIR""/""$CONCAT_RENAME"_random.txt

else

# Detect First Run after system restart and copy concat file to tmpfs
if [ ! -f $TMP_TVLISTS_DIR/$CONCAT_RENAME"_random.txt" ];
then
	cp $CONCAT_LIST_DIR/$CONCAT_RENAME"_random.txt" $TMP_TVLISTS_DIR/$CONCAT_RENAME"_random.txt"
	chmod 777 $TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_random.txt
fi

#Merge Concat and Cache
paste -d "~" "$TMP_TVLISTS_DIR""/""$CONCAT_RENAME"_random.txt "$CACHE_DIR""/""$CONCAT_RENAME"_random_cache.txt | shuf > "$TMP_TVLISTS_DIR""/""$CONCAT_RENAME"_concat_cache_merged.txt

#In place shuffle
shuf $TMP_TVLISTS_DIR/$CONCAT_RENAME"_concat_cache_merged.txt"  -o $TMP_TVLISTS_DIR/$CONCAT_RENAME"_concat_cache_merged.txt"

mv "$CONCAT_LIST_DIR""/""$CONCAT_RENAME"_random.txt "$CONCAT_LIST_DIR""/""$CONCAT_RENAME"_random.txt.backup
mv "$CACHE_DIR""/""$CONCAT_RENAME"_random_cache.txt "$CACHE_DIR""/""$CONCAT_RENAME"_random_cache.txt.backup

#Split the result
cat $TMP_TVLISTS_DIR/$CONCAT_RENAME"_concat_cache_merged.txt" | awk -v FS='~' '{print $1 > '\"''$(echo $TMP_TVLISTS_DIR/$CONCAT_RENAME)'_random.txt'\"' ; print $2 > '\"''$(echo $TMP_TVLISTS_DIR/$CONCAT_RENAME)'_random_cache.txt'\"' ; }' 



cp "$TMP_TVLISTS_DIR""/""$CONCAT_RENAME"_random.txt "$CONCAT_LIST_DIR""/""$CONCAT_RENAME"_random.txt

chmod 777 $TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_random.txt
chmod 777 $TMP_TVLISTS_DIR"/""$CONCAT_RENAME"_concat_cache_merged.txt

touch -r $CONCAT_FILE $CACHE_DIR/$CONCAT_RENAME"_random_cache.txt" # matching concat & cache file dates so we can detect changes in future


# Cleanup

rm $TMP_TVLISTS_DIR/$CONCAT_RENAME"_concat_cache_merged.txt" > /dev/null 2>&1
rm $TMP_TVLISTS_DIR/$CONCAT_RENAME".txt" > /dev/null 2>&1

fi
