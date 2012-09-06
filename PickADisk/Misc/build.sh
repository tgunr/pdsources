#!/bin/bash -xvn
#  build.sh
#  PickADisk
#
#  Created by Dave Carlton on 9/6/12.
#  Copyright (c) 2012 PolyMicro Systems. All rights reserved.
logger "Starting PickADisk Xcode Script"

# Test for kill prefs file on each build
if [[ "$CONFIGURATION" == 'Debug Fresh Prefs' ]]; then
    if [ -e "$HOME/Library/Preferences/com.polymicrosystems.pickadisk.plist" ]; then
            logger "Removing prefs"
            rm -f "$HOME/Library/Preferences/com.polymicrosystems.pickadisk.plist"
    fi
fi

### If not releasing increment build number
if [[ ! "$CONFIGURATION" =~ 'Release' ]]; then
    /usr/bin/perl -pe 's/(BUILD_NUMBER = )(\d+)/$1.($2+1)/eg' -i "$SRCROOT/Misc/buildnumber.xcconfig"
fi

BUILD_NUMBER=`head -n 1 "$SRCROOT/Misc/buildnumber.xcconfig" | sed -e 's/BUILD_NUMBER = //'`
BUILD_VERSION=`tail -n 1 "$SRCROOT/Misc/releasenumber.xcconfig" | sed -e 's/VERSION_NUMBER = //'`
echo HERE

## Pre-release construction of release files
if [[ "$CONFIGURATION" == 'Release Test' ]]; then
    # copy build number over to release number
    # as long as we stay in a release mode this number will not change in case we have to run again
    RELEASE_NUMBER=$BUILD_NUMBER
    RELEASE_VERSION=$BUILD_VERSION

    # construct file paths
    ZIP_FILE=`echo "$PRODUCT_NAME-$VERSION_NUMBER-$RELEASE_NUMBER.zip" | tr "-" "_"`
    HTML_FILE=`echo "PAD-$VERSION_NUMBER-$RELEASE_NUMBER.html" | tr "-" "_"`

    # see if release notes file for this release already exists, may be 2nd or more build so only do it once
    RELEASE_NOTES_PATH=$SRCROOT/Sources/sparkle/support/releasenotes
if [[ ! -e "$RELEASE_NOTES_PATH/$HTML_FILE" ]] ; then
echo "$RELEASE_NOTES_PATH/$HTML_FILE"
cat >  "$RELEASE_NOTES_PATH/$HTML_FILE" <<End-of-html
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 TRANSITIONAL//EN">
<html>

<head>
<title>Version $RELEASE_VERSION Build $RELEASE_NUMBER</title>
<link href="../css/simplelist.css" type="text/css" rel="stylesheet" media="all">
</head>
<body>
<p class="p1" align="center">PickADisk Version $RELEASE_VERSION Build $RELEASE_NUMBER </p>
<ul class="ul1">
<li class="li1">Item1</li>
</ul>
</body>
</html>
End-of-html
fi

    open -a /Applications/TextEdit.app "$RELEASE_NOTES_PATH/$HTML_FILE"

    XML_UPDATE_FILE=$SRCROOT/Sources/sparkle/updates.xml
    TODAY_DATE=`date`

    # New item is in clipboard, paste it in
    pbcopy<<End-of-item
<item>
<title>Version $RELEASE_VERSION Build $BUILD_NUMBER</title>
<sparkle:releaseNotesLink>http://updates.pickadisk.com/trunk/support/releasenotes/$HTML_FILE</sparkle:releaseNotesLink>
<description>Version $RELEASE_VERSION Build $BUILD_NUMBER </description>
<pubDate>$TODAY_DATE</pubDate>
<enclosure sparkle:shortVersionString="$RELEASE_VERSION" sparkle:version="$RELEASE_NUMBER" url="http://updates.pickadisk.com/trunk/archives/$ZIP_FILE" type="application/octet-stream"/>
</item>
End-of-item

    open -a /Applications/Aquamacs.app "$XML_UPDATE_FILE"

    rsync -auv "$SRCROOT/Sources/sparkle/" "$SRCROOT/../../marketing/WebSite/updates/" --exclude=".*"
    pushd "$TARGET_BUILD_DIR" >/dev/null
    find "$WRAPPER_NAME" -name ".svn" -delete
    zip -q -r "$ZIP_FILE" "$WRAPPER_NAME"
    cp "$ZIP_FILE" "$SRCROOT/../../marketing/WebSite/updates/archives/"
    popd >/dev/null
    echo "Prelease checklist"
    echo "- Update updates.xml with new version, paste in from clip board"
    echo "- Update release notes"
    echo "- Update known issues"
    echo "- Update URL for new version, copy next line"
    echo "../updates/assets/updates/archives/$ZIP_FILE"
    echo "- Turn on local hosts for pickadisk.com"
    echo "- Publish site"
    echo "- Verify site"
    echo "- Change build to release"
    echo "- Verify not using local hosts"
fi

if [[ "$CONFIGURATION" == 'Release' ]]; then
    echo "Update remote web site"
    #rsync -auv /web/sites/pickadisk.com/ polymicrosystems.com:sites/staging.pickadisk.com/
fi
