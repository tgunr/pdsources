/*
 *  pmsCFUtility.c
 *  PickADisc
 *
 *  Created by Jack Small on 7/16/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "pmsCFUtility.h"
#include <sys/xattr.h>

OSStatus		CFURLSetXattr( CFURLRef inURL, CFStringRef inKeyName, CFStringRef inKeyValue )
{
	OSStatus		outResult = -1;
	UInt8			pathText[4096];
	const char*		keyText = CFStringCreateCString(inKeyName, kCFStringEncodingUTF8);
	void*			keyValue = NULL;
	size_t			keyValueSize = 0;
	Boolean			goodPath = FALSE;
	
	if( keyText == NULL ) goto EXIT;
	
	goodPath = CFURLGetFileSystemRepresentation( inURL, TRUE, (UInt8*)&pathText, 4096 );
	if( !goodPath ) goto EXIT;
	
	if( inKeyValue == NULL ) {
		if( removexattr( (const char *)&pathText, keyText, 0 ) == -1 ) outResult = errno;
		else outResult = 0;
		goto EXIT;
	}
	
	keyValue = CFStringCreateCString(inKeyValue, kCFStringEncodingUTF8);
	keyValueSize = strlen((const char*)keyValue);
	
	if( setxattr( (const char *)&pathText, keyText, keyValue, keyValueSize, 0, 0 ) == -1 ) outResult = errno;
	
EXIT:
	if( keyText != NULL ) free( (void*)keyText );
	if( keyValue != NULL ) free( keyValue );
	
	return outResult;	
}

CFStringRef		CFURLCopyXattr( CFURLRef inURL, CFStringRef inKeyName, OSStatus* outError )
{
	OSStatus		outResult = -1;
	UInt8			pathText[4096];
	const char*		keyText = CFStringCreateCString(inKeyName, kCFStringEncodingUTF8);
	void*			keyValue = NULL;
	size_t			keyValueSize = 0;
	Boolean			goodPath = FALSE;
	
	CFStringRef		keyValueString = NULL;
	
	if( keyText == NULL ) goto EXIT;
	
	goodPath = CFURLGetFileSystemRepresentation( inURL, TRUE, (UInt8*)&pathText, 4096 );
	if( !goodPath ) goto EXIT;
	
	keyValueSize = getxattr( (const char *)&pathText, keyText, NULL, 0, 0, 0 );
	if( keyValueSize == -1 ) goto EXIT;
	
	keyValue = (UInt8*)calloc( 1, keyValueSize+1 );
	if( keyValue == NULL) goto EXIT;
	
	keyValueSize = getxattr( (const char *)&pathText, keyText, keyValue, keyValueSize, 0, 0 );
	if( keyValueSize == -1 ) goto EXIT;
	
	keyValueString = CFStringCreateWithBytes( NULL, (const UInt8*)keyValue, (CFIndex)keyValueSize, kCFStringEncodingUTF8, FALSE );
	if( keyValueString != NULL ) outResult = 0;
	
EXIT:
	if( keyText != NULL ) free( (void*)keyText );
	if( keyValue != NULL ) free( keyValue );
	
	if( outError != NULL ) *outError = outResult;
	return keyValueString;	
}


char*			CFStringCreateCString( CFStringRef theString, CFStringEncoding theEncoding )
{
	char*		cstring;
	CFIndex			maxlen;
	Boolean			goodCoerce = FALSE;
	
	maxlen = CFStringGetMaximumSizeForEncoding( CFStringGetLength( theString ), theEncoding ) + 1;
	cstring = (char*)calloc( 1, maxlen );
	if( cstring != NULL ) goodCoerce = CFStringGetCString(theString, cstring, maxlen, theEncoding);
	if( !goodCoerce & (cstring != NULL) ) {
		free( cstring );
		cstring = NULL;
	}
	
	return( cstring );
}

static SpeechChannel g_CFUTILS_SYSTEM_SPEECHCHANNEL;

OSErr			CFStringSpeak( CFStringRef theWords, Boolean interrupt, SpeechChannel onChannel )
{
	if( g_CFUTILS_SYSTEM_SPEECHCHANNEL == NULL ) NewSpeechChannel( NULL, &g_CFUTILS_SYSTEM_SPEECHCHANNEL );
	if( g_CFUTILS_SYSTEM_SPEECHCHANNEL == NULL ) return( memFullErr );
	
	if( onChannel == NULL ) onChannel = g_CFUTILS_SYSTEM_SPEECHCHANNEL;
	
	OSErr				theErr;
	SInt32				theFlags = (interrupt) ? 0 : kNoSpeechInterrupt;
	char*				theText = NULL;
	unsigned long		theLength = 0;
	
	if( theWords != NULL ) {
		theText = CFStringCreateCString( theWords, kCFStringEncodingUTF8 );
		theLength = strlen( theText );
	}
	
	theErr = SpeakBuffer( onChannel, (const void*)theText, theLength, theFlags );
	//if(theErr != noErr) fprintf( stderr, "CFStringSpeak Error: %i", theErr );
	
	return theErr;
}

CFStringRef		CFStringCreateFromCommandPipe( CFAllocatorRef inAllocator, CFURLRef inCommandURL, CFStringRef inCommandArgs, OSStatus* outError )
{
	OSStatus		outResult = kIOReturnBadArgument;
	CFStringRef		outCFText = NULL;
//	CFStringRef		theCommand = CFSTR("carousel");
//	CFStringRef		errUnknown = CFSTR("carousel.sh:");
//	CFURLRef		commandURL = CFBundleCopyResourceURL( CFBundleGetMainBundle(), theCommand, CFSTR("sh"), NULL );
	CFStringRef		doCFCommand;
	char*			doCommand = NULL;
	char*			utf8Name = NULL;
	FILE*			pipe;
	int				pipeSize = 8192;
	
	
	if( inAllocator == NULL ) inAllocator = kCFAllocatorDefault;
	
	doCFCommand = CFStringCreateWithFormat(	inAllocator, NULL, CFSTR("\"%@\" %@"), inCommandURL, inCommandArgs );
	if( doCFCommand == NULL ) goto BAIL;
	
	//	NSLog( (NSString*)doCFCommand );
	
	doCommand = CFStringCreateCString( doCFCommand, kCFStringEncodingUTF8 );	
	if( doCommand == NULL ) goto BAIL;
	
	//	printf("Carousel command: %s", doCommand);
	
	utf8Name = (char*)calloc(1, pipeSize);
	if( doCommand == NULL ) goto BAIL;
	
	pipe = popen( doCommand, "r" );
	if ( pipe ) {
		pipeSize = fread( utf8Name, 1, pipeSize, pipe );
		outResult = pclose( pipe );
	}
	
	if( pipeSize > 2 ) {
		utf8Name[pipeSize-1] = 0;
		outCFText = CFStringCreateWithCString( inAllocator, utf8Name, kCFStringEncodingUTF8 );
		
//		if( CFStringHasPrefix( outCFText, errUnknown ) == TRUE ) {
//			CFRelease( outCFText );
//			outCFText = (CFStringRef)NULL;
//		}
	} 
	
BAIL:
	if( outError ) *outError = outResult;
	if( utf8Name ) free( utf8Name );
	if( doCFCommand ) CFRelease( doCFCommand );
	//	if( commandURL ) CFRelease( commandURL );
	//	if( commandPathURL ) CFRelease( commandPathURL );
	if( doCommand ) free( doCommand );
	return( outCFText );
}
