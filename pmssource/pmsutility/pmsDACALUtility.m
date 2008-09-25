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
	
	slotNumber = CFURLCopyXattr( kCFAllocatorDefault, url, kDACALCarouselDocumentXAttrSlotAddDate, (OSStatus*)NULL );
	if( slotNumber != NULL ) 
	{	
		isSlot = TRUE;
		CFRelease( slotNumber );
	} 
	
	return( isSlot );
}

Boolean			CFURLIsTopInSlot( CFAllocatorRef inAllocator, CFURLRef url )
{
	Boolean			isSlot = FALSE;
	CFURLRef		actualSlot = CFURLCreateCopyDeletingLastPathComponent( inAllocator, url );

	if( actualSlot ) {
		isSlot = CFURLIsSlot( actualSlot );		// unfortunately this 
		CFRelease( actualSlot );
	}
	return( isSlot );
}	

DACALDeviceRef	CFURLCopyCarouselUUID( CFAllocatorRef inAllocator, CFURLRef url )
{
	CFStringRef		slotIDString = NULL;
	CFUUIDRef		slotUUID = NULL;
	
	slotIDString = CFURLCopyXattr( inAllocator, url, kDACALCarouselDocumentXAttrCarousel, (OSStatus*)NULL );
	if( slotIDString != NULL ) slotUUID = CFUUIDCreateFromString(inAllocator, slotIDString );
	if( slotIDString != NULL ) CFRelease( slotIDString );
	
	return( (DACALDeviceRef)slotUUID );
}	

DACALSlotNum	CFURLGetSlotNumber( CFURLRef url, Boolean onlySlotFolders )
{
	DACALSlotNum	outSlot = 0;
	//	CFStringRef		slotTitle = NULL;
	CFStringRef		slotNumber = NULL;
	
	if( onlySlotFolders && !CFURLIsSlot(url) ) return outSlot;
	
	slotNumber = CFURLCopyXattr( kCFAllocatorDefault, url, kDACALCarouselDocumentXAttrSlot, (OSStatus*)NULL );
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
	
	CFURLRef		theSlotTopPath = CFURLCreateCopyDeletingLastPathComponent( allocator, url );
	//CFStringRef		slotIconFlavor = NULL;
	OSType			slotIconType = kGenericCDROMIcon;

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
	
	if( (theSlotTopPath != NULL ) && CFURLIsSlot( theSlotTopPath ) ) {
		//slotIconFlavor = CFURLCopyItemFlavor( theSlotTopPath, &outResult );
		//if( [(NSString*)PADINDEX_FLAVORVALUE_MUSIC compare:(NSString*)slotIconFlavor] == NSOrderedSame )
		//	slotIconType = 'cdda';				// CDAudioVolume
		//else if( [(NSString*)PADINDEX_FLAVORVALUE_MOVIE compare:(NSString*)slotIconFlavor] == NSOrderedSame )
		//	slotIconType = 'dvd ';				// public.dvd-media
		//else
		//	slotIconType = kGenericCDROMIcon;   // public.cd-media
		slotIconType = kGenericCDROMIcon;   
		theOutputIcon = DACALGetIconRefForType(slotIconType);
		//AcquireIconRef(theOutputIcon);
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

CFStringRef	CFURLCopyReferenceTitle( CFAllocatorRef inAllocator, CFURLRef url, OSStatus* outError )
{
	CFStringRef		itemName = NULL;
	
	itemName = CFURLCopyXattr( inAllocator, url, kDACALCarouselDocumentXAttrUserTitle, outError );
	if( itemName == NULL ) itemName = CFURLCopyDisplayName( inAllocator, url, outError );
	
	return( itemName );
}

OSStatus	CFURLSetReferenceTitle( CFURLRef url, CFStringRef newTitle )
{	
	return CFURLSetXattr( url, kDACALCarouselDocumentXAttrUserTitle, newTitle );
}


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

IconRef		DACALGetIconRefForType( int	theType )
{
	OSStatus		outResult = paramErr;
	IconRef			theOutputIcon = NULL;
	
	if( theType == 0 ) goto BAIL;
	
	outResult = GetIconRef( kOnSystemDisk, kDACALCreatorType, theType, &theOutputIcon );
	if( outResult != 0 ) outResult = GetIconRef( kOnSystemDisk, kSystemIconsCreator, theType, &theOutputIcon );
	
BAIL:
	return( theOutputIcon );
}

NSImage*	DACALGetIconImageForType( int	theType )
{
	OSStatus		outResult = paramErr;
	IconRef			theOutputIcon = NULL;
	NSImage*		theOutputImage = NULL;
	
	//	OSType			theIconCreator = 'DACi';
	//	OSType			theIconType = 'Crsl';
	
	if( theType == 0 ) goto BAIL;
	
	if( theType == 'morI' ) theType = 'morÄ';
	
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

CFDateRef	CFURLCopyDateSlotAdded( CFAllocatorRef inAllocator, CFURLRef url, SInt32* outError )
{
	SInt32			theErr = kCFURLUnknownError;
	CFDateRef		theDate = NULL;
	
	DACALDeviceRef	theBox = CFURLCopyCarouselUUID( inAllocator, url );
	DACALSlotNum	theSlot = CFURLGetSlotNumber( url, FALSE );
	
	CFURLRef		theSlotURL = DACALSlotCopyPath( theBox, theSlot, (DACALResult*)&theErr );
	CFStringRef		theSlotDate = NULL;
	
	if( theSlotURL ) {			
		theSlotDate = CFURLCopyXattr( inAllocator, theSlotURL, kDACALCarouselDocumentXAttrSlotAddDate, &theErr );
		if(theErr != 0) theDate = (CFDateRef)[NSDate dateWithString:(NSString*)theSlotDate];
		if(!theDate) theDate = CFURLCopyDateCreated( inAllocator, theSlotURL, &theErr );			// backup for existing slots
	}
		
	if( outError ) *outError = theErr;
	return( theDate );
}

CFStringRef	CFURLCopyItemFlavor( CFURLRef url, OSStatus* outError )
{	
//	SInt32			theErr = kCFURLUnknownError;
	CFStringRef		newFlav = CFURLCopyXattr( kCFAllocatorDefault, url, kDACALCarouselDocumentXAttrSlotKind, outError ); 
	DACALDeviceRef	theBox = CFURLCopyCarouselUUID( NULL, url );
	DACALSlotNum	theSlot = CFURLGetSlotNumber( url, FALSE );
	
	CFURLRef		theSlotURL = DACALSlotCopyPath( theBox, theSlot, (DACALResult*)outError );
	
	if( !newFlav ) newFlav =  CFURLCopyXattr( kCFAllocatorDefault, theSlotURL, kDACALCarouselDocumentXAttrSlotKind, outError ); 
	
	return( newFlav );
}

OSStatus		CFURLSetItemFlavor( CFURLRef url, CFStringRef newFlavor )
{	return CFURLSetXattr( url, kDACALCarouselDocumentXAttrSlotKind, newFlavor ); }

NSImage*		DACALCreateImageRefForFlavor( NSString* flavorName )
{
	OSType			genericIconType = 'gFil';

	if( [(NSString*)PADINDEX_FLAVORVALUE_MUSIC compare:(NSString*)flavorName] == NSOrderedSame )
		genericIconType = 'gMus';				// CDAudioVolume
	else if( [(NSString*)PADINDEX_FLAVORVALUE_MOVIE compare:(NSString*)flavorName] == NSOrderedSame )
		genericIconType = 'gMov';				// public.dvd-media
	else if( [(NSString*)PADINDEX_FLAVORVALUE_IMAGE compare:(NSString*)flavorName] == NSOrderedSame )
		genericIconType = 'gImg';				// generic-image

	return( DACALGetIconImageForType(genericIconType) );
}







