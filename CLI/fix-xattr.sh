#!/bin/bash
#  fix-xattr
#
#  Created by Dave Carlton on 2008-06-01.
#  Copyright (c) 2008 polyMicro Systems. All rights reserved.
#

DEBUGCMD=
# davec 20080602 -- Need to fix this so I can use just one command, write seems broken on the C version
XATTRCMD=/Users/davec/bin/xattr
XATTRCMDW=/usr/bin/xattr
# delete all known attributes
OLDXATTR="@carousel
@slot
com.polymicrosystems.carousel
com.polymicrosystems.carousel.slot"


function del-xattr {
	xattrs=`$XATTRCMD -l "$1"`
	for xattr in $xattrs ; do
		# echo $xattr
		for oldattr in $OLDXATTR ; do
			if [[ ${xattr%=*} == ${oldattr} ]] ; then
				$DEBUGCMD $XATTRCMDW -d ${xattr%=*} "$1" >/dev/null
			fi
		done
	done
}

cd ~/Library/Carousels
# for carousel in "Carousel 1" ; do 
for carousel in Carousel*[0-9] ; do 
    pushd "$carousel" >/dev/null
    export currentCarousel="${carousel#Carousel }"
    for slot in Slot*[0-9] ; do
		# for slot in "Slot 54" ; do
	pushd "$slot" >/dev/null
	export currentSlot="${slot#Slot }"
	echo "Setting slot $slot"
	# delete specified attributes 
	for file in * ; do
	    find "$file" -print0 | while read -d $'\0' filename ; do
		echo "`pwd`/$filename: C=$currentCarousel S=$currentSlot"
		del-xattr "$filename"
		$DEBUGCMD $XATTRCMDW -w com.polymicrosystems.carousel $currentCarousel "$filename"
		$DEBUGCMD $XATTRCMDW -w com.polymicrosystems.carousel.slot $currentSlot "$filename"
	    done # with files in slot
		# echo $XATTRCMDW -w com.polymicrosystems.carousel $currentCarousel "$file"
		# echo $XATTRCMDW -w com.polymicrosystems.carousel.slot $currentSlot "$file"
	done # with slot
	popd > /dev/null 
	echo "Setting slot $slot"
	del-xattr "$slot"			
	$DEBUGCMD $XATTRCMDW -w com.polymicrosystems.carousel $currentCarousel "$slot"
	$DEBUGCMD $XATTRCMDW -w com.polymicrosystems.carousel.slot $currentSlot "$slot"
	# $XATTRCMD -l "$slot"
    done
    popd > /dev/null # back to carousels
done

