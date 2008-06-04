#!/bin/bash
CAROUSELPATH=${CAROUSELPATH:-"$HOME/Library/Carousels"}
CMDPATH="`dirname $0`"
CMDNAME="`basename $0`"
DACALCMD="$CMDPATH/dacal" 
# XATTRCMD="$CMDPATH/xattr"
XATTRCMD="/usr/bin/xattr"

# some assumptions
volumename="/Volumes/Untitled"
discname=`basename "$volumename"`

if [[ ! -e ~/.dacalslot ]] ; then 
    echo "1" > ~/.dacalslot
fi

slot=`cat ~/.dacalslot`
getslot=""
level=1
carousel=1
nodisc=0
nomove=0
eject=0

function usage {
    cat <<EOF
carousel [-h] [-v] [-c carousel] [-s slot] [-l level] [-x] [-n] [-t Title] [-d /Volumes/disc] [-g Carousel/path]
    -h Help
    -v Verbose
    -c Carousel number; default = 1
    -s Slot number; subsequent calls will increment from this value
    -l Level to scan, 1 is default for top level, all for everything
    -x Do not issue move to slot command, useful if slot door is already down
    -n No disc, assumes -t, you are just specifying a title for the slot
    -d Disc volume to scan, assumes /Volumes/disc, default is last mounted device e.g. DVD/CD you just mounted
    -g Get disc from carousel using path to carousel file/folder
    -z Show commands to execute but do not execute
    -e Eject volume on completion
    -w Which title is at -c -s (which must be specified)
    -k Clear slot
	-p Path to -c -s options
	-N Next available slot, scans -c from 1 upward to -s for first avaialable slot
EOF
    exit 1
}

while getopts "hc:s:g:l:d:vt:nxzewkpN" Option
do 
    case "$Option" in 
	h ) usage ;;
	v ) verbose="-print" ;;
	c ) carousel="$OPTARG" ;;
	s ) slot="$OPTARG" ;;
	l ) level="$OPTARG" ;;
	t ) title="$OPTARG" ;;
	n ) nodisc=1 ;;
	x ) nomove=1 ;;
	d ) volumename="$OPTARG" 
	    discname="`basename $volumename`";;
	g ) getfileslot="$OPTARG" ;;
	z ) ${DEBUGCMD-echo} ;;
	e ) eject=1 ;;
	w ) whichtitle=1 ;;
	k ) clearslot=1 ;;
	p ) pathtoslot=1 ;;
	N ) nextslot=1 ;;
	* ) echo "Unimplemented option chosen." 
	    exit 1 ;;   # DEFAULT
    esac
done
shift $(($OPTIND - 1))

carouselbase="$CAROUSELPATH/Carousel $carousel"
carouselbaseslot="$carouselbase/Slot $slot"

if [[ $debug == 1 ]] ; then
	echo "$CMDNAME $@"
	$DEBUGCMD=echo
fi

if [[ $whichtitle == 1 ]] ; then
	if [[ -d "$carouselbaseslot" ]] ; then 
		ls -1 "$carouselbaseslot/"|head -1
		exit 0
	else
		echo "$CMDNAME: Error - carousel $carousel slot $slot not avaialable"
		exit 1
	fi
	exit 0
fi

if [[ $pathtoslot == 1 ]] ; then
	if [[ -d "$carouselbaseslot" ]] ; then 
		echo "$carouselbaseslot"
	else
		echo "$CMDNAME: Error - carousel $carousel slot $slot not avaialable"
		exit 1
	fi
	exit 0
fi

if [[ $nextslot == 1 ]] ; then
	result=0
	for (( i = 1; i < $slot; i++ )); do
		if [[ ! -d "$carouselbase/Slot $i" ]] ; then
			result=1
			break
		fi
	done
	if [[ $result == 1 ]] ; then
		echo "$carouselbase/Slot $i"
		exit 0
	else
		echo "$CMDNAME: No slot availiable up to slot $slot"
		exit 1
	fi
fi

if [[ ! "${volumename%\/*/}" =~ "/Volumes" ]] ; then
    echo "Source is not a volume: $volumename"
    echo 1
fi

# if not getting a slot, must be storing a slot
if [[ "$getfileslot" == "" ]] ; then
    if [[ "$title" != "" ]] ; then 
	discname="$title"
    fi
    
    echo "Creating $discname in Carousel $carousel Slot $slot"
    carouselpathslot="$carouselbase/Slot $slot/"
    carouselpathslotdiscname="$carouselpathslot/$discname"
    
    if [[ -d "$carouselpathslot" ]] ; then 
		/bin/rm -fr "$carouselpathslot"
		if [[ $clearslot == 1 ]] ; then # no need to continue
			exit 0 
		fi
    fi

    if [[ $nextincslot == 1 ]] ; then
		for file in "$carouselpathslot" ; do
		done
		exit 0
	fi
	
    # no real disc, faking one from the a given -t title
    if [[ $nodisc == 1 ]] ; then
	# has to be a -t title or can't proceed
	if [[ "$title" == "" ]] ; then
	    echo "No title! Use -t Tile when not labling from a disc"
	    exit 1
	fi
	/bin/mkdir -p "$carouselpathslotdiscname"
	$DEBUGCMD "$XATTRCMD" -w "com.polymicrosystems.carousel" $carousel  "$carouselpathslotdiscname"
	$DEBUGCMD "$XATTRCMD" -w "com.polymicrosystems.carousel.slot" $slot "$carouselpathslotdiscname"
    else # real disc to index
	$DEBUGCMD /bin/mkdir -p "$carouselpathslotdiscname"
	
	if [[ ! -d "$volumename" ]] ; then # oops, no disc name? whats this?
	    echo "No volume named: $volumename"
	    exit 1
	fi
	
	if [[ "$level" != "all" ]] ; then
	    maxlevel="-maxdepth $level"
	fi
	
	if [[ "$verbose" != "" ]] ; then
	    echo "Creating mirror folders in $carouselpathslotdiscname"
	fi

	# make paths to folders in backend from disc accroding to desired level
	$DEBUGCMD /usr/bin/find "$volumename" -type d $maxlevel -exec mkdir -p  "$carouselpathslotdiscname/{}" \;  $verbose
	
	if [[ "$verbose" != "" ]] ; then
	    echo "Creating mirror files in $carouselpathslotdiscname"
	fi
	
	# create files for each folder we just created
	$DEBUGCMD /usr/bin/find "$volumename" -type f $maxlevel -execdir touch -r {}  "$carouselpathslotdiscname/{}" \; $verbose
	
	# set the attributes for each file
	echo "Writing extended attributes, be patient"
	$DEBUGCMD /usr/bin/find "$carouselpathslotdiscname" -print | awk  '{ printf "\"%s\"\n", $0 }' | xargs "$XATTRCMD" -w "com.polymicrosystems.carousel" $carousel
	$DEBUGCMD /usr/bin/find "$carouselpathslotdiscname" -print | awk  '{ printf "\"%s\"\n", $0 }' | xargs "$XATTRCMD" -w "com.polymicrosystems.carousel.slot" $slot
	
	if [[ $eject == 1 ]] ; then
	    $DEBUGCMD /usr/sbin/diskutil eject "$volumename"
	fi
    fi
    
    if [[ $nomove == 0 ]] ; then
	$DEBUGCMD "$DACALCMD" -s $slot
    fi

    ((slot++))
    echo $slot > ~/.dacalslot
else # get a disc from a slot
    carousel = `"$XATTRCMD" -p com.polymicrosystems.carousel  "$getfileslot"`
    slot = `"$XATTRCMD" -p com.polymicrosystems.carousel.slot  "$getfileslot"`
    $DEBUGCMD "$DACALCMD" -c $carousel -s $slot
fi
exit 0
