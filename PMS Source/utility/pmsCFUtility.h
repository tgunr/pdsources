/*
 *  pmsCFUtility.h
 *  PickADisc
 *
 *  Created by Jack Small on 7/16/08.
 *  Copyright 2008 Polymicrosystems. All rights reserved.
 *
 */

#include <CoreFoundation/CoreFoundation.h>

extern OSStatus			CFURLSetXattr( CFURLRef inURL, CFStringRef inKeyName, CFStringRef inKeyValue );
extern CFStringRef		CFURLCopyXattr( CFURLRef inURL, CFStringRef inKeyName, OSStatus* outError );

extern char*			CFStringCreateCString( CFStringRef theString, CFStringEncoding theEncoding );



