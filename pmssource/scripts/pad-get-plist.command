#!/bin/bash

TMPFILE=`mktemp -t pad.XXXXXX` || exit 1
PADFILE=~/Desktop/padinfo.text
cp /dev/null $PADFILE

find ~/Library/PickADisk -name "*.plist" > $TMPFILE

while read plist
do
    echo $plist >> $PADFILE
    cat "$plist" >>$PADFILE
    echo >> $PADFILE
done < $TMPFILE

