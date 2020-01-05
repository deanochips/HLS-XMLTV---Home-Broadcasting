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
# XMLTV Clear Cache.
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

countdown () {
	sleep 1 && ${ECHO} -ne "5..."
	sleep 1 && ${ECHO} -ne "4..."
	sleep 1 && ${ECHO} -ne "3..."
	sleep 1 && ${ECHO} -ne "2..."
	sleep 1 && ${ECHO} -ne "1"
}

purge_cache_of () {

	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /-}
	echo ""

	case $1 in
		[eE][xX][iI][tT])
			${ECHO} "$Color_Off "
			clear
			exit 
			;;
		[aA][lL][lL])

			echo "	Json) Clear Json Cache"
			echo "	Metadata) Clear Metadata Cache"
			echo "	Both) Clear Both Cache"
			echo ""

			printf -v _hr "%*s" $(tput cols) && echo ${_hr// /-}

			local choice
			read -p "Enter choice: " options

			case $options in
				[jJ][sS][oO][nN])
					rm "$CACHE_DIR"/*.json
					echo "All Cached JSON Deleted";;
				[mM][eE][tT][aA][dD][aA][tT][aA])
					rm "$CACHE_DIR"/*_cache.txt
					echo "All Cached Metadata Deleted";;
				[bB][oO][tT][hH])
					rm "$CACHE_DIR"/*_cache.txt
					rm "$CACHE_DIR"/*.json
					echo "Both Deleted"
					;;
				*)
					echo "Invalid entry reseting script."
					;;
			esac

			;;
		*)
			if [[ "$1" =~ ^[0-9]+$ ]]
			then
				split=( ${arg_array[ $1 ]} )

				if ! [ -z "${split[0]:1:-1}" ]
				then

					echo "	Json) Clear Json Cache for ""${split[0]:1:-1}"
					echo "	Metadata) Clear Metadata Cache for ""${split[0]:1:-1}"
					echo "	Both) Clear Both Cache for ""${split[0]:1:-1}"				
					echo ""

					printf -v _hr "%*s" $(tput cols) && echo ${_hr// /-}

					local choice
					read -p "Enter choice: " options

					case $options in
						[jJ][sS][oO][nN])
							rm "$CACHE_DIR"/"${split[0]:1:-1}"".json"
							echo "JSON Deleted";;


						[mM][eE][tT][aA][dD][aA][tT][aA])

							rm "$CACHE_DIR"/"${split[2]:1:-5}"_cache.txt
							rm "$CACHE_DIR"/"${split[2]:1:-12}"_runningorder_cache.txt > /dev/null 2>&1
							rm "$CACHE_DIR"/"${split[2]:1:-12}"_cache.txt > /dev/null 2>&1
							echo "Metadata Deleted";;

						[bB][oO][tT][hH])
							rm "$CACHE_DIR"/"${split[2]:1:-5}"_cache.txt
							rm "$CACHE_DIR"/"${split[2]:1:-12}"_runningorder_cache.txt > /dev/null 2>&1
							rm "$CACHE_DIR"/"${split[2]:1:-12}"_cache.txt > /dev/null 2>&1
							rm "$CACHE_DIR"/"${split[0]:1:-1}"".json"
							echo "Both Deleted"
							;;
						*)
							echo "Invalid entry reseting script."
							;;
					esac

					fi
					fi
					;;
			esac
			countdown
			clear
			unset $SPLASH_RUN_YET
			load_splash_screen
		}

	menu_items() {
		M=0   # start loop counter
		for args in "${arg_array[@]}"
		do
			vars=( $args )
			echo "	"$M") ""${vars[0]:1:-1}"
			M=$((M + 1))  # loop counter
		done
	}

show_menus() {
	sleep 0.01 && ${ECHO} "$green "
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /-}
	sleep 0.01 && ${ECHO} -ne "$BGreen "
	echo -ne "\033[1mCLEAR CACHE\033"
	sleep 0.01 && ${ECHO} "$green "
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /-}
	echo ""
	menu_items
	echo ""
	echo "	All) Clear All Cache"
	echo "	Exit) To Exit"
	echo ""

}

read_options(){
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /-}
	local choice
	read -p "Enter choice: " choice
	purge_cache_of $choice
}


while true
do
	show_menus
	read_options
done
