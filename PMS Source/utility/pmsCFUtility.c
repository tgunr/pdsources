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


