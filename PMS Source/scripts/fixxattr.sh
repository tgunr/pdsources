#!/bin/bash -x
#  fixxattr
#
#  Created by Dave Carlton on 2008-07-09.
#  Copyright (c) 2008 polyMicro Systems. All rights reserved.
#
XATTRCMD="/usr/bin/xattr"

cd "$HOME/Library/Carousels.1"
for carousel in *.carousel ; do
	echo "Fixing $carousel"
	carouseluuid=${carousel%.carousel}
	$XATTRCMD -w com.polymicrosystems.pickadisc.carousel $carouseluuid "$carousel"
	$XATTRCMD -w com.polymicrosystems.pickadisc.carousel.slot $slotnum "$carousel"
	$XATTRCMD -w com.polymicrosystems.pickadisc.kind folder "$carousel"
	pushd "$carousel"
	for slot in Slot* ; do
		echo "Fixing $slot"
		slotnum="${slot##?????}"
		$XATTRCMD -w com.polymicrosystems.pickadisc.carousel $carouseluuid "$slot"
		$XATTRCMD -w com.polymicrosystems.pickadisc.carousel.slot $slotnum "$slot"
		$XATTRCMD -w com.polymicrosystems.pickadisc.kind folder "$slot"
		pushd "$slot"
		find . -maxdepth 1 -exec $XATTRCMD -w com.polymicrosystems.pickadisc.carousel $carouseluuid {} \; \
		-exec $XATTRCMD -w com.polymicrosystems.pickadisc.carousel.slot $slotnum {} \; \
		-exec $XATTRCMD -w com.polymicrosystems.pickadisc.kind data {} \;
		popd 
	done
	popd
done