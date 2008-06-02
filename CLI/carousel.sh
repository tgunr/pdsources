#!/bin/bash 
CAROUSELPATH=${CAROUSELPATH:-"$HOME/Library/Carousels"}
volumename="`df|tail -n 1|sed -e 's/.*\(\/Volumes.*\)/\1/'`"
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

while getopts "hc:s:g:l:d:vt:nxz" Option
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

    echo "Creating $discname for Slot $slot"

    carouselbase="$CAROUSELPATH/Carousel $carousel"
    carouselpath="$carouselbase/Slot $slot/$discname"

    if [[ -d "$carouselbase/Slot $slot" ]] ; then 
	rm -fr "$carouselbase/Slot $slot"
    fi

    if [[ $nodisc = 1 ]] ; then
	if [[ "$title" == "" ]] ; then
	    echo "No title! Use -t Tile when not labling from a disc"
	    exit 1
	fi
	if [[ $debug == 1 ]] ; then
	    echo "mkdir -p "$carouselpath""
	    echo "/usr/bin/xattr -w "@carousel" $carousel  "$carouselpath""
	    echo "/usr/bin/xattr -w "@slot" "$slot" "$carouselpath""
	else
	    mkdir -p "$carouselpath"
	    /usr/bin/xattr -w "@carousel" $carousel  "$carouselpath"
	    /usr/bin/xattr -w "@slot" "$slot" "$carouselpath"
	fi
    else
	if [[ $debug == 1 ]] ; then
	    echo "mkdir -p "$carouselpath""
	else
	    mkdir -p "$carouselpath"
	fi
	if [[ ! -d "$volumename" ]] ; then
	    echo "No volume named: $volumename"
	    exit 1
	fi
	
	pushd "$volumename" > /dev/null
	
	if [[ "$level" != "all" ]] ; then
	    maxlevel="-maxdepth $level"
	fi
	
	if [[ "$verbose" != "" ]] ; then
	    echo "Creating mirror folders in $carouselpath"
	fi

	if [[ $debug == 1 ]] ; then
	    echo "find . -type d $maxlevel -exec mkdir -p  "$carouselpath/"{} \;  $verbose"
	else
	    find . -type d $maxlevel -exec mkdir -p  "$carouselpath/"{} \;  $verbose
	fi
	if [[ "$verbose" != "" ]] ; then
	    echo "Creating mirror files in $carouselpath"
	fi

	if [[ $debug == 1 ]] ; then
	    echo "find . -type f $maxlevel -exec touch -r {}  "$carouselpath/"{} \; $verbose"
	else
	    find . -type f $maxlevel -exec touch -r {}  "$carouselpath/"{} \; $verbose
	fi
	
	popd > /dev/null
	
	echo "Writing xattr, be patient"
	if [[ $debug == 1 ]] ; then
	    echo "find "$carouselpath" -exec /usr/bin/xattr -w "@carousel" $carousel {} \; -exec /usr/bin/xattr -w "@slot" "$slot" {} \; $verbose"
	    echo "diskutil eject "$volumename""
	else
	    find "$carouselpath" -exec /usr/bin/xattr -w "@carousel" $carousel {} \; -exec /usr/bin/xattr -w "@slot" "$slot" {} \; $verbose
	    diskutil eject "$volumename"
	fi
    fi
    
    if [[ $nomove == 0 ]] ; then
	if [[ $debug == 1 ]] ; then
	    echo "~/bin/dacal -s $slot"
	else
	    ~/bin/dacal -s $slot
	fi
    fi

    ((slot++))
#     slot=$(($slot + 1))
    echo $slot > ~/.dacalslot
else
    getslotnum=`/usr/bin/xattr -l "$getfileslot"|cut -c7-`
    if [[ $debug == 1 ]] ; then
	echo "dacal -s $getslotnum"
    else
	dacal -s $getslotnum
    fi
fi
