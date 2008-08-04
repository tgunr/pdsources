/*
 *  pmsDACALUtility.m
 *  PickADisc
 *
 *  Created by Jack Small on 7/16/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "pmsDACALUtility.h"

OSStatus DACALRegisterIconResource( CFStringRef theIconFile, OSType theIconType )
{
	CFURLRef	anIconURL = CFBundleCopyResourceURL( CFBundleGetMainBundle(), theIconFile, CFSTR("icns"), NULL );
	FSRef		anIconFS;
	Boolean		anIconFound = CFURLGetFSRef( anIconURL, &anIconFS );
	IconRef		anIconRef;
	OSStatus	anIconErr = -1;
	
	if( anIconFound ) anIconErr = RegisterIconRefFromFSRef( kDACALCreatorType, theIconType, &anIconFS, &anIconRef );
	
	if( anIconErr == 0 ) AcquireIconRef( anIconRef );
	if( anIconURL ) CFRelease( anIconURL );
	
	return( anIconErr );
}


Boolean	CFURLIsCarousel( CFURLRef url )
{
	CFStringRef		itemName = CFURLCopyLastPathComponent( url );
	CFRange			foundRange = CFStringFind( itemName, kDACALCarouselDocumentDotExtension, 0 );
	
	CFRelease( itemName );
	return( foundRange.length != 0 );
}

Boolean	CFURLIsSlot( CFURLRef url )
{
	CFStringRef		slotNumber = NULL;
	Boolean			isSlot = FALSE;
	
	slotNumber = CFURLCopyXattr( url, kDACALCarouselDocumentXAttrSlotKind, (OSStatus*)NULL );
	if( slotNumber != NULL ) 
	{	
		isSlot = TRUE;
		CFRelease( slotNumber );
	} else {
		CFURLRef	actualSlot = CFURLCreateCopyDeletingLastPathComponent( NULL, url );
		slotNumber = CFURLCopyXattr( actualSlot, kDACALCarouselDocumentXAttrSlotKind, (OSStatus*)NULL );
		if( slotNumber != NULL ) 
		{	
			//isSlot = TRUE;
			CFRelease( slotNumber );
		}
		CFRelease( actualSlot );
	}
	
	return( isSlot );
	
	/*
	 CFStringRef		itemName = CFURLCopyLastPathComponent( url );
	 CFRange			foundRange = CFStringFind( itemName, CFSTR("Slot "), 0 );
	 
	 CFRelease( itemName );
	 
	 if( foundRange.length == 0 )
	 {
	 CFURLRef	actualSlot = CFURLCreateCopyDeletingLastPathComponent( NULL, url );
	 itemName = CFURLCopyLastPathComponent( actualSlot );
	 foundRange = CFStringFind( itemName, CFSTR("Slot "), 0 );
	 
	 CFRelease( itemName );
	 CFRelease( actualSlot );
	 }
	 
	 return( foundRange.length != 0 );
	 */
}

DACALDeviceRef	CFURLCopyCarouselUUID( CFURLRef url )
{
	CFStringRef		slotIDString = NULL;
	CFUUIDRef		slotUUID = NULL;
	
	slotIDString = CFURLCopyXattr( url, kDACALCarouselDocumentXAttrCarousel, (OSStatus*)NULL );
	if( slotIDString != NULL ) slotUUID = CFUUIDCreateFromString(NULL, slotIDString );
	if( slotIDString != NULL ) CFRelease( slotIDString );
	
	return( (DACALDeviceRef)slotUUID );
}	

DACALSlotNum	CFURLGetSlotNumber( CFURLRef url, Boolean onlySlotFolders )
{
	DACALSlotNum	outSlot = 0;
	//	CFStringRef		slotTitle = NULL;
	CFStringRef		slotNumber = NULL;
	
	if( onlySlotFolders && !CFURLIsSlot(url) ) return outSlot;
	
	slotNumber = CFURLCopyXattr( url, kDACALCarouselDocumentXAttrSlot, (OSStatus*)NULL );
	if( slotNumber != NULL ) outSlot = CFStringGetIntValue( slotNumber );
	if( slotNumber != NULL ) CFRelease( slotNumber );
	
	return( outSlot );
	/*	
	 if( onlySlotFolders && !CFURLIsSlot(url) ) return outSlot;
	 
	 slotTitle = CFURLCopyLastPathComponent(url);
	 if( slotTitle != NULL )
	 {
	 slotNumber = CFStringCreateWithSubstring(NULL, slotTitle, CFRangeMake( CFStringGetLength(CFSTR("Slot ")), CFStringGetLength(slotTitle)));
	 if( slotNumber != NULL ) outSlot = CFStringGetIntValue( slotNumber );
	 }
	 
	 CFRelease( slotNumber ), slotNumber = NULL;
	 CFRelease( slotTitle ), slotTitle = NULL;
	 
	 if( outSlot == 0 )
	 {
	 CFURLRef	actualSlot = CFURLCreateCopyDeletingLastPathComponent( NULL, url );
	 slotTitle = CFURLCopyLastPathComponent(actualSlot);
	 if( slotTitle != NULL )
	 {
	 slotNumber = CFStringCreateWithSubstring(NULL, slotTitle, CFRangeMake( CFStringGetLength(CFSTR("Slot ")), CFStringGetLength(slotTitle)));
	 if( slotNumber != NULL ) outSlot = CFStringGetIntValue( slotNumber );
	 }
	 CFRelease( slotNumber ), slotNumber = NULL;
	 CFRelease( slotTitle ), slotTitle = NULL;
	 CFRelease( actualSlot ), actualSlot = NULL;
	 }
	 
	 return outSlot;
	 */
}

IconRef	CFURLGetIcon( CFAllocatorRef allocator, CFURLRef url, OSStatus* outError )
{
	FSRef			theFileRef;
	Boolean			isGoodFile = FALSE;
	OSStatus		outResult = paramErr;
	FSCatalogInfo	theCatInfo;
	HFSUniStr255	theFileName;
	SInt16			theFileLabel;
	
	IconRef			theOutputIcon = NULL;
	
	if( CFURLIsCarousel(url) ) {
		outResult = GetIconRef( kOnSystemDisk, kDACALCreatorType, kDACALCarouselsFolderType, &theOutputIcon );
		if( outResult != 0 ) printf( "GetIconRef: %d\n", (int)outResult );
		AcquireIconRef(theOutputIcon);
		goto BAIL;
	}
	
	if( CFURLIsSlot(url) ) {
		outResult = GetIconRef( kOnSystemDisk, kDACALCreatorType, kGenericCDROMIcon, &theOutputIcon );
		if( outResult != 0 ) printf( "GetIconRef: %d\n", (int)outResult );
		//else printf("Assigned disc icon!\n");
		AcquireIconRef(theOutputIcon);
		goto BAIL;
	}
	
	isGoodFile = CFURLGetFSRef( url, &theFileRef );
	if( !isGoodFile ) goto BAIL;	
	outResult = FSGetCatalogInfo(&theFileRef, kIconServicesCatalogInfoMask, &theCatInfo, &theFileName, NULL, NULL);
	if( outResult != 0 ) goto BAIL;
	outResult = GetIconRefFromFileInfo(&theFileRef, theFileName.length, (const UniChar*)&theFileName.unicode,
									   kIconServicesCatalogInfoMask, &theCatInfo, kIconServicesNormalUsageFlag, 
									   &theOutputIcon, &theFileLabel);
	
BAIL:
	if( outError != NULL ) *outError = outResult;
	return( theOutputIcon );
}

NSImage*	CFURLGetIconAsNSImage( CFAllocatorRef allocator, CFURLRef url, OSStatus* outError )
{
	IconRef	theItemIcon = CFURLGetIcon(allocator, url, outError);
	NSImage*	theItemImage = NULL;
	
	if( theItemIcon != NULL ) theItemImage = [[NSImage alloc]initWithIconRef:theItemIcon];
	if( theItemImage != NULL ) {
		[theItemImage setScalesWhenResized:YES];
		[theItemImage setSize:NSMakeSize( 16.0, 16.0 )];
	}
	
	return( theItemImage );
}

CFStringRef	CFURLCopyDisplayName( CFAllocatorRef allocator, CFURLRef url, OSStatus* outError )
{
	CFStringRef		theOutputName = NULL;
	OSStatus		theOutResult;
	
	theOutResult = 	LSCopyDisplayNameForURL(url, &theOutputName);
	
	if( outError != NULL ) *outError = theOutResult;
	return( theOutputName );
}	

/*	
 {
 FSRef			theFileRef;
 Boolean			isGoodFile = FALSE;
 OSStatus		outResult = paramErr;
 FSCatalogInfo	theCatInfo;
 HFSUniStr255	theFileName;
 
 CFStringRef		theOutputName = NULL;
 
 isGoodFile = CFURLGetFSRef( url, &theFileRef );
 if( !isGoodFile ) goto BAIL;	
 outResult = FSGetCatalogInfo(&theFileRef, kFSCatInfoNone, &theCatInfo, &theFileName, NULL, NULL);
 if( outResult != 0 ) goto BAIL;
 
 theOutputName = CFStringCreateWithCharacters(allocator, (const UniChar*)&theFileName.unicode, theFileName.length);
 
 BAIL:
 if( outError != NULL ) *outError = outResult;
 return( theOutputName );
 }
 */


Boolean	CFURLIsVisible( CFURLRef url )
{
	Boolean				isURLVisible = FALSE;
	FSRef				theFileRef;
	Boolean				isGoodFile = FALSE;
	OSStatus			outResult;
	LSItemInfoRecord	theFileInfo;
	
	isGoodFile = CFURLGetFSRef( url, &theFileRef );
	if( !isGoodFile ) goto BAIL;	
	
	outResult = LSCopyItemInfoForRef( &theFileRef, kLSRequestBasicFlagsOnly, &theFileInfo );
	if( outResult == noErr ) isURLVisible = ((theFileInfo.flags & kLSItemInfoIsInvisible) == 0);
	
BAIL:
	return( isURLVisible );
}


NSImage*	DACALGetIconImageForType( int	theType )
{
	OSStatus		outResult = paramErr;
	IconRef			theOutputIcon = NULL;
	NSImage*		theOutputImage = NULL;
	
	//	OSType			theIconCreator = 'DACi';
	//	OSType			theIconType = 'Crsl';
	
	if( theType == 0 ) goto BAIL;
	
	outResult = GetIconRef( kOnSystemDisk, kDACALCreatorType, theType, &theOutputIcon );
	if( outResult != 0 ) outResult = GetIconRef( kOnSystemDisk, kSystemIconsCreator, theType, &theOutputIcon );
	
	if( theOutputIcon != NULL ) theOutputImage = [[NSImage alloc]initWithIconRef:theOutputIcon];
	if( theOutputImage != NULL ) {
		[theOutputImage setScalesWhenResized:YES];
		[theOutputImage setSize:NSMakeSize( 16.0, 16.0 )];
	}
	
BAIL:
	return( theOutputImage );
}

