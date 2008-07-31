/*
 *  pmsCFUtility.h
 *  PickADisc
 *
 *  Created by Jack Small on 7/16/08.
 *  Copyright 2008 Polymicrosystems. All rights reserved.
 *
 */

#include <ApplicationServices/ApplicationServices.h>
#include <CoreFoundation/CoreFoundation.h>

extern OSStatus		CFURLSetXattr( CFURLRef inURL, CFStringRef inKeyName, CFStringRef inKeyValue );
extern CFStringRef	CFURLCopyXattr( CFURLRef inURL, CFStringRef inKeyName, OSStatus* outError );

extern char*		CFStringCreateCString( CFStringRef theString, CFStringEncoding theEncoding );
extern CFStringRef	CFStringCreateFromCommandPipe( CFAllocatorRef inAllocator, CFURLRef inCommandURL, CFStringRef inCommandArgs, OSStatus* outError );

//
// WARNING: The CFStringSpeak function leaks theWords of each call because no copy is made and
// it creates a speach channel that never gets destroyed, although it is reused, if no channel is specified.
//

OSErr				CFStringSpeak( CFStringRef theWords, Boolean interrupt, SpeechChannel onChannel );





