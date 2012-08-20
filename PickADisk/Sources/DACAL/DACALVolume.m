//
//  DACVolume.m
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <DACAL/dacalconstants.h>
#import "DACVolume.h"
#import "PADLifeCycleSetup.h"
#import "dacallib.h"
#import "AppController.h"
#import "DACALTreeDataSource.h"

@implementation DACVolume

int		DACVolume_nextIconID = 0;

-(void)dealloc
{
	if( volumeDiskRef != NULL )	CFRelease( volumeDiskRef );
	if( mediaTitle != nil )		[mediaTitle release];
	if( mediaType != nil )		[mediaType release];
	if( mediaSize != nil )		[mediaSize release];
	if( mediaIcon != NULL ) 
		if( IsValidIconRef( mediaIcon ) )
								ReleaseIconRef( mediaIcon );
	if( mediaUUID != NULL )		CFRelease( mediaUUID );
	if( padIdentifier != nil )	[padIdentifier release];
	if( padKnownHost != nil )	[padKnownHost release];
	if( padKnownSlot != nil )	[padKnownSlot release];
	if( padFlavorGuess != nil )	[padFlavorGuess release];
	
	volumeDiskRef	= NULL;
	mediaTitle		= nil;
	mediaType		= nil;
	mediaSize		= nil;
	mediaIcon		= NULL;
	mediaUUID		= NULL;
	padIdentifier	= nil;
	padKnownHost	= nil;
	padKnownSlot	= nil;
	padFlavorGuess	= nil;
	padKnownVolume	= NO;

	[volumeURL release];
	[super dealloc];
}

-(FSVolumeRefNum)mountVolume
	{ return mountVolume; }

-(NSURL*)volumeURL
	{ return volumeURL; }

-(NSString*)volumePath
{
	NSString*	outPath = nil;
	NSURL*		vURL = [self volumeURL];
	
	if( vURL )
		outPath = [vURL path];
	
	return outPath;
}

-(DADiskRef)volumeDiskRef
	{ return volumeDiskRef; }

-(IconRef)mediaIcon
	{ return mediaIcon; }

-(CFUUIDRef)mediaUUID
	{ return mediaUUID; }

-(NSString*)mediaTitle
{ 
	if( mediaTitle )
		return [[NSString alloc] initWithString:mediaTitle];
	
	return mediaTitle; 
}

-(NSString*)mediaType
	{ return mediaType; }

-(NSNumber*)mediaSize
	{ return mediaSize; }

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
		if( newSlot ) [newSlot retain];
		if( padKnownSlot ) [padKnownSlot release];
		padKnownSlot = newSlot;
		padKnownVolume = (padKnownSlot != nil);
	}
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

-(NSArray*)topLevelDirectory
{
	NSArray*			outListing = nil;
	CFDictionaryRef		ourProps = NULL;
	Boolean				didFind = FALSE;
	didFind = CFURLCreateDataAndPropertiesFromResource( kCFAllocatorDefault,
													   (CFURLRef)[self volumeURL],
													   NULL,
													   &ourProps,
													   (CFArrayRef)[NSArray arrayWithObject:(NSString*)kCFURLFileDirectoryContents],
													   NULL );
	
	if( didFind && ourProps )
		outListing = (NSArray*)CFDictionaryGetValue( ourProps, kCFURLFileDirectoryContents );
	
	if( outListing )
		[outListing retain];
	
	if( ourProps )
		CFRelease( ourProps );
	
	return outListing;
}

-(BOOL)isVolumeURL:(NSURL*)otherURL
{
	FSRef	thisFS;
	FSRef	thatFS;
	
	CFURLGetFSRef( (CFURLRef)[self volumeURL], &thisFS );
	CFURLGetFSRef( (CFURLRef)otherURL, &thatFS );
	
	return( (FSCompareFSRefs( (const FSRef*)&thisFS, (const FSRef*)&thatFS ) == 0) ? YES : NO ); 
}

-(BOOL)isIdentifiedAs:(NSString*)testID
{
	if( padIdentifier )
		return [padIdentifier isEqual:testID];
	else if( testID == nil )
		return YES;
	
	return NO;
}

-(BOOL)isIndexable
	{ return !padKnownVolume; }

-(BOOL)isCD
	{ return [mediaType isEqual:@"IOCDMedia"]; }

-(BOOL)isDVD
	{ return [mediaType isEqual:@"IODVDMedia"]; }
	
-(BOOL)isBD
	{ return [mediaType isEqual:@"IOBDMedia"]; }

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
		NSLog(@"Could not read volume directory: %@", self);
		goto HAVEGUESS;
	}
	dirCount = [volumeDirectory count];
	volumesEnumAIFF = [volumeDirectory objectEnumerator];
	volumesEnumOnce = [volumeDirectory objectEnumerator];

	//	Music CD?
	//		Check if all the visible items have an "aiff" extension
	while( (workURL = (NSURL*)[volumesEnumAIFF nextObject]) )
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
	while( (workURL = (NSURL*)[volumesEnumOnce nextObject]) )
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

/*
 //#import <DiscID/DiscID.h>
 
 // DISK ID STUFF
 // 
 if( [[self pendingTitle] compare:@"Audio CD"] == NSOrderedSame )
 {
 FSRef			theRef;
 FSCatalogInfo	theInfo;
 FSVolumeRefNum	theVRef;
 CFStringRef		diskIDRef;
 CFStringRef		diskPath;
 const char*		diskIDStr = NULL;
 OSStatus		theErr;
 
 DiscId*			disc = discid_new();
 
 theErr = CFURLGetFSRef((CFURLRef)[self pendingURL], &theRef );
 theErr = FSGetCatalogInfo( &theRef, kFSCatInfoVolume, &theInfo, NULL, NULL, NULL );
 theVRef = theInfo.volume;
 
 theErr = FSCopyDiskIDForVolume( theVRef, &diskIDRef );
 diskPath = CFStringCreateWithFormat( kCFAllocatorDefault, NULL, CFSTR("/dev/r%@"), diskIDRef );
 diskIDStr = CFStringCreateCString( diskPath, kCFStringEncodingUTF8 );
 
 fprintf(stderr, "Default Device: %s\n", discid_get_default_device() );
 
 if ( discid_read(disc, diskIDStr) == 0 ) {
 fprintf(stderr, "Error: %s\n", discid_get_error_msg(disc));
 } else {
 fprintf(stderr, "DiscID        : %s\n", discid_get_id(disc));
 fprintf(stderr, "Submit via    : %s\n", discid_get_submission_url(disc));
 }
 
 discid_free(disc); 
 free( (void*)diskIDStr );
 CFRelease( diskIDRef );
 CFRelease( diskPath );
 }
 //
 // END DISK ID STUFF
 
 
*/



-(NSMutableDictionary*)getDVDMediaInfo
{
    HRESULT             herror            = S_OK;
    IOReturn            error             = kIOReturnSuccess;
    IOCFPlugInInterface **plugInInterface = NULL;
    MMCDeviceInterface  **mmcInterface    = NULL;
    NSMutableDictionary *dict             = NULL;
    bool                firstTime         = true;
    io_name_t           deviceName;
    int                 n;
	
	io_service_t		service			  = DADiskCopyIOMedia( [self volumeDiskRef] );
	
	NSMutableArray *formats		= [NSMutableArray arrayWithCapacity:3];
	[formats addObject:[NSNumber numberWithInt:0]];
	[formats addObject:[NSNumber numberWithInt:14]];
	[formats addObject:[NSNumber numberWithInt:255]];
    NSArray*		fFormats    = [[NSArray alloc] initWithArray:formats];

    error = IORegistryEntryGetName(service, deviceName);
    if(error != kIOReturnSuccess) {
        goto bail;
    }
    
    while (true) {
        SInt32 score;
        error = IOCreatePlugInInterfaceForService(service,
                                                  kIOMMCDeviceUserClientTypeID,
                                                  kIOCFPlugInInterfaceID,
                                                  &plugInInterface,
                                                  &score);
        if(error == kIOReturnSuccess) {
            break;
        }
        else if(error == kIOReturnUnsupported || error == kIOReturnNoResources) {
            io_registry_entry_t parentService = (io_object_t)NULL;
            error = IORegistryEntryGetParentEntry(service, kIOServicePlane, &parentService);
            if(error != kIOReturnSuccess) {
                goto bail;
            }
            if(!firstTime) {
                IOObjectRelease(service);
            }
            firstTime = false;
            service   = parentService;
        }
        else {
            goto bail;
        }
    }
    
    herror = (*plugInInterface)->QueryInterface(plugInInterface,
                                                CFUUIDGetUUIDBytes(kIOMMCDeviceInterfaceID),
                                                (LPVOID)&mmcInterface);
    if(herror != S_OK) {
        goto bail;
    }
	
    dict = [[[NSMutableDictionary alloc] initWithCapacity:3] autorelease];
    //[dict setObject:[NSString stringWithCString:deviceName] forKey:@"Name"];
    
 	sleep(3);
	
    // NSLog(@"getMediaInfo: deviceName = %s", deviceName);
    for(n = 0; n < [fFormats count]; n++) {
        int format = [[fFormats objectAtIndex:n] intValue];
        [self readDVDStructure:mmcInterface
					withFormat:format address:0 layer:0 intoDictionary:dict];
        //NSLog(@"getMediaInfo: format = %@", [dict objectForKey:[NSNumber numberWithInt:format]]);
    }
    
bail:
    if(mmcInterface != NULL) {
        (*mmcInterface)->Release(mmcInterface);
    }
    if(plugInInterface != NULL) {
        IODestroyPlugInInterface(plugInInterface);
    }
//	if( service != NULL )
//		CFRelease( service );
	
	
	{
		// is really DVD?
		
	//	if( [dict objectForKey:@"ErrorMessage"] == nil )
	//		goto HAVEDVD;
		
	//	NSData*		data255 = [dict objectForKey:[NSNumber numberWithInt:255]];
		NSData*		data255 = [dict objectForKey:@"255"];
		if( data255 )
		{
			NSString*	hash255 = [data255 md5String];
			
			if( [hash255 isEqual:@"ffff456fffff0203ff1aff3dffffff72"] ) {
				NSLog(@">>HASH MATCHES FOR CD MEDIA<<");
				goto HAVECD;
			}

			if( [dict count] < 2 ) {
				NSLog(@"DVD Info has < 2 keys, falling back. \nDVD Info was: %@", dict);
				goto HAVECD;
			}
		
		} else {
			NSLog(@"DVDInfo mising format 255, falling back. \nDVD Info was: %@", dict);
			goto HAVECD;
		}
	}
	
	// Good luck!
	goto HAVEDVD;
	
HAVECD:
	dict = nil;
	
HAVEDVD:	
    return dict;
}


- (void) readDVDStructure:(MMCDeviceInterface**)mmcInterface
			   withFormat:(SCSICmdField1Byte)format
				  address:(SCSICmdField4Byte)address
					layer:(SCSICmdField1Byte)layer
		   intoDictionary:(NSMutableDictionary*)dict
{
    HRESULT  herror     = S_OK;
    NSData   *data      = NULL;
    Ptr      buffer    = NULL;
    int      bufferSize = 0;
	
    SCSITaskStatus  taskStatus
	
	
	= kSCSITaskStatus_GOOD;
    SCSI_Sense_Data senseData;
    UInt8           header[4];
    
	herror = (*mmcInterface)->ReadDVDStructure(mmcInterface,
                                               address,
                                               layer,
                                               format,
                                               header,
                                               sizeof(header),
                                               &taskStatus,
                                               &senseData);
    if(herror != S_OK || taskStatus != kSCSITaskStatus_GOOD) {
        goto bail;
    }
    
    bufferSize = header[0] * 0x100 + header[1] + 2;
    buffer     = NewPtrClear(bufferSize);
    if(buffer == NULL) {
        goto bail;
    }
	
    herror = (*mmcInterface)->ReadDVDStructure(mmcInterface,
                                               address,
                                               layer,
                                               format,
                                               buffer,
                                               bufferSize,
                                               &taskStatus,
                                               &senseData);
    if(herror != S_OK || taskStatus != kSCSITaskStatus_GOOD) {
        goto bail;
    }
	
    data = [[[NSData alloc] initWithBytes:buffer length:bufferSize] autorelease];
    if(data != NULL) {
       // [dict setObject:data forKey:[NSNumber numberWithInt:format]];
		//	Modified by Jack to emit a string key
		 [dict setObject:data forKey:[NSString stringWithFormat:@"%ld",format]];
    }
    
bail:
    if(buffer != NULL) {
        DisposePtr(buffer);
    }
	
    if(data == NULL) {
        NSString* errorMsg = nil;
        if(herror == S_OK && taskStatus == kSCSITaskStatus_CHECK_CONDITION) {
            UInt8 key  = senseData.SENSE_KEY & 0x0f;
            UInt8 asc  = senseData.ADDITIONAL_SENSE_CODE;
			//          UInt8 ascq = senseData.ADDITIONAL_SENSE_CODE_QUALIFIER;
            if(key == kSENSE_KEY_ILLEGAL_REQUEST && asc == 0x24) {
                errorMsg = [NSString stringWithFormat: @"No support for format %i on this drive", format];
            }
        }
        //if(errorMsg == nil)
        //    errorMsg = @"Could not read DVD structure from the media";
        //if(errorMsg != nil) 
		//	[dict setObject:errorMsg forKey:@"ErrorMessage"];
    }
}



-(DACVolume*)initForMountURL:(NSURL*)mountURL
{
	CFDictionaryRef	volumeData = NULL;

	if( (self = [super init]) )
	{
		FSRef			theRef;
		FSRef			iconFileRef;
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
			NSLog(@"Media Size: %@", [NSString stringFromByteCount:mediaSize]);
		
		//	Aquire the media "type" icon
		workDict = CFDictionaryGetValue( volumeData, CFSTR("DAMediaIcon") );
		if( workDict )
		{
			bundleIDString = CFDictionaryGetValue( workDict, CFSTR("CFBundleIdentifier") );
			iconResFile = CFDictionaryGetValue( workDict, CFSTR("IOBundleResourceFile") );
			
			if( iconResFile && bundleIDString ) {
				
				// Lazy Init the kext bundle identifers
				[[DACVolumeService sharedVolumeService] lazyInitKextBundles];
				
				CFBundleRef		theIconBundle = CFBundleGetBundleWithIdentifier( bundleIDString );
				if( theIconBundle )
					iconFileURL = CFBundleCopyResourceURL( theIconBundle, iconResFile, NULL, NULL );
				if( iconFileURL ) CFURLGetFSRef( iconFileURL, &iconFileRef );
				//if( iconFileURL ) CFShow( iconFileURL );
				//else NSLog( @"Bad Icon File URL: Bundle:%@ ID:%@ Name:%@", theIconBundle, bundleIDString, iconResFile );
			}
			
			if( FSIsFSRefValid(&iconFileRef) )
				RegisterIconRefFromFSRef( kDACALCarouselsFolderType, DACVolume_nextIconID++, &iconFileRef, &mediaIcon );
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
				NSLog(@"DVD Info Dict: %@", dvdInfo);
				NSLog(@"DVD Info Dict Key Count: %i", [dvdInfo count]);

				NSString*			infoMD5 = [dvdInfo md5String];
				
				padIdentifier = [[NSString alloc] initWithString:infoMD5];
				NSLog(@"Disc: %@\nProposed DACDiscKey: %@", self, infoMD5);
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
							NSLog(@"TOC DACDiskKey: %@", hashTOC);
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
				
				//if( padIdentifier == nil )
				padIdentifier = [[NSString alloc] initWithString:md5_String];
				
				NSLog(@"Fallback DACDiscKey: %@", md5_String);
			}
		}
		
		if( padIdentifier == nil )
			NSLog(@"Warning!! Nil Identifier! Volume: %@", self);
		
		DACALSlot*	workSlot = nil;
		
		if( padIdentifier )
			if( (workSlot = DACALDeviceSlotForSlotIdentifier((CFStringRef)padIdentifier)) ) {
				padKnownVolume = YES;
				padKnownSlot = [workSlot retain];
				NSLog(@"Volume Identified As: %@", padKnownSlot);
			}
		
	}	// (if self =)

	padKnownHost = [[NSString alloc] initWithString:[[NSHost currentHost] name]];
	
	if( volumeData != NULL ) CFRelease( volumeData );
	return self;

MISMATCH:
	NSLog(@"Media mismatch: %@", self);
	if( volumeData != NULL ) CFShow( volumeData );
	
FAILED:
	if( volumeData != NULL ) CFRelease( volumeData );
	[self dealloc];
	return nil;
}

-(NSString*)description
	{ return [NSString stringWithFormat:@"%@ Title:%@ DACID:%@",[super description], [self mediaTitle], [self padIdentifier]]; }

+(DACVolume*)volumeForMountURL:(NSURL*)mountURL
	{ return [[DACVolume alloc] initForMountURL:mountURL]; }
						   
+(NSArray*)detectedMounts:(NSArray*)newMounts
{
	NSArray*			outMounts = nil;
	int					newIndex, newCount = [newMounts count];
	NSMutableArray*		newList = [[NSMutableArray alloc] initWithCapacity:newCount];
	NSURL*				newItemURL;
	DACVolume*			newVolume = nil;
	
	//if( (newList == nil) || (newCount == 0) ) return outMounts;
	
	for( newIndex=0; newIndex < newCount; newIndex++ ) {
		newItemURL = (NSURL*)[newMounts objectAtIndex:newIndex];
		newVolume = [DACVolume volumeForMountURL:newItemURL];
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
		[[DACVolumeService sharedVolumeService] addPendingUnmount:padIdentifier];
	
	return [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath: [self volumePath]];
}


@end		//	DACVolume

@implementation DACVolumeService

-(void)dealloc
{
	if( knownVolumes != nil ) [knownVolumes release];
	if( pendingMounts != nil ) [pendingMounts release];
	if( pendingUnmounts != nil ) [pendingUnmounts release];
	
	knownVolumes = nil;
	pendingMounts = nil;
	pendingUnmounts = nil;
	
	[super dealloc];
}

-(void)initSelf
{
	kextBundles = NULL;
	
	// Create managed volumes list without autorelease
	knownVolumes	= [[NSMutableArray alloc] initWithCapacity:0];
	pendingMounts	= [[NSMutableArray alloc] initWithCapacity:0];
	pendingUnmounts	= [[NSMutableArray alloc] initWithCapacity:0];		
}

-(id)initializeService
{ 
	[self scanMountedRemovableMedia];

	// Setup notifications for media changes
	NSNotificationCenter *noteCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	
	// Register for all mount notifications
	[noteCenter addObserver:self selector:@selector(newMediaDetectedNotification:)
					   name:@"NSWorkspaceDidMountNotification" object:nil]; 
	// Register for all unmount notifications
	[noteCenter addObserver:self selector:@selector(existingMediaRemovedNotification:)
					   name:@"NSWorkspaceWillUnmountNotification" object:nil]; 
	
	return self;
}


+(id)sharedVolumeService
	{ return [DACVolumeService sharedService]; }

-(CFArrayRef)kextBundles
	{ return kextBundles; }

-(void)lazyInitKextBundles
{
	if( kextBundles != NULL ) return;
	
	// Although this might look crazy, it will ultimately give us access to the resources of any kext
	// simply by referencing the bundle ID. It is an expensive transaction, so we save it until we
	// absolutely must have it.
	
	CFURLRef	allKextURLs = CFURLCreateWithString( kCFAllocatorDefault, CFSTR("file:///System/Library/Extensions/"), NULL );
	kextBundles = CFBundleCreateBundlesFromDirectory( kCFAllocatorDefault, allKextURLs, NULL );
	if( allKextURLs != NULL ) CFRelease( allKextURLs );
}

-(NSMutableArray*)pendingMounts
	{ return pendingMounts; }

-(void)setPendingMounts:(NSMutableArray*)newMounts
{
	if( !pendingMounts || ![pendingMounts isEqual:newMounts] )
	{
		if( newMounts ) [newMounts retain];
		if( pendingMounts) [pendingMounts release];
		pendingMounts = newMounts;
	}
}

-(void)addPendingMount:(NSString*)knownDACDiskID
{
	if( pendingMounts )
		if( [pendingMounts indexOfObject:knownDACDiskID] == NSNotFound )
			[pendingMounts addObject:knownDACDiskID];
}

-(void)removePendingMount:(NSString*)foundDACDiskID
{
	if( pendingMounts )
		[pendingMounts removeObject:foundDACDiskID];
}

-(BOOL)isPendingMount:(NSString*)aDACDiscID
{
	BOOL	haveID = NO;
	
	if( pendingMounts )
		haveID = ([pendingMounts indexOfObject:aDACDiscID] != NSNotFound);
	
	if( haveID == YES )
		[self removePendingMount:aDACDiscID];
	
	return haveID;
}

-(NSMutableArray*)pendingUnmounts
	{ return pendingUnmounts; }

-(void)setPendingUnmounts:(NSMutableArray*)newUnmounts
{
	if( !pendingUnmounts || ![pendingUnmounts isEqual:newUnmounts] )
	{
		if( newUnmounts ) [newUnmounts retain];
		if( pendingUnmounts) [pendingUnmounts release];
		pendingUnmounts = newUnmounts;
	}
}

-(void)addPendingUnmount:(NSString*)knownDACDiskID
{
	if( pendingUnmounts )
		if( [pendingUnmounts indexOfObject:knownDACDiskID] == NSNotFound )
			[pendingUnmounts addObject:knownDACDiskID];
}

-(void)removePendingUnmount:(NSString*)foundDACDiskID
{
	if( pendingUnmounts )
		[pendingUnmounts removeObject:foundDACDiskID];
}

-(BOOL)isPendingUnmount:(NSString*)aDACDiscID
{
	BOOL	haveID = NO;
	
	if( pendingUnmounts )
		haveID = ([pendingUnmounts indexOfObject:aDACDiscID] != NSNotFound);
	
	if( haveID == YES )
		[self removePendingUnmount:aDACDiscID];

	return haveID;
}


-(NSMutableArray*)knownVolumes
	{ return knownVolumes; }

-(DACVolume*)knownVolumeWithURL:(NSURL*)theURL
{
	NSInteger	knownCount = [knownVolumes count];
	NSInteger	knownIndex = 0;
	DACVolume*	testVolume = nil;
	
	for( knownIndex=0; knownIndex < knownCount; knownIndex++ )
	{
		testVolume = [knownVolumes objectAtIndex:knownIndex];
		if( [testVolume isVolumeURL:theURL] == YES )
			return testVolume;
	}
	
	return nil;
}

-(DACVolume*)knownVolumeWithPath:(NSString*)thePath
{
	NSURL*		theURL = [[NSURL alloc] initFileURLWithPath:thePath];
	DACVolume*	theVolume = [self knownVolumeWithURL:theURL];
	
	[theURL release];
	
	return theVolume;
}

-(NSArray*)knownVolumesWithIdentifier:(NSString*)theID
{
	NSEnumerator*		knownEnum = [knownVolumes objectEnumerator];
	DACVolume*			workVolume = nil;
	NSMutableArray*		matchArray = [[NSMutableArray alloc] initWithCapacity:0];
	NSArray*			outArray = nil;
	
	while ( (workVolume = [knownEnum nextObject]) )
		if( [workVolume isIdentifiedAs:theID] )
			[matchArray addObject:workVolume];
	
	outArray = [NSArray arrayWithArray:matchArray];
	[matchArray release];
	
	return outArray;
}


-(NSArray*)knownIndexableVolumes:(NSArray*)testVolumeList
{
	if( testVolumeList == nil )
		testVolumeList = [self knownVolumes];

	NSEnumerator*		listEnum = [testVolumeList objectEnumerator];
	NSMutableArray*		buildArray = [NSMutableArray arrayWithCapacity:0];
	DACVolume*			workVolume = nil;
	
	while ( (workVolume = [listEnum nextObject]) )
		if( [workVolume isIndexable] == YES )
			[buildArray addObject:workVolume];
	
	return [NSArray arrayWithArray:buildArray]; 
}

-(NSArray*)knownSlotVolumes:(NSArray*)testVolumeList
{
	if( testVolumeList == nil )
		testVolumeList = [self knownVolumes];
	
	NSEnumerator*		listEnum = [testVolumeList objectEnumerator];
	NSMutableArray*		buildArray = [NSMutableArray arrayWithCapacity:0];
	DACVolume*			workVolume = nil;

	while ( (workVolume = [listEnum nextObject]) )
		if( [workVolume padKnownSlot] != nil )
			[buildArray addObject:workVolume];
	
	return [NSArray arrayWithArray:buildArray]; 
}

-(void)knownSlotsDetected:(NSArray*)knownSlotsList
{
	NSEnumerator*		slotEnum = [knownSlotsList objectEnumerator];
	DACVolume*			workVolume = nil;
	BOOL				slotsOK = NO;
	NSInteger			recognizedAction = [[NSUserDefaults standardUserDefaults] integerForKey:kDACDiscKeyRecognized];
	
	if( recognizedAction != kDACDVKnownIDAutoCheckIn )
		return;
	
	while ( (workVolume = [slotEnum nextObject]) ) 
		if( [[workVolume padKnownSlot] slotVolume] == nil )
			slotsOK = [[workVolume padKnownSlot] slotMountedAsVolume:workVolume];
	
	//[AppController playUISoundForBOOL:slotsOK];
}

-(void)knownSlotRemoved:(DACVolume*)knownSlotVolume
{
	DACALSlot*		slotVolume = [knownSlotVolume padKnownSlot];
	BOOL			slotsOK = NO;

	if( slotVolume )
		slotsOK = [slotVolume slotUnmounted];
	
	//[AppController playUISoundForBOOL:slotsOK];	
}


// Notification methods

-(void)newMediaDetected:(NSArray*)newMounts
{
	NSArray*		newVolumes = [DACVolume detectedMounts:[newMounts arrayOfURLsFromPaths]];
	NSWindow*		mainWindow = [[[[AppController shared] dataView] outlineView] window];
	
	NSArray*		knownMounts = [self knownSlotVolumes:newVolumes];
	NSArray*		indexMounts = [self knownIndexableVolumes:newVolumes];
	AppController*	AppControl = [AppController shared];
	NSInteger		unrecogAction = [[NSUserDefaults standardUserDefaults] integerForKey:kDACDiscKeyUnrecognized];
	
	NSLog(@"Mounted Volumes: %@", newVolumes);	
		
	[knownVolumes addUniqueObjectsFromArray:newVolumes];
	
	if( (unrecogAction == kDACDVUnknownIDDisplayAddWindow ) )
		if( ([indexMounts count] > 0) && (mainWindow != nil) && ([mainWindow attachedSheet] == nil) )
			[[AppControl toolbarController] clickAssign:self];

	//	Notify the Add Volumes Window
	if( [indexMounts count] > 0 )
		[[AppControl addVolumeController] performSelectorOnMainThread:@selector(detectedVolumes:)
														   withObject:indexMounts
														waitUntilDone:YES];

	if( [knownMounts count] > 0 )
		[self knownSlotsDetected:knownMounts];

}

-(void)scanMountedRemovableMedia
{
	NSArray*		mediaPaths = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
    if ([mediaPaths count]) {
        [self newMediaDetected:mediaPaths];
    } else
        PMLOG(1, @"mediaPath count = 0");
}

-(void)existingMediaRemoved:(NSString*)oldMediaPath
{
	DACVolume*		foundMedia = [self knownVolumeWithPath:oldMediaPath];
	
	if( foundMedia )
	{
		NSLog(@"Removed Volume: %@", foundMedia);	

		//	Notify the Add Volumes Window
		if( [foundMedia isIndexable] == YES )
			[[[AppController shared] addVolumeController] performSelectorOnMainThread:@selector(ejectedVolumes:)
																		   withObject:[NSArray arrayWithObject:foundMedia]
																		waitUntilDone:YES];
		else if( [foundMedia padKnownSlot] != nil )
				[self knownSlotRemoved:foundMedia];
		
		//	Actually remove from our list
		[knownVolumes removeObject:foundMedia];
		[foundMedia release];
	}
}


-(void)newMediaDetectedNotification:(id)aNotification
	{ [self newMediaDetected:[NSArray arrayWithObject:[NSString stringWithString:[[aNotification userInfo] valueForKey:@"NSDevicePath"]]]]; }

-(void)existingMediaRemovedNotification:(id)aNotification
	{ [self existingMediaRemoved:[NSString stringWithString:[[aNotification userInfo] valueForKey:@"NSDevicePath"]]]; }

-(void)carouselDeviceAttached:(DACALDevice*)aDevice
{ //[self scanMountedRemovableMedia]; 
}

-(void)carouselDeviceSlotAttached:(DACALSlot*)aSlot
{
	NSArray*		matchVolumes = nil;
	NSEnumerator*	matchEnum = nil;
	DACVolume*		workVolume = nil;
	
	
	if( aSlot && [aSlot slotIdentifier] )
	{
		matchVolumes = [self knownVolumesWithIdentifier:[aSlot slotIdentifier]];
		matchEnum = [matchVolumes objectEnumerator];
		
		while ( (workVolume = [matchEnum nextObject]) )
			if( ![workVolume padKnownVolume] )
				[workVolume setPadKnownSlot:aSlot];
		
		if( [matchVolumes count] > 0 ) {
			if( [[[matchVolumes objectAtIndex:0] padKnownSlot] isEqual:aSlot] ) {
				[[DACVolumeService sharedVolumeService] addPendingMount:[aSlot slotIdentifier]];
				[aSlot slotMountedAsVolume:[matchVolumes objectAtIndex:0]];
			}
		}
	}
}

-(void)carouselDeviceDetached:(DACALDevice*)aDevice;
	{ }

@end



















// blank space



