//
//  DACALVolume.m
//  PickADisk
//
//  Created by Jack Small on 9/9/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "DACALVolume.h"
#import <IOKit/IOMessage.h>
#import <IOKit/storage/IODVDMedia.h>
#import "DACALSlot.h"
#import "dacalconstants.h"
#import "DACALTreeDataSource.h"
#import "NSData_Extensions.h"
#import "NSString_Extensions.h"
#import "AppController.h"
#import "PADIndexToolbarController.h"
#import "DACALVolumeService.h"
#import "DACALDeviceNode.h"

@implementation DACALVolume

int		DACALVolume_nextIconID = 0;

-(void)dealloc
{
	if( padIdentifier != nil )	[padIdentifier release];
	if( padKnownHost != nil )	[padKnownHost release];
	if( padKnownSlot != nil )	[padKnownSlot release];
	if( padFlavorGuess != nil )	[padFlavorGuess release];
	
	padIdentifier	= nil;
	padKnownHost	= nil;
	padKnownSlot	= nil;
	padFlavorGuess	= nil;
	padKnownVolume	= NO;
	
	[super dealloc];
}

-(NSString*)padIdentifier
	{ return padIdentifier; }

-(NSString*)padKnownHost
	{ return padKnownHost; }

-(BOOL)padKnownVolume
	{ return padKnownVolume; }

-(DACALSlot*)padKnownSlot
{ return padKnownSlot; }

-(void)setPadKnownSlot:(DACALSlot*)newSlot;
{
	if( !padKnownSlot || ![padKnownSlot isEqual:newSlot] )
	{
		if( newSlot )
            [newSlot retain];
		if( padKnownSlot )
            [padKnownSlot release];
		padKnownSlot = newSlot;
		padKnownVolume = (padKnownSlot != nil);
	}
}

-(DACALDeviceRef)padKnownDevice { return padKnownDevice; }

-(void)setPadKnownDevice:(DACALDeviceRef)newDevice {
	PMLOG(1, @"padKnownDevice: %x newDevice: %x", padKnownDevice, newDevice);
	if( !padKnownDevice )
		padKnownDevice = newDevice;
}

-(NSString*)padFlavorGuess
	{ return padFlavorGuess; }

-(void)setPadFlavorGuess:(NSString*)guessFlavor
{
	if( !padFlavorGuess || ![padFlavorGuess isEqual:guessFlavor] )
	{
		if( guessFlavor ) [guessFlavor retain];
		if( padFlavorGuess ) [padFlavorGuess release];
		padFlavorGuess = guessFlavor;
	}
}


-(BOOL)isIdentifiedAs:(NSString*)testID
{
	if( padIdentifier )
		return [padIdentifier isEqual:testID];
	else if( testID == nil )
		return YES;
	
	return NO;
}

-(BOOL)isIndexable {
    return YES;
    return !padKnownVolume;
}

-(NSString*)guessPADFlavor
{
	NSString*		outGuess = nil;
	NSArray*		volumeDirectory = nil;
	NSEnumerator*	volumesEnumAIFF = nil;
	NSEnumerator*	volumesEnumOnce = nil;
	NSInteger		dirCount = 0;
	NSString*		workString = nil;
	NSURL*			workURL = nil;
	Boolean			goodItem = FALSE;
	
	const	NSString*	aiffExtension = @"aiff";
	const	NSString*	mp3Folder = @"MP3";
	const	NSString*	videoFolder	= @"VIDEO_TS";
	const	NSString*	dcimFolder = @"DCIM";
	const	NSString*	iphotoManifest = @"IPHOTO.XML";
	
	if( padFlavorGuess != nil ) return padFlavorGuess;
	
	volumeDirectory = [self topLevelDirectory];
	
	if( !volumeDirectory )
	{
		PMLOG(2, @"Could not read volume directory: %@", self);
		goto HAVEGUESS;
	}
	dirCount = [volumeDirectory count];
	volumesEnumAIFF = [volumeDirectory objectEnumerator];
	volumesEnumOnce = [volumeDirectory objectEnumerator];

	//	Music CD?
	//		Check if all the visible items have an "aiff" extension
	while( workURL = (NSURL*)[volumesEnumAIFF nextObject] )
	{
		workString = nil;
		goodItem = FALSE;
		if( !workURL ) break;
		if( !CFURLIsVisible( (CFURLRef)workURL ) ) continue;
		workString = (NSString*)CFURLCopyPathExtension( (CFURLRef)workURL );
		if( [aiffExtension isEqual:workString] == NO ) break;
		goodItem = TRUE;
	}	
	if( goodItem ) {
		outGuess = PADINDEX_FLAVORVALUE_MUSIC;
		goto HAVEGUESS;
	}
	
	//	One shots
	//		Check if any item matches a known value
	goodItem = FALSE;
	while( workURL = (NSURL*)[volumesEnumOnce nextObject] )
	{
		workString = nil;
		if( !workURL ) break;
		workString = (NSString*)CFURLCopyLastPathComponent( (CFURLRef)workURL );
		if( [videoFolder isEqual:workString] == YES )		//	is movie?
		{
			outGuess = PADINDEX_FLAVORVALUE_MOVIE;
			goodItem = TRUE;
			break;
		}
		if( [mp3Folder isEqual:workString] == YES ) {		//	is mp3s?
			outGuess = PADINDEX_FLAVORVALUE_MUSIC;
			goodItem = TRUE;
			break;
		}
		if( [dcimFolder isEqual:workString] == YES ) {		//	is pictures?
			outGuess = PADINDEX_FLAVORVALUE_IMAGE;
			goodItem = TRUE;
			break;
		}
		if( [iphotoManifest isEqual:workString] == YES ) {	//	is iPhoto?
			outGuess = PADINDEX_FLAVORVALUE_IMAGE;
			goodItem = TRUE;
			break;
		}
	}	
	if( goodItem ) goto HAVEGUESS;
	
	//	Shot in the dark
	if( dirCount > 2 ) outGuess = PADINDEX_FLAVORVALUE_FILES;
	
HAVEGUESS:
	
	if( outGuess != nil )
		[self setPadFlavorGuess:outGuess];
	
	return outGuess;
}

-(DACALVolume*)initForMountURL:(NSURL*)mountURL
{
	CFDictionaryRef	volumeData = NULL;
	
	if( self = [super init] )
	{
		FSRef			theRef;
		FSCatalogInfo	theInfo;
		OSStatus		theErr;
		CFDictionaryRef	workDict = NULL;
		CFURLRef		iconFileURL = NULL;
		CFStringRef		bundleIDString = NULL;
		CFStringRef		iconResFile = NULL;
		CFStringRef		volumeName = NULL;
		//		CFStringRef		volumeUUIDString = NULL;
		CFStringRef		mediaName = NULL;
		NSString*		deviceModel = NULL;
		Boolean			goodModel = FALSE;
		//		CFBooleanRef	wholeMedia = kCFBooleanFalse;
		
		volumeDiskRef	= NULL;
		mediaType		= nil;
		mediaSize		= nil;
		mediaIcon		= NULL;
		mediaUUID		= NULL;
		padIdentifier	= nil;
		padKnownVolume	= NO;
		padKnownSlot	= nil;
		padFlavorGuess	= nil;
		
		//	The Volume FSRef
		theErr = !CFURLGetFSRef((CFURLRef)mountURL, &theRef );
		if( theErr != 0 ) 
			goto FAILED;
		
		//	The Volume URL
		volumeURL = [mountURL copy];
		
		//	The FSVolumeRefNum
		theErr = FSGetCatalogInfo( &theRef, kFSCatInfoVolume, &theInfo, NULL, NULL, NULL );
		if( theErr != 0 ) 
			goto FAILED;
		mountVolume = theInfo.volume;
		
		//	Locate volume DADisk info
		theErr = FSCopyDADiskForVolume( mountVolume, &volumeDiskRef );
		if( theErr != 0 ) 
			goto FAILED;
		
		volumeData = DADiskCopyDescription( volumeDiskRef );
		if( volumeData == NULL ) 
			goto FAILED;
		
		//CFShow( volumeData );
		
		//	Extract the volume name
		volumeName = CFDictionaryGetValue( volumeData, CFSTR("DAVolumeName") );
		if( volumeName != NULL )
			mediaTitle = [[NSString alloc] initWithString:(NSString*)volumeName];
		else {
			//	Falback on media name
			volumeName = CFDictionaryGetValue( volumeData, CFSTR("DAMediaName") );
			if( volumeName )
				mediaTitle = [[NSString alloc] initWithString:(NSString*)volumeName];
		}
		
		if( mediaTitle == nil )		// No title?  Something fishy.
			goto MISMATCH;
		
		//	The volume UUID doesn't exist for all volumes
		mediaUUID = CFDictionaryGetValue( volumeData, CFSTR("DAVolumeUUID") );
		if( mediaUUID != NULL ) {
			mediaUUID = CFUUIDCreateFromUUIDBytes( kCFAllocatorDefault, CFUUIDGetUUIDBytes(mediaUUID) );
			//padIdentifier = (NSString*)CFUUIDCreateString( kCFAllocatorDefault, mediaUUID );
		}
		
		//	These things disqualify the volume from our list
		{
			//	Whole Media tag doesn't seem to work for some media
			//wholeMedia = CFDictionaryGetValue( volumeData, CFSTR("DAMediaWhole") );
			//if( CFEqual( wholeMedia, kCFBooleanFalse ) ) goto MISMATCH;
			
			deviceModel = (NSString*)CFDictionaryGetValue( volumeData, CFSTR("DADeviceModel") );
			if( deviceModel == NULL ) 
				goto MISMATCH;
			
			//	Primitive but effective, only allow devices that have discs
			if( [deviceModel rangeOfString:@"CD"].length > 0 ) goodModel = TRUE;
			else if( [deviceModel rangeOfString:@"DVD"].length > 0 ) goodModel = TRUE;
			else if( [deviceModel rangeOfString:@"BD"].length > 0 ) goodModel = TRUE;
			
			if( !goodModel ) 
				goto MISMATCH;
			
			//	Grab a nonautoreleased copy of the media kind
			mediaName = CFDictionaryGetValue( volumeData, CFSTR("DAMediaKind") );
			if( mediaName != NULL )
				mediaType = [[NSString alloc] initWithString:(NSString*)mediaName];
			else 
				goto MISMATCH;
		}
		
		//	Save the disc size
		mediaSize = (NSNumber*)CFDictionaryGetValue( volumeData, CFSTR("DAMediaSize") );
		if( mediaSize ) mediaSize = (NSNumber*)CFRetain( mediaSize );
		
		if( mediaSize )
			PMLOG(2, @"Media Size: %@", [NSString stringFromByteCount:mediaSize]);
		
		//	Aquire the media "type" icon
		workDict = CFDictionaryGetValue( volumeData, CFSTR("DAMediaIcon") );
		if( workDict )
		{
			bundleIDString = CFDictionaryGetValue( workDict, CFSTR("CFBundleIdentifier") );
			iconResFile = CFDictionaryGetValue( workDict, CFSTR("IOBundleResourceFile") );
			
			if( iconResFile && bundleIDString ) {
				
				// Lazy Init the kext bundle identifers
				[[DACALVolumeService sharedVolumeService] lazyInitKextBundles];
				
				CFBundleRef		theIconBundle = CFBundleGetBundleWithIdentifier( bundleIDString );
				if( theIconBundle )
					iconFileURL = CFBundleCopyResourceURL( theIconBundle, iconResFile, NULL, NULL );
				if( iconFileURL ) {
					CFURLGetFSRef( iconFileURL, &iconFileRef );
					//if( iconFileURL ) CFShow( iconFileURL );
					//else PMLOG(2,  @"Bad Icon File URL: Bundle:%@ ID:%@ Name:%@", theIconBundle, bundleIDString, iconResFile );
					CFRelease(iconFileURL);
				}
			}
			
			if( FSIsFSRefValid(&iconFileRef) )
				RegisterIconRefFromFSRef( kDACALCarouselsFolderType, DACALVolume_nextIconID++, &iconFileRef, &mediaIcon );
		}
		
		//if( [self isDVD] == YES )
		{
			NSMutableDictionary*	dvdInfo = [self getDVDMediaInfo];				// autoreleased
			if( dvdInfo != nil )
			{
				//	First add in some others for more uniqueness
				//	[dvdInfo addEntryFromDictionary:volumeData forKey:@""];
				
				//[dvdInfo addEntryFromDictionary:(NSDictionary*)volumeData forKey:@"DAMediaBSDMajor"];
				//[dvdInfo addEntryFromDictionary:(NSDictionary*)volumeData forKey:@"DAMediaBSDMinor"];
				[dvdInfo addEntryFromDictionary:(NSDictionary*)volumeData forKey:@"DAMediaBlockSize"];
				[dvdInfo addEntryFromDictionary:(NSDictionary*)volumeData forKey:@"DAMediaContent"];
				[dvdInfo addEntryFromDictionary:(NSDictionary*)volumeData forKey:@"DAMediaName"];
				[dvdInfo addEntryFromDictionary:(NSDictionary*)volumeData forKey:@"DAMediaSize"];
				[dvdInfo addEntryFromDictionary:(NSDictionary*)volumeData forKey:@"DAMediaWhole"];
				[dvdInfo addEntryFromDictionary:(NSDictionary*)volumeData forKey:@"DAMediaWritable"];
				[dvdInfo addEntryFromDictionary:(NSDictionary*)volumeData forKey:@"DAVolumeKind"];
				[dvdInfo addEntryFromDictionary:(NSDictionary*)volumeData forKey:@"DAVolumeMountable"];
				[dvdInfo addEntryFromDictionary:(NSDictionary*)volumeData forKey:@"DAVolumeName"];
				[dvdInfo addEntryFromDictionary:(NSDictionary*)volumeData forKey:@"DAVolumeUUID"];
				//[dvdInfo addEntryFromDictionary:volumeData forKey:@""];
				//[dvdInfo addEntryFromDictionary:volumeData forKey:@""];
				//[dvdInfo addEntryFromDictionary:volumeData forKey:@""];
				
				CFShow( volumeData );
				PMLOG(2, @"DVD Info Dict: %@", dvdInfo);
				PMLOG(2, @"DVD Info Dict Key Count: %i", [dvdInfo count]);
				
				infoMD5 = [dvdInfo md5String];
				
				padIdentifier = [[NSString alloc] initWithString:infoMD5];
				PMLOG(2, @"Disc: %@\nProposed DACDiscKey: %@", self, infoMD5);
				// save the id?
			} else {
				
				//	Try a hash of the .TOC.plist if it exists...
				
				NSURL*			tocURL = [NSURL URLWithString:@".TOC.plist" relativeToURL:[self volumeURL]];
				NSError*		tocErr = nil;
				NSString*		tocFile = nil;
				
				if( tocURL != nil ) {
					tocFile = [NSString stringWithContentsOfURL:tocURL encoding:NSUTF8StringEncoding error:&tocErr];
					
					if( tocFile )
					{
						NSString*	hashTOC = [tocFile md5String];
						if( hashTOC ) {
							padIdentifier = [[NSString alloc] initWithString:hashTOC];
							PMLOG(2, @"TOC DACDiskKey: %@", hashTOC);
						}
					}
				}
				
			}
			
		}
		
		//	Fallback on a hash of the top level directory
		if( !padIdentifier )
		{
			NSArray*	topLevel = [[self topLevelDirectory] arrayOfPathsFromURLs];
			NSData*		outData = (NSData*)CFPropertyListCreateXMLData( kCFAllocatorDefault, (CFPropertyListRef)topLevel );
			
			if( outData != nil ) {
				NSString* md5_String = [outData md5String];
				[outData release];
				//if( padIdentifier == nil )
				padIdentifier = [[NSString alloc] initWithString:md5_String];
				
				PMLOG(2, @"Fallback DACDiscKey: %@", md5_String);
			}
		}
		
		if( padIdentifier == nil )
			PMLOG(2, @"Warning!! Nil Identifier! Volume: %@", self);
		
		DACALSlot*	workSlot = nil;
		
		if( padIdentifier ) {
			CFStringRef cfStr = (CFStringRef)padIdentifier;
			workSlot = DACALDeviceSlotForSlotIdentifier(cfStr);
			if( workSlot ) {
				padKnownVolume = YES;
				padKnownSlot = [workSlot retain];
				PMLOG(2, @"Volume Identified As: %@", padKnownSlot);
			}
		}
	}	// (if self =)
	
	padKnownHost = [[NSString alloc] initWithString:[[NSHost currentHost] name]];
	
	if( volumeData != NULL ) 
		CFRelease( volumeData );
	return self;
	
MISMATCH:
	//	if( gVerbose == YES ) {
	//		PMLOG(2, @"Media mismatch: %@", [self volumeURL]);
	//		if(volumeData != NULL)
	//			CFShow( volumeData );
	//}
	
FAILED:
	if( volumeData != NULL ) 
		CFRelease( volumeData );
	[self dealloc];
	return nil;
}


+(DACALVolume *)volumeForMountURL: (NSURL *) mountURL
{
	return (DACALVolume *)[[self alloc] initForMountURL: mountURL];
}

+(NSArray*)detectedMounts:(NSArray*)newMounts
{
	NSArray*			outMounts = nil;
	int					newIndex, newCount = [newMounts count];
	NSMutableArray*		newList = [[NSMutableArray alloc] initWithCapacity:newCount];
	NSURL*				newItemURL;
	DACALVolume*			newVolume = nil;
	
	//if( (newList == nil) || (newCount == 0) ) return outMounts;
	
	for( newIndex=0; newIndex < newCount; newIndex++ ) {
		newItemURL = (NSURL*)[newMounts objectAtIndex:newIndex];
		newVolume = [DACALVolume volumeForMountURL:newItemURL];
		if( newVolume ) 
			[newList addObject:newVolume];
	}
	
	if( [newList count] > 0 )
		outMounts = [NSArray arrayWithArray:newList];
	
	[newList release];
	
	return outMounts;
}

-(BOOL)ejectVolume
{
	if( padIdentifier )
		[[DACALVolumeService sharedVolumeService] addPendingUnmount:padIdentifier];
	
	DACALDeviceNode *theDevice = [padKnownSlot slotDevice];
	BOOL result = [super ejectVolume];
	return result;
}

-(NSString*)description
{ 
	return [NSString stringWithFormat:@"%@ Title:%@ DACID:%@",[super description], [self mediaTitle], [self padIdentifier]]; 
}


@end		//	DACALVolume




