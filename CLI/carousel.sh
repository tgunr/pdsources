#!/bin/bash
#  $Id$
#
#  Created by Dave Carlton on 2008-05-31.
#  Copyright (c) 2008 polyMicro Systems. All rights reserved.
#
USER_INTERRUPT=13
CAROUSELPATH=${CAROUSELPATH:-"$HOME/Library/Carousels"}
CMDPATH="`dirname $0`"
CMDNAME="`basename $0`"
DACALCMD="$CMDPATH/dacal" 
XATTRCMD="$CMDPATH/xattr"
#XATTRCMD="/usr/bin/xattr"
xattrbase="com.polymicrosystems.pickadisc"
xattrcarousel="$xattrbase.carousel"
xattrslot=$xattrcarousel".slot"
xattrkind="$xattrbase.kind"

# some assumptions
volumename="/Volumes/Untitled"
discname=`basename "$volumename"`
slotfile="$CAROUSELPATH/.dacalslot"

if [[ ! -e $slotfile ]] ; then 
    echo "1" > $slotfile
fi

slot=`cat "$slotfile"`
getslot=""
level=1
minslot=1
carousel=1
nodisc=0
nomove=0
eject=0
kind="data"
DEBUGCMD=
verbose=""
maxlevel="-maxdepth 1"

function usage () {
echo "carousel usage
    -h Help
    -v Verbose
    -c Carousel number; default = 1
    -m Minimum slot number; optional with -N; default = 1
    -s Slot number; subsequent calls will increment from this value
    -l Level to scan, 1 is default for top level, all for everything
    -t Title
    -x Do not issue move to slot command, useful if slot door is already down
    -n No disc, assumes -t is being used, 
          you are just specifying a title for the slot
    -d Disc volume to scan i.e. /Volumes/disc
    -g Get disc from carousel using path to carousel file|folder
    -D Show commands to execute but do not execute, use echo or logger as argument
    -e Eject volume on completion
    -w Which title is at -c -s (which must be specified)
    -k Clear slot
    -p Path to -c -s options
    -N Next available slot, 
          scans -c from -m upward to -s for first avaialable slot
    -X Turn on bash debug flag
    -K Specify kind of slot folder data (default = data)
	-L List all slots paths for -c"
   exit 1
}

while getopts "hc:m:s:g:l:d:vt:nxD:ewkpNXK:L" Option
do 
    case "$Option" in 
	h ) usage ;;
	v ) verbose="-t" ;;
	c ) carousel="$OPTARG" ;;
	m ) minslot="$OPTARG" ;;
	s ) slot="$OPTARG" ;;
	l ) level="$OPTARG" ;;
	t ) title="$OPTARG" ;;
	n ) nodisc=1 ;;
	x ) nomove=1 ;;
	d ) volumename="$OPTARG" 
	    discname=`basename "$volumename"`;;
	g ) getfileslot="$OPTARG" ;;
	D ) DEBUGCMD="$OPTARG" ;; 
	e ) eject=1 ;;
	w ) whichtitle=1 ;;
	k ) clearslot=1 ;;
	p ) pathtoslot=1 ;;
	N ) nextslot=1 ;;
	X ) set -x;;
	K ) kind="$OPTARG";;
	L ) listslots=1;;
	* ) echo "Unimplemented option chosen." 
	    exit 1 ;;   # DEFAULT
    esac
done
shift $(($OPTIND - 1))

carouselbase="$CAROUSELPATH/$carousel.carousel"
carouselbaseslot="$carouselbase/Slot $slot"

if [[ $listslots == 1 ]] ; then 
	if [[ -d "$carouselbase" ]] ; then
		cd "$carouselbase"
		find . -type d -maxdepth 2 -depth 2
		exit 0
fi
	exit 1
fi

if [[ $whichtitle == 1 ]] ; then
    if [[ -d "$carouselbaseslot" ]] ; then 
	ls -1 "$carouselbaseslot/"|head -1
	exit 0
    else
	$DEBUGCMD "$CMDNAME: Error - carousel $carousel slot $slot not avaialable"
	exit 1
    fi
    exit 0
fi

if [[ $pathtoslot == 1 ]] ; then
    if [[ -d "$carouselbaseslot" ]] ; then 
	$DEBUGCMD "$carouselbaseslot"
    else
	$DEBUGCMD "$CMDNAME: Error - carousel $carousel slot $slot not avaialable"
	exit 1
    fi
    exit 0
fi

if [[ $nextslot == 1 ]] ; then
    result=0
    for (( i = minslot; i < $slot; i++ )); do
	if [[ ! -d "$carouselbase/Slot $i" ]] ; then
	    result=1
	    break
	fi
    done
    if [[ $result == 1 ]] ; then
	$DEBUGCMD "$carouselbase/Slot $i"
	exit 0
    else
	$DEBUGCMD "$CMDNAME: No slot availiable up to slot $slot"
	exit 1
    fi
fi

if [[ $clearslot == 1 ]] ; then 
    if [[ -d "$carouselbaseslot" ]] ; then 
	/bin/rm -fr "$carouselbaseslot"
    else
	$DEBUGCMD "$CMDNAME: No slot at slot $slot"
	exit 1
    fi
    exit 0 
fi

if [[ ! "${volumename%\/*/}" =~ "/Volumes" ]] ; then
    $DEBUGCMD "Source is not a volume: $volumename"
    exit 1
fi

# if not getting a slot, must be storing a slot
if [[ "$getfileslot" == "" ]] ; then
    if [[ "$verbose" != "" ]] ; then
	 	echo "Creating $discname in Carousel $carousel Slot $slot"
    fi
    
    if [[ -d "$carouselbaseslot" ]] ; then 
	/bin/rm -fr "$carouselbaseslot"
    fi
    
    # no real disc, faking one from the a given -t title
    if [[ $nodisc == 1 ]] ; then
		# has to be a -t title or can't proceed
		if [[ "$title" == "" ]] ; then
			$DEBUGCMD "No title! Use -t Title when not labling from a disc"
			exit 1
		else
			discname="$title"
		fi
		$DEBUGCMD /bin/mkdir -p "$carouselbaseslot/$discname"
		trap 'rm -fr "$carouselbaseslot"; exit $USER_INTERRUPT' TERM INT
		$DEBUGCMD "$XATTRCMD" -w "$xattrcarousel" $carousel  "$carouselbase"
		$DEBUGCMD "$XATTRCMD" -w "$xattrcarousel" $carousel  "$carouselbaseslot"
		$DEBUGCMD "$XATTRCMD" -w "$xattrcarousel" $carousel  "$carouselbaseslot/$discname"
		$DEBUGCMD "$XATTRCMD" -w "$xattrslot" $slot "$carouselbaseslot"
		$DEBUGCMD "$XATTRCMD" -w "$xattrslot" $slot "$carouselbaseslot/$discname"
		$DEBUGCMD "$XATTRCMD" -w "$xattrkind" "$kind" "$carouselbaseslot"
		$DEBUGCMD "$XATTRCMD" -w "$xattrkind" "$kind" "$carouselbaseslot/$discname"
    else # real disc to index
		$DEBUGCMD /bin/mkdir -p "$carouselbaseslot/$discname"
		trap 'rm -fr "$carouselbaseslot"; exit $USER_INTERRUPT' TERM INT
		$DEBUGCMD "$XATTRCMD" -w "$xattrcarousel" $carousel  "$carouselbase"
		$DEBUGCMD "$XATTRCMD" -w "$xattrcarousel" $carousel  "$carouselbaseslot"
		$DEBUGCMD "$XATTRCMD" -w "$xattrcarousel" $carousel  "$carouselbaseslot/$discname"
		$DEBUGCMD "$XATTRCMD" -w "$xattrslot" $slot "$carouselbaseslot"
		$DEBUGCMD "$XATTRCMD" -w "$xattrslot" $slot "$carouselbaseslot/$discname"
		$DEBUGCMD "$XATTRCMD" -w "$xattrkind" "$kind" "$carouselbaseslot"
		$DEBUGCMD "$XATTRCMD" -w "$xattrkind" "$kind" "$carouselbaseslot/$discname"

		if [[ ! -d "$volumename" ]] ; then # oops, no disc name? whats this?
			$DEBUGCMD "No volume named: $volumename"
			exit 1
		fi
		
		if [[ $level != 1 ]] ; then
			if [[ $level == 0 ]] ; then
				maxlevel=""
			else
				maxlevel="-maxdepth $level"
			fi
		fi

		if [[ "$verbose" != "" ]] ; then
			echo "Creating mirror folders in $carouselbaseslot"
		fi
		
		# make paths to folders in backend from disc accroding to desired level
		pushd "$carouselbaseslot/" > /dev/null
		$DEBUGCMD /usr/bin/find "$volumename" -type d $maxlevel -print |sed -e 's/\/Volumes\///' |xargs  $verbose -I % mkdir -p "%"
		if [[ -d "$carouselbaseslot/%" ]] ; then 
			rmdir "$carouselbaseslot/%"
		fi

		if [[ "$verbose" != "" ]] ; then
			echo "Creating mirror files in $carouselbaseslot"
		fi
		
		# create files for each folder we just created
		vname=`dirname "$volumename"`
		$DEBUGCMD /usr/bin/find "$volumename" -type f $maxlevel -print |sed -e 's/\/Volumes\///' |xargs $verbose -I % touch -r "$vname/%" "%"
		if [[ "$title" != "" ]] ; then # need to override the discname with title
			mv "$discname" "$title"
		fi
		popd > /dev/null
		
		# set the attributes for each file
		if [[ "$verbose" != "" ]] ; then
			echo "Writing extended attributes, be patient"
		fi
		
		$DEBUGCMD /usr/bin/find "$carouselbaseslot" -print | awk  '{ printf "\"%s\"\n", $0 }' | xargs $verbose -I % "$XATTRCMD" -w "$xattrcarousel" $carousel %
		$DEBUGCMD /usr/bin/find "$carouselbaseslot" -print | awk  '{ printf "\"%s\"\n", $0 }' | xargs $verbose -I % "$XATTRCMD" -w "$xattrslot" $slot %
		# $DEBUGCMD /usr/bin/find "$carouselbaseslot" -print | awk  '{ printf "\"%s\"\n", $0 }' | xargs  $verbose -I % "$XATTRCMD" -w "$xattrkind" $kind "%"
		
		if [[ $eject == 1 ]] ; then
			$DEBUGCMD /usr/sbin/diskutil eject "$volumename"
		fi
    fi
    
    if [[ $nomove == 0 ]] ; then
		$DEBUGCMD "$DACALCMD" -s $slot
    fi
    
    ((slot++))
    echo $slot > "$slotfile"
else # get a disc from a slot
    carousel=`"$XATTRCMD" -p "$xattrcarousel"  "$getfileslot"`
    slot=`"$XATTRCMD" -p "$xattrslot"  "$getfileslot"`
    $DEBUGCMD "$DACALCMD" -c $carousel -s $slot
fi
exit 0
