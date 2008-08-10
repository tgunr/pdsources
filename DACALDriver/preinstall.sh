#!/bin/sh

# preinstall.sh
# DACALDriver
#
# Created by Dave Carlton on 8/9/08.
# Copyright 2008 PolyMicro Systems. All rights reserved.

KEXT="/System/Library/Extensions/DACALDriver.kext"

if [[ -e "$KEXT" ]] ; then
	kextstat|grep -i com.polymicrosystems.driver.DACALDriver
	if [[ $? == 0 ]] ; then
		logger "Unloading DACALDriver"
		kextunload "$KEXT"
	fi
fi
