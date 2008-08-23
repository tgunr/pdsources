#!/bin/bash
#  $Id$
#
#  Created by Dave Carlton on 2008-06-01.
#  Copyright (c) 2008 polyMicro Systems. All rights reserved.
#

DEBUGCMD=
CAROUSELPATH=${CAROUSELPATH:-"$HOME/Library/PickADisk"}
XATTRCMD=/Users/davec/bin/xattr
# delete all known attributes
OLDXATTR="com.polymicrosystems.pickadisk'.device
com.polymicrosystems.pickadisk'.device.slot
com.polymicrosystems.pickadisk'.device.slot.kind
com.polymicrosystems.pickadisc.carousel
com.polymicrosystems.pickadisc.carousel.slot
com.polymicrosystems.pickadisc.carousel.slot=1
com.polymicrosystems.pickadisc.carousel=0000D000-0400-0000-0000-000000000000
com.polymicrosystems.pickadisc.kind=data 
com.polymicrosystems.pickadisc.kind=folder
"
specialxattr="com.polymicrosystems.pickadisc.carousel.slot="

# new attributes
xattrbase="com.polymicrosystems.pickadisk"
xattrcarousel="$xattrbase.device"
xattrslot="$xattrcarousel.slot"
xattrkind="$xattrslot.kind"
xattradded="$xattrslot.added"
xattrcheckout="$xattrslot.checkout"

function del-xattr {
	xattrs=`$XATTRCMD -l "$1" | awk 'BEGIN{FS=":"}; {print $2}'`
	for xattr in $xattrs ; do
		# echo $xattr
		for oldattr in $OLDXATTR ; do
			if [[ "${xattr}" == "${oldattr}" ]] ; then
				echo "deleting $xattr in $1"
				$DEBUGCMD $XATTRCMD -d "${oldattr}" "$1" >/dev/null
			fi
			if [[ "${xattr}" == "${specialxattr}$2" ]] ; then
				echo "deleting $xattr in $1"
				$DEBUGCMD $XATTRCMD -d "${specialxattr}$2" "$1" >/dev/null
			fi
		done
	done
}

function del-all-xattr {
	xattrs=`$XATTRCMD -l "$1" | awk 'BEGIN{FS=":"}; {print $2}'`
	for xattr in $xattrs ; do
		$DEBUGCMD $XATTRCMD -d "${xattr}" "$1" >/dev/null
	done
}

if [[ ! -e "$CAROUSELPATH" ]] ; then
	echo "$CAROUSELPATH does not exist"
	exit 1
fi

dateadded=`date "+%Y-%m-%d% %H:%M:%S -0700"`
pushd "$CAROUSELPATH"

# for carousel in "Carousel 1" ; do 
for carousel in *.carousel; do 
    pushd "$carousel" >/dev/null
    export currentCarousel="${carousel#Carousel }"
    for slot in Slot*[0-9] ; do
		# for slot in "Slot 54" ; do
	pushd "$slot" > /dev/null
	export currentSlot="${slot#Slot }"
	echo "Checking slot $slot"
	# run thru the slots
	for file in * ; do
		# go thru all files
	    find "$file" -print0 | while read -d $'\0' filename ; do
		# echo "`pwd`/$filename: C=$currentCarousel S=$currentSlot"
		# delete specified attributes 
		del-all-xattr "$filename" "$currentSlot"
		# add in new ones
		$DEBUGCMD $XATTRCMD -w "$xattrcarousel" $currentCarousel "$filename"
		$DEBUGCMD $XATTRCMD -w "$xattrslot" $currentSlot "$filename"
		# $XATTRCMD -l "$filename"
	    done # with files in slot
	done # with slot
	popd > /dev/null 
	echo "Setting slot $slot"
	# delete specified attributes 
	del-all-xattr "$slot"	"$currentSlot"		
	# add in new ones
	$DEBUGCMD $XATTRCMD -w "$xattrcarousel"  $currentCarousel "$slot"
	$DEBUGCMD $XATTRCMD -w "$xattrslot" $currentSlot "$slot"
	$DEBUGCMD $XATTRCMD -w "$xattrkind" data "$slot"
	$DEBUGCMD $XATTRCMD -w "$xattradded" "$dateadded" "$slot"
	# $XATTRCMD -l "$slot"
    done
    popd > /dev/null # back to carousels
done
popd

