//
//  DACVolume.m
//  PickADisk
//
//  Created by Jack Small on 9/9/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "DACVolume.h"
#import <IOKit/IOMessage.h>
#import <IOKit/storage/IODVDMedia.h>


@implementation DACVolume

int		DACVolume_nextIconID = 0;

-(void)dealloc
{
	if( volumeDiskRef != NULL )	CFRelease( volumeDiskRef );
	if( mediaTitle != NULL )	CFRelease( mediaTitle );
	if( mediaType != nil )		[mediaType release];
	if( mediaSize != nil )		[mediaSize release];
	if( mediaIcon != NULL ) 
		if( IsValidIconRef( mediaIcon ) )
								ReleaseIconRef( mediaIcon );
	if( mediaUUID != NULL )		CFRelease( mediaUUID );
	if( padIdentifier != nil )	[padIdentifier release];
	
	volumeDiskRef	= NULL;
	mediaTitle		= NULL;
	mediaType		= nil;
	mediaSize		= nil;
	mediaIcon		= NULL;
	mediaUUID		= NULL;
	padIdentifier	= nil;
	
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
	{ return mediaTitle; }

-(NSString*)mediaType
	{ return mediaType; }

-(NSNumber*)mediaSize
	{ return mediaSize; }

-(NSString*)padIdentifier
	{ return padIdentifier; }

-(BOOL)padKnownVolume
	{ return padKnownVolume; }

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
	
	volumeDirectory = [self topLevelDirectory];
	
	if( !volumeDirectory )
	{
		NSLog(@"Could not read volume directory: %@", self);
		goto HAVEGUESS;
	}
	dirCount = [volumeDirectory count];

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
	return outGuess;
}

-(NSDictionary*)getDVDMediaInfo
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
    [dict setObject:[NSString stringWithCString:deviceName] forKey:@"Name"];
    
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
        [dict setObject:data forKey:[NSNumber numberWithInt:format]];
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
        if(errorMsg == nil)
            errorMsg = @"Could not read DVD structure from the media";
        if(errorMsg != nil) 
			[dict setObject:errorMsg forKey:@"ErrorMessage"];
    }
}



-(DACVolume*)initForMountURL:(NSURL*)mountURL
{
	CFDictionaryRef	volumeData = NULL;

	if( self = [super init] )
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
		
		//	The Volume FSRef
		theErr = !CFURLGetFSRef((CFURLRef)mountURL, &theRef );
		if( theErr != 0 ) goto FAILED;

		//	The Volume URL
		volumeURL = [mountURL copy];

		//	The FSVolumeRefNum
		theErr = FSGetCatalogInfo( &theRef, kFSCatInfoVolume, &theInfo, NULL, NULL, NULL );
		if( theErr != 0 ) goto FAILED;
		mountVolume = theInfo.volume;
		
		//	Locate volume DADisk info
		theErr = FSCopyDADiskForVolume( mountVolume, &volumeDiskRef );
		if( theErr != 0 ) goto FAILED;
		
		volumeData = DADiskCopyDescription( volumeDiskRef );
		if( volumeData == NULL ) goto FAILED;
		
		//CFShow( volumeData );
		
		//	Extract the volume name
		volumeName = CFDictionaryGetValue( volumeData, CFSTR("DAVolumeName") );
		if( volumeName != NULL )
			mediaTitle = (NSString*)CFStringCreateCopy( kCFAllocatorDefault, volumeName );
		else {
			//	Falback on media name
			volumeName = CFDictionaryGetValue( volumeData, CFSTR("DAMediaName") );
			mediaTitle = (NSString*)CFStringCreateCopy( kCFAllocatorDefault, volumeName );
		}
		
		//	The volume UUID doesn't exist for all volumes
		mediaUUID = CFDictionaryGetValue( volumeData, CFSTR("DAVolumeUUID") );
		if( mediaUUID != NULL ) {
			mediaUUID = CFUUIDCreateFromUUIDBytes( kCFAllocatorDefault, CFUUIDGetUUIDBytes(mediaUUID) );
			padIdentifier = (NSString*)CFUUIDCreateString( kCFAllocatorDefault, mediaUUID );
		}
		
		//	These things disqualify the volume from our list
		{
			//	Whole Media tag doesn't seem to work for some media
			//wholeMedia = CFDictionaryGetValue( volumeData, CFSTR("DAMediaWhole") );
			//if( CFEqual( wholeMedia, kCFBooleanFalse ) ) goto MISMATCH;
			
			deviceModel = (NSString*)CFDictionaryGetValue( volumeData, CFSTR("DADeviceModel") );
			if( deviceModel == NULL ) goto MISMATCH;
			
			//	Primitive but effective, only allow devices that have discs
			if( [deviceModel rangeOfString:@"CD"].length > 0 ) goodModel = TRUE;
			else if( [deviceModel rangeOfString:@"DVD"].length > 0 ) goodModel = TRUE;
			else if( [deviceModel rangeOfString:@"BD"].length > 0 ) goodModel = TRUE;

			if( !goodModel ) goto MISMATCH;
			
			//	Grab a nonautoreleased copy of the media kind
			mediaName = CFDictionaryGetValue( volumeData, CFSTR("DAMediaKind") );
			if( mediaName != NULL )
				mediaType = [[NSString alloc] initWithString:(NSString*)mediaName];
			else goto MISMATCH;
		}
		
		//	Save the disc size
		mediaSize = (NSNumber*)CFDictionaryGetValue( volumeData, CFSTR("DAMediaSize") );
		if( mediaSize ) mediaSize = (NSNumber*)CFRetain( mediaSize );
		
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
			NSDictionary*	dvdInfo = [self getDVDMediaInfo];				// autoreleased
			if( dvdInfo != nil )
			{
				NSLog(@"DVD Info Dict: %@", dvdInfo);

				NSEnumerator*		infoEnum = [dvdInfo objectEnumerator];
				id					infoItem = nil;
				NSMutableString*	infoString = [NSMutableString stringWithString:@""];
				NSString*			infoMD5 = nil;
				
				while ( infoItem = [infoEnum nextObject] ) 
					[infoString appendString:[infoItem md5String]];
				
				infoMD5 = [infoString md5String];
				
				NSLog(@"Disc: %@\nProposed DACKey: %@", self, infoMD5);
				// save the id?
			}
		}
		
		
	}
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
	{ return [NSString stringWithFormat:@"%@ Title:%@ UUID:%@",[super description], [self mediaTitle], [self padIdentifier]]; }

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
	{ return [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath: [self volumePath]]; }


@end		//	DACVolume

@implementation DACVolumeService

static id	DACVolumeService_shared = nil;

-(void)dealloc
{
	
	
	[super dealloc];
}

-(id)init
{
    if (DACVolumeService_shared) 
	{
        [self autorelease];
        return DACVolumeService_shared;
    }
	if( self = [super init] )
	{
		DACVolumeService_shared = [self retain];

		kextBundles = NULL;
		
		// Create managed volumes list without autorelease
		knownVolumes = [[NSMutableArray alloc] initWithCapacity:0];

		NSArray*		mediaPaths = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
		[knownVolumes	addObjectsFromArray:[DACVolume detectedMounts:[mediaPaths arrayOfURLsFromPaths]]];
		
		if( knownVolumes && ([knownVolumes count] > 0) )
			NSLog(@"Mounted Volumes:%@", knownVolumes);
		
		// Setup notifications for media changes
		NSNotificationCenter *noteCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
		
		// Register for all mount notifications
		[noteCenter addObserver:self selector:@selector(newMediaDetected:)
						   name:@"NSWorkspaceDidMountNotification" object:nil]; 
		// Register for all unmount notifications
		[noteCenter addObserver:self selector:@selector(existingMediaRemoved:)
						   name:@"NSWorkspaceWillUnmountNotification" object:nil]; 
		
	}
	return self;
}

+(id)sharedVolumeService
{
	if (!DACVolumeService_shared) {
		[[DACVolumeService alloc] init];
	}
	return DACVolumeService_shared;
}

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


-(NSArray*)knownIndexableVolumes:(NSArray*)testVolumeList
{
	if( testVolumeList == nil )
		testVolumeList = [self knownVolumes];

	NSInteger			buildCount = [testVolumeList count];
	NSInteger			buildIndex = 0;
	NSMutableArray*		buildArray = [NSMutableArray arrayWithCapacity:buildCount];
	
	for( buildIndex=0; buildIndex < buildCount; buildIndex++ )
		if( [[testVolumeList objectAtIndex:buildIndex] isIndexable] == YES )
			[buildArray addObject:[testVolumeList objectAtIndex:buildIndex]];
	
	return [NSArray arrayWithArray:buildArray]; 
}


// Notification methods

-(void)newMediaDetected:(id)aNotification
{
	NSString*		newMediaPath = [NSString stringWithString:[[aNotification userInfo] valueForKey:@"NSDevicePath"]];
	NSArray*		newMounts = [NSArray arrayWithObject:newMediaPath];
	NSArray*		newVolumes = [DACVolume detectedMounts:[newMounts arrayOfURLsFromPaths]];
	NSWindow*		mainWindow = [[[[AppController shared] dataView] outlineView] window];
	
	NSLog(@"Mounted Volumes: %@", newVolumes);	
		
	[knownVolumes addObjectsFromArray:newVolumes];

	if( [mainWindow attachedSheet] == nil )
		[[[AppController shared] toolbarController] clickAssign:self];
		//[[[AppController shared] addVolumeController] startSheet:mainWindow];

	//	Notify the Add Volumes Window
	[[[AppController shared] addVolumeController] performSelectorOnMainThread:@selector(detectedVolumes:)
																   withObject:[self knownIndexableVolumes:newVolumes]
																waitUntilDone:YES];
}

-(void)existingMediaRemoved:(id)aNotification
{
	NSString*		oldMediaPath = [NSString stringWithString:[[aNotification userInfo] valueForKey:@"NSDevicePath"]];
	DACVolume*		foundMedia = [self knownVolumeWithPath:oldMediaPath];
	
	if( foundMedia )
	{
		NSLog(@"Removed Volume: %@", foundMedia);	

		//	Notify the Add Volumes Window
		if( [foundMedia isIndexable] == YES )
			[[[AppController shared] addVolumeController] performSelectorOnMainThread:@selector(ejectedVolumes:)
																		   withObject:[NSArray arrayWithObject:foundMedia]
																		waitUntilDone:YES];
		
		//	Actually remove from our list
		[knownVolumes removeObject:foundMedia];
		[foundMedia release];
	}
}

@end



















// thing



