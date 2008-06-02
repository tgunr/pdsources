#!/bin/bash 
#  fix-xattr
#
#  Created by Dave Carlton on 2008-06-01.
#  Copyright (c) 2008 polyMicro Systems. All rights reserved.
#

XATTRCMD=/Users/davec/bin/xattr
XATTRCMDW=/usr/bin/xattr

cd ~/Library/Carousels
for carousel in Carousel*[0-9] ; do 
	pushd "$carousel" >/dev/null
	export currentCarousel="${carousel#Carousel }"
	for slot in Slot*[0-9] ; do
		pushd "$slot" >/dev/null
		export currentSlot="${slot#Slot }"
		for file in * ; do
			echo "`pwd`/$file: C=$currentCarousel S=$currentSlot"
			xattrs=`$XATTRCMD -l "$file"`
			for xattr in $xattrs ; do
				# echo $xattr
				if [[ "$xattr" != "" ]] ; then
					# echo $XATTRCMDW -d ${xattr%=*} "$file"
					$XATTRCMDW -d ${xattr%=*} "$file" >/dev/null
				fi
			done
			$XATTRCMDW -w com.polymicrosystems.carousel $currentCarousel "$file"
			$XATTRCMDW -w com.polymicrosystems.carousel.slot $currentSlot "$file"
		done
		popd > /dev/null
		$XATTRCMDW -w com.polymicrosystems.carousel $currentCarousel "$slot"
		$XATTRCMDW -w com.polymicrosystems.carousel.slot $currentSlot "$slot"
		# $XATTRCMD -l "$slot"
	done
	popd > /dev/null
done
