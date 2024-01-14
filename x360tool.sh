#!/bin/bash
#
# @desc:	Check http://primepage.de/x360tool/
#
# @name:	x360tool(.sh)
#
# @author:	Alexander Hagenah <ah@primepage.de>
#		http://primepage.de
#
# @created:	09/29/2009

# VARIABLES / feel free to change
ABGX="/home/xaitax/tools/abgx360/abgx360" # binary of abgx!
BURNSPEED="2"
LOGFILE="$(pwd)/log.txt"

# PARAMS
DEVICE="$1"
IMAGE="$2"
OPTION=""
FILESIZE=""

# COLOURS
C_RED='\e[0;31m'
C_GREEN='\e[0;32m'
C_BLUE='\e[0;34m'
C_WHITEBOLD='\e[1;37m'
C_NC='\e[0m'

if [[ -z "$1" || -z "$2" ]]; then
	echo -e "$C_BLUE"
	echo -e "            ________   _______________   __                .__    "
	echo -e "    ___  ___\_____  \ /  _____/\   _  \_/  |_  ____   ____ |  |   "
	echo -e "    \  \/  /  _(__  </   __ \  /  /_\  \   __\/  _ \ /  _ \|  |   "
	echo -e "     >    <  /       \  |__\ \ \  \_/   \  | (  <_> |  <_> )  |__ "
	echo -e "    /__/\_ \/______  /\_____  / \_____  /__|  \____/ \____/|____/ "
	echo -e "          \/       \/       \/        \/                          "
	echo -e "                          Version 0.1                             "
	echo -e "             http://primepage.de | ah@primepage.de                "
	echo -e "                    (c) Alexander Hagenah 2009                    "	
	echo -e "$C_NC"
	echo -e "$C_WHITEBOLD   Usage:$C_NC        ./x360tool [device] [image]"
	echo -e "$C_WHITEBOLD   Example:$C_NC      ./x360tool /dev/cdrom /tmp/xbox360.iso"
	echo -e ""
	exit 1
fi

options() {
	echo -e ""
	echo -e "$C_WHITEBOLD   [1]:$C_NC Stealth Checking with abgx360"
	echo -e "$C_WHITEBOLD   [2]:$C_NC Burn ISO to DVD-DL"
	echo -e "$C_WHITEBOLD   [q]:$C_NC Quit"
}

main() {
	if [ ! -f $IMAGE ]; then
		echo -e "$C_RED"
		echo -e "[x] $IMAGE is not a valid file!"
		echo -e "$C_NC"
	else
		options
		echo	""
		printf	"Pleaser enter 1 or 2: " && read OPTION
		
		case "$OPTION" in
		"1")
			abgx_stealth
		;;
		"2")
			burn_iso
		;;
		"q"|"Q")
			exit 0
		;;
		*)
			echo -e "$C_RED"
			echo -e "[x] $OPTION is not a valid answer!"
			echo -e "$C_NC"
			main
			exit 0
		esac
	fi
}

abgx_stealth() {
	if [ -f $ABGX ]; then
		echo $IMAGE
		$ABGX -pt --af3 --max --pause $IMAGE
	else
		echo -e "$C_RED"
		echo -e "Cannot find abgx360!"
		echo -e "Set to: $ABGX"
		echo -e "Make sure abgx is compiled and path is defined correctly!"
		echo -e "$C_NC"
	fi
}

burn_iso() {

	echo "Cheking ISO for filesize..."
	FILESIZE=$(stat -c%s $IMAGE)
	
	if [ $FILESIZE -le 7572881408 ]; then
		echo -e "$C_RED"
		echo -e "Filesize is unusual for valid XBOX 360 ISO. Please check with abgx360."
		echo -e "Usual Filesize: 7838695424 or at least greater then 7572881408."
		echo -e "ISO filesize:	$FILESIZE"
		echo -e "$C_NC"
	else
		echo -e "$C_GREEN"
		echo -e "Filesize OK!"
		echo -e "$C_NC"
		printf "Burn with Speed [1,2,4,6,8] (Default "2"): " && read BURNSPEED
		
		case "$BURNSPEED" in
		"2"|"4"|"6"|"8")
			echo ""
			echo "Insert blank DVD-DL and press [ENTER]"
			read
			echo `date`": Burning image started..." >> $LOGFILE
			growisofs -use-the-force-luke=dao -use-the-force-luke=break:1913760  -dvd-compat -speed=$BURNSPEED -Z $DEVICE=$IMAGE >> $LOGFILE
			echo `date`": Burning image ended!" >> $LOGFILE
		;;
		*)
			echo -e "$C_RED[x]" " Answer not allowed.$C_NC"
			burn_iso
			exit 0
		esac
	fi
}

main
