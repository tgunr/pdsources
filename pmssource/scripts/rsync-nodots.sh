#!/bin/bash -x
#  rsync-nodots folder folder
#
#  Created by Dave Carlton on 2008-08-02.
#  Copyright (c) 2008 polyMicro Systems. All rights reserved.
#

CMDNAME=`basename "$0"`
if [[ $# != 2 ]] ; then
	echo "$CMDNAME: Needs 2 folders, source and target"
	exit 1
fi

rsync -av --exclude=".*" "$1" "$2"