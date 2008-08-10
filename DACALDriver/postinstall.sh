#!/bin/sh

# postinstall.sh
# DACALDriver
#
# Created by Dave Carlton on 8/9/08.
# Copyright 2008 PolyMicro Systems. All rights reserved.

KEXT="/System/Library/Extensions/DACALDriver.kext"

if [[ -e "$KEXT" ]] ; then
	logger "Loading DACALDriver"
	kextload "$KEXT"
	touch `dirname $KEXT`
fi
