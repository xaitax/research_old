#!/bin/bash
#
# @author:	Alexander 'xaitax' Hagenah <ah@primepage.de>
#			http://primepage.de
#
# @desc:	HTTP Banner Grabber + Highlighting
#
# @created:	05/14/2013
#

# GLOBAL VARIABLES

ARGV0="`basename "$0"`"
OPTIONS="aehl:n:pr:s:t:"
USAGE="\
usage: $ARGV0 [$OPTIONS]

  grab server string from http banner.
  $ARGV0 scans single hosts or defined network ranges.

options:
  -a		alert (BEL) if banner matches expression
		to add/del expressions edit script
  -e		emphasize output if banner matches expression
		to add/del expressions edit script
  -h		print this help
  -l filename	write to file
  -n network	three octet network addr like 192.168.0
  -p		show defined emphrasize expressions
  -r b:e	host range to scan. default $BADDR:$EADDR
  -s host	single scan
  -t secs	timeout for connects and final net reads. default $NCTIMEOUT"

# VARIABLES

BADDR=1			# host range begin default value
EADDR=255		# host range end default value
NETCAT=/bin/nc	# path to netcat
NCTIMEOUT=2		# default timeout for connects and final net reads

# put expressions to emphersize or alert if banner matches here...
# example below was used because of CVE-2013-2028
HIGHLIGHT="
nginx/1.3.9
nginx/1.3.10
nginx/1.3.11
nginx/1.3.12
nginx/1.3.13
nginx/1.3.14
nginx/1.3.15
nginx/1.4.0
"

# FUNCTIONS

usage_exit()
# args: 'int return'
{
	echo "$USAGE" >&2
	exit $1
}

cleanup()
{
	# stdout
	echo "|                   "
	echo "\`-----[ "`date "+%Y-%m-%d %H:%M:%S"`""

        exit $?
}

highlight()
# args: 'string'
{
	for EXPRESSION in $HIGHLIGHT; do
		echo $1 | grep -i $EXPRESSION 2>&1 >/dev/null
		if [ $? -eq 0 ]; then
			BANNER="\e[1;31m$BANNER\e[0m"
		fi
	done
}

alert()
# args: 'string'
{
        for EXPRESSION in $HIGHLIGHT; do
                echo $1 | grep -i $EXPRESSION 2>&1 >/dev/null
                if [ $? -eq 0 ]; then
			tput bel
                fi
        done
}

single()
# args: 'host'
{
	# grab
	BANNER="`echo -e "HEAD / HTTP/1.0\r\n\r\n" | 
		$NETCAT -w $NCTIMEOUT $HOST 80 2>/dev/null | 
		awk '/Server:/ || /X-Powered-By:/' | 
		awk '{sub(/\r$/,"");print}' | 
		awk '{printf("%s", $0 " " (NR==1 ? "" : "\n"))}'
	`"
	
	if [ "$BANNER" != "" ]; then
		# logfile
		if [ $LOG -eq 1 ]; then
			echo ",----[ $1">>$LOGFILE
			echo "|">>$LOGFILE
			echo -en "| $1: $BANNER\n">>$LOGFILE
			echo "|">>$LOGFILE
			echo "\`-----[ "`date "+%Y-%m-%d %H:%M:%S"`"">>$LOGFILE
		fi

		# emphasize
		if [ $EMPHASIZE -eq 1 ]; then
			highlight "$BANNER"
		fi

		# alert
		if [ $ALERT -eq 1 ]; then
			alert "$BANNER"
		fi

		# stdout
		echo ",----[ $1"
		echo "|"
		echo -en "| $1: $BANNER\n"
		echo "|"
		echo "\`-----[ "`date "+%Y-%m-%d %H:%M:%S"`""
	fi

}

multi()
{
	if [ $RANGE != "0" ]; then
		BADDR="`echo $RANGE | cut -d\: -f1`"
		EADDR="`echo $RANGE | cut -d\: -f2`"
	fi

	EMPTY=1

	# logfile
	if [ $LOG -eq 1 ]; then
	        echo ",----[ $NETWORK.$BADDR-$NETWORK.$EADDR">>$LOGFILE 
		echo "|">>$LOGFILE

	fi

	# stdout
	echo ",----[ $NETWORK.$BADDR-$NETWORK.$EADDR"
	echo "|"
	while [ $BADDR -le $EADDR ]; do
		HOST=$NETWORK.$BADDR

		BANNER="`echo -e "HEAD / HTTP/1.0\r\n\r\n" | 
			$NETCAT -w $NCTIMEOUT $HOST 80 2>/dev/null | 
			awk '/Server:/ || /X-Powered-By:/' | 
			awk '{sub(/\r$/,"");print}' | 
			awk '{printf("%s", $0 " " (NR==1 ? "" : "\n"))}'
		`"
				
		if [ "$BANNER" != "" ]; then
			EMPTY=0

			# logfile
			if [ $LOG -eq 1 ]; then
				echo -en "| $HOST: $BANNER\n">>$LOGFILE
			fi

			# emphasize
	                if [ $EMPHASIZE -eq 1 ]; then
				highlight "$BANNER"
			fi
		
			# alert
			if [ $ALERT -eq 1 ]; then
				alert "$BANNER"
			fi

			# stdout
			echo -en "| $HOST: $BANNER\n"
		fi

		# display actual host
		if [ $BADDR -eq $EADDR ]; then
			echo -en "|\r"
		else
			echo -en "| $HOST\r"
		fi

		BADDR=`expr $BADDR + 1`
	done

	if [ $EMPTY -eq 1 ]; then
		echo "| received 0 banner"
	fi

	# logfile
	if [ $LOG -eq 1 ]; then
		echo "|">>$LOGFILE
		echo "\`----[ "`date "+%Y-%m-%d %H:%M:%S"`"">>$LOGFILE
	fi

	# stdout
	echo "|                    "
	echo "\`----[ "`date "+%Y-%m-%d %H:%M:%S"`""

}

# START

if [ $# -lt 1 ]; then
	usage_exit 1
fi

# SIGNAL HANDLING

trap "cleanup" SIGINT SIGPIPE SIGTERM

# DEFAULT VALUES

ALERT=0
EMPHASIZE=0
LOG=0
MULTI=0
RANGE=0
SINGLE=0

# GETOPTS

while getopts "$OPTIONS" OPTION; do
	case "$OPTION" in
		a)
			ALERT=1
			;;
		e)
			EMPHASIZE=1
			;;
		h)	usage_exit 0
			;;
		l)
			LOG=1
			LOGFILE="$OPTARG"
			;;
		n)
			MULTI=1
			NETWORK="$OPTARG"
			;;
		p)
			for LINE in $HIGHLIGHT; do echo "$LINE"; done 
			exit $?
			;;
		r)
			RANGE="$OPTARG"
			;;
		s)
			SINGLE=1
			HOST="$OPTARG"
			;;
		t)
			NCTIMEOUT=$OPTARG
			;;
	esac
done

# PARSE

if [ $SINGLE -eq 1 ]; then single $HOST; fi
if [ $MULTI -eq 1 ]; then multi $NETWORK; fi

exit $?
