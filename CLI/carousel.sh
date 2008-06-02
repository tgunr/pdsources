#!/bin/bash
CAROUSELPATH=${CAROUSELPATH:-"$HOME/Library/Carousels"}
CMDPATH="`dirname $0`"
DACALCMD="$CMDPATH/dacal" 
# XATTRCMD="$CMDPATH/xattr"
XATTRCMD="/usr/bin/xattr"

echo "$@"

volumename="/Volumes/Unititled"
device="`df|tail -n 1|cut -c1-18`"
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
debug=0
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
EOF
    exit 1
}

while getopts "hc:s:g:l:d:vt:nxze" Option
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
	d ) volumename="$OPTARG" ;;
	g ) getfileslot="$OPTARG" ;;
	z ) debug=1 ;;
	e ) eject=1 ;;
	* ) echo "Unimplemented option chosen." 
	    exit 1 ;;   # DEFAULT
    esac
done
shift $(($OPTIND - 1))

if [[ ! "${volumename%\/*/}" =~ "/Volumes" ]] ; then
    echo "Source is not a volume: $volumename"
    exit 1
fi

if [[ "$getfileslot" == "" ]] ; then
    if [[ "$title" != "" ]] ; then 
	discname="$title"
    fi

    echo "Creating $discname for Carousel $carousel Slot $slot"

    carouselbase="$CAROUSELPATH/Carousel $carousel"
    carouselpathslot="$carouselbase/Slot $slot/$discname"

    if [[ -d "$carouselbase/Slot $slot" ]] ; then 
	/bin/rm -fr "$carouselbase/Slot $slot"
    fi

    if [[ $nodisc = 1 ]] ; then
	if [[ "$title" == "" ]] ; then
	    echo "No title! Use -t Tile when not labling from a disc"
	    exit 1
	fi
	if [[ $debug == 1 ]] ; then
	    echo "/binmkdir -p $carouselpathslot"
	    echo "$XATTRCMD -w com.polymicrosystems.carousel $carousel $carouselpathslot"
	    echo "$XATTRCMD -w com.polymicrosystems.carousel.slot $slot $carouselpathslot"
	else
	    /bin/mkdir -p "$carouselpathslot"
	    "$XATTRCMD" -w "com.polymicrosystems.carousel" $carousel  "$carouselpathslot"
	    "$XATTRCMD" -w "com.polymicrosystems.carousel.slot" $slot "$carouselpathslot"
	fi
    else
	if [[ $debug == 1 ]] ; then
	    echo "/bin/mkdir -p $carouselpathslot"
	else
	    /bin/mkdir -p "$carouselpathslot"
	fi
	if [[ ! -d "$volumename" ]] ; then
	    echo "No volume named: $volumename"
	    exit 1
	fi
		
	if [[ "$level" != "all" ]] ; then
	    maxlevel="-maxdepth $level"
	fi
	
	if [[ "$verbose" != "" ]] ; then
	    echo "Creating mirror folders in $carouselpathslot"
	fi

	if [[ $debug == 1 ]] ; then
	    echo "/usr/bin/find $volumename -type d $maxlevel -exec mkdir -p  $carouselpathslot/{} \;  $verbose"
	else
	    /usr/bin/find "$volumename" -type d $maxlevel -exec mkdir -p  "$carouselpathslot/{}" \;  $verbose
	fi
	if [[ "$verbose" != "" ]] ; then
	    echo "Creating mirror files in $carouselpathslot"
	fi

	if [[ $debug == 1 ]] ; then
	    echo "/usr/bin/find . -type f $maxlevel -exec touch -r {}  $carouselpathslot/{} \; $verbose"
	else
	    /usr/bin/find "$volumename" -type f $maxlevel -execdir touch -r {}  "$carouselpathslot/{}" \; $verbose
	fi
		
	echo "Writing extended attributes, be patient"
	if [[ $debug == 1 ]] ; then
	    echo "/usr/bin/find  $carouselpathslot -print | awk  '{ printf \"%s\"\n, $0 }' | xargs $XATTRCMD -w com.polymicrosystems.carousel $carousel"
	    echo "/usr/bin/find  $carouselpathslot -print | awk  '{ printf \"%s\"\n, $0 }' | xargs $XATTRCMD -w com.polymicrosystems.carousel.slot $slot"
	    if [[ $eject == 1 ]] ; then
		echo "/usr/sbin/diskutil eject $volumename"
	    fi
	else
	    /usr/bin/find "$carouselpathslot" -print | awk  '{ printf "\"%s\"\n", $0 }' | xargs "$XATTRCMD" -w "com.polymicrosystems.carousel" $carousel
	    /usr/bin/find "$carouselpathslot" -print | awk  '{ printf "\"%s\"\n", $0 }' | xargs "$XATTRCMD" -w "com.polymicrosystems.carousel.slot" $slot
	    if [[ $eject == 1 ]] ; then
		/usr/sbin/diskutil eject "$volumename"
	    fi
	fi
    fi
    
    if [[ $nomove == 0 ]] ; then
	if [[ $debug == 1 ]] ; then
	    echo "$DACALCMD -s $slot"
	else
	    "$DACALCMD" -s $slot
	fi
    fi

    ((slot++))
    echo $slot > ~/.dacalslot
else
    set -x
    carousel = `"$XATTRCMD" -p com.polymicrosystems.carousel  "$getfileslot"`
    slot = `"$XATTRCMD" -p com.polymicrosystems.carousel.slot  "$getfileslot"`
    if [[ $debug == 1 ]] ; then
	echo "$DACALCMD -s $getslotnum"
    else
	"$DACALCMD" -c $carousel -s $slot
    fi
fi
exit 0
