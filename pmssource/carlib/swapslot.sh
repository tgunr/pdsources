#!/bin/bash
#  $Id$
#
#  Created by Dave Carlton on 2008-09-01.
#  Copyright (c) 2008 polyMicro Systems. All rights reserved.
#

DEBUGCMD=
USER_INTERRUPT=13
CAROUSELPATH=${CAROUSELPATH:-"$HOME/Library/PickADisk"}
CMDPATH="`dirname $0`"
CMDNAME="`basename $0`"
DACALCMD="$CMDPATH/dacal" 
XATTRCMD="$CMDPATH/xattr"

from_carousel="`ls "$CAROUSELPATH"|head -n 1`"
from_carousel="`basename $from_carousel .carousel`"

# new attributes
xattrbase="com.polymicrosystems.pickadisk"
xattrcarousel="$xattrbase.device"
xattrslot="$xattrcarousel.slot"
xattrkind="$xattrslot.kind"
xattradded="$xattrslot.added"
xattrcheckout="$xattrslot.checkout"
xattrvolname="$xattrslot.volname"

OLDXATTR="$xattrcarousel
$xattrslot
"
function usage () {
echo "swapslot --from-carousel carousel --from-slot slot --to-ccarousel carousel --to-slot slot
    -h Help
    -v Verbose
    -c Carousel number; default = 1
    -s Slot number
	swapslot expects at least 3 arguments; -from-carousel --from-slot --to-slot
	Alternate usage: swapslot -c carousel -s from -s to 
	If --to-carosuel is not specified, --from-carousel is assumed
	If --from-carousel not specified, 1st carousel assumed
	"
   exit 1
}

# see if we can even get started
if [[ ! -e "$CAROUSELPATH" ]] ; then
	echo "$CMDNAME: No folder at $HOME/Library/PickADisk"
	exit 1
fi

while [ "${1+isset}" ]; do
	case "$1" in
    -f|--from-carousel)
		from_carousel="$2"
		shift 2
	;;
    -t|--to-carousel)
		to_carousel="$2"
		shift 2
	;;
	-s)
		if [[ ${from_slot} ]] ; then
			to_slot="$2"
		else
			from_slot="$2"
		fi
		shift 2
	;;
    --from-slot)
    	from_slot="$2"
	    shift 2
	;;
    --to-slot)
	    to_slot="$2"
	    shift 2
    ;;
	-v|--verbose)
		verbose=-v
		shift
	;;
    -h|--help)
	    usage
	    # no shifting needed here, we'll quit!
	    exit 
    ;;
    *)
		echo "Error: Unknown option: $1" >&2
		exit 1
    ;;
  esac
done

#see if we have enough args to continue

#check carousels
if [[ $from_carousel ]] ; then
	if ! [[ $to_carousel ]] ; then
		# to_carousel not specified so use the from_carousel
		to_carousel="$from_carousel"
	fi
else
	echo "$CMDNAME: --from_carousel not specified"
	exit 64
fi

#do we have slots?
if ! [[ $from_slot && $to_slot ]] ; then
	echo "$CMDNAME: --from-slot and --to-slot must be specified"
	exit 64
fi

from_carouselbase="$CAROUSELPATH/$from_carousel.carousel"
from_carouselbaseslot="$from_carouselbase/Slot $from_slot"
to_carouselbase="$CAROUSELPATH/$to_carousel.carousel"
to_carouselbaseslot="$to_carouselbase/Slot $to_slot"

function del-xattr { # filepath
	xattrs=`$XATTRCMD -l "$1" | awk 'BEGIN{FS=":"}; {print $2}'`
	for xattr in $xattrs ; do
		# echo $xattr
		for oldattr in $OLDXATTR ; do
			if [[ "${xattr}" == "${oldattr}" ]] ; then
				#echo "$CMDNAME: deleting $xattr in $1"
				$DEBUGCMD $XATTRCMD -d "${oldattr}" "$1" >/dev/null
			fi
		done
	done
}

function set-xattr { # filepath carousel slot
	# go thru all files
	find "$1" -print0 | while read -d $'\0' filename ; do
	# echo "`pwd`/$filename: C=$currentCarousel S=$currentSlot"
	# delete specified attributes 
	del-xattr "$filename"
	# add in new ones
	$DEBUGCMD $XATTRCMD -w "$xattrcarousel" $2 "$filename"
	$DEBUGCMD $XATTRCMD -w "$xattrslot" $3 "$filename"
	#$XATTRCMD -l "$filename"
	done # with files in slot
}

# check if from exists, no need to continue if not
if ! [[ -e "$from_carouselbaseslot" ]] ; then
	echo "CMDNAME: --from_slot $from_slot does not exist"
	exit 64
fi

# go find the --to-slot and move it aside
if [[ -e "$to_carouselbaseslot" ]] ; then
	$DEBUGCMD mv -f $verbose "$to_carouselbaseslot" "$CAROUSELPATH/"
fi

# now move the from_slot to the to_slot
$DEBUGCMD mv -f $verbose "$from_carouselbaseslot" "$to_carouselbaseslot"
$DEBUGCMD set-xattr "$to_carouselbaseslot" $to_carousel $to_slot

if [[ -e "$CAROUSELPATH/Slot $to_slot" ]] ; then
	$DEBUGCMD mv -f $verbose "$CAROUSELPATH/Slot $to_slot" "$from_carouselbaseslot"
	$DEBUGCMD set-xattr "$from_carouselbaseslot" $from_carousel $from_slot
fi
