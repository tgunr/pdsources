//
//  Volume.m
//  DACALTester
//
//  Created by Dave Carlton on 2/12/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import "Volume.h"
#import "VolumeService.h"
#import "NSArray_Extensions.h"
#import "NSData_Extensions.h"
#import "NSString_Extensions.h"
#import "dacallib.h"

@implementation Volume

-(void)dealloc
{
	if (volumeDiskRef != NULL) CFRelease(volumeDiskRef);
	if (mediaTitle != nil) [mediaTitle release];
	if (mediaType != nil) [mediaType release];
	if (mediaSize != nil) [mediaSize release];
	if (mediaIcon != NULL)
		if ( IsValidIconRef(mediaIcon) )
			ReleaseIconRef(mediaIcon);
	if (mediaUUID != NULL) CFRelease(mediaUUID);

	volumeDiskRef   = NULL;
	mediaTitle      = nil;
	mediaType       = nil;
	mediaSize       = nil;
	mediaIcon       = NULL;
	mediaUUID       = NULL;

	[super dealloc];
} // dealloc

-(FSVolumeRefNum)mountVolume
{
	return mountVolume;
}

-(NSURL *)volumeURL
{
	return volumeURL;
}

-(NSString *)volumePath
{
	NSString * outPath = nil;
	NSURL    * vURL = [self volumeURL];

	if (vURL)
		outPath = [vURL path];

	return outPath;
}

-(DADiskRef)volumeDiskRef
{
	return volumeDiskRef;
}

-(IconRef)mediaIcon
{
	return mediaIcon;
}

-(CFUUIDRef)mediaUUID
{
	return mediaUUID;
}

-(NSString *)mediaTitle
{
	if (mediaTitle)
		return [[NSString alloc] initWithString: mediaTitle];

	return mediaTitle;
}

-(NSString *)mediaType
{
	return mediaType;
}

-(NSNumber *)mediaSize
{
	return mediaSize;
}

+(Volume *)volumeForMountURL: (NSURL *) mountURL
{
	return [[self alloc] initForMountURL: mountURL];
}

-(NSArray *)topLevelDirectory
{
	NSArray       * outListing = nil;
	CFDictionaryRef ourProps = NULL;
	Boolean         didFind = FALSE;

	didFind = CFURLCreateDataAndPropertiesFromResource(kCFAllocatorDefault,
		(CFURLRef)[self volumeURL],
		NULL,
		&ourProps,
		(CFArrayRef)[NSArray arrayWithObject : (NSString *)kCFURLFileDirectoryContents],
		NULL);

	if (didFind && ourProps)
		outListing = (NSArray *)CFDictionaryGetValue(ourProps, kCFURLFileDirectoryContents);

	if (outListing)
		[outListing retain];

	if (ourProps)
		CFRelease(ourProps);

	return outListing;
} // topLevelDirectory

-(BOOL)isVolumeURL: (NSURL *) otherURL
{
	FSRef thisFS;
	FSRef thatFS;

	CFURLGetFSRef( (CFURLRef)[self volumeURL], &thisFS );
	CFURLGetFSRef( (CFURLRef)otherURL, &thatFS );

	return (FSCompareFSRefs( (const FSRef *)&thisFS, (const FSRef *)&thatFS ) == 0) ? YES : NO;
}

-(BOOL)isCD
{
	return [mediaType isEqual: @"IOCDMedia"];
}

-(BOOL)isDVD
{
	return [mediaType isEqual: @"IODVDMedia"];
}

-(BOOL)isBD
{
	return [mediaType isEqual: @"IOBDMedia"];
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



-(NSMutableDictionary *)getDVDMediaInfo
{
	HRESULT                herror            = S_OK;
	IOReturn               error             = kIOReturnSuccess;
	IOCFPlugInInterface ** plugInInterface = NULL;
	MMCDeviceInterface  ** mmcInterface    = NULL;
	NSMutableDictionary  * dict             = NULL;
	bool                   firstTime         = true;
	io_name_t              deviceName;
	int                    n;

	io_service_t service           = DADiskCopyIOMedia([self volumeDiskRef]);

	NSMutableArray * formats     = [NSMutableArray arrayWithCapacity: 3];

	[formats addObject: [NSNumber numberWithInt: 0]];
	[formats addObject: [NSNumber numberWithInt: 14]];
	[formats addObject: [NSNumber numberWithInt: 255]];
	NSArray * fFormats    = [[NSArray alloc] initWithArray: formats];

	error = IORegistryEntryGetName(service, deviceName);
	if (error != kIOReturnSuccess) {
		goto bail;
	}

	while (true) {
		SInt32 score;
		error = IOCreatePlugInInterfaceForService(service,
			kIOMMCDeviceUserClientTypeID,
			kIOCFPlugInInterfaceID,
			&plugInInterface,
			&score);
		if (error == kIOReturnSuccess) {
			break;
		} else if ( (error == kIOReturnUnsupported) || (error == kIOReturnNoResources) )        {
			io_registry_entry_t parentService = 0;
			error = IORegistryEntryGetParentEntry(service, kIOServicePlane, &parentService);
			if (error != kIOReturnSuccess) {
				goto bail;
			}
			if (!firstTime) {
				IOObjectRelease(service);
			}
			firstTime = false;
			service   = parentService;
		} else   {
			goto bail;
		}
	}

	herror = (*plugInInterface)->QueryInterface(plugInInterface,
		CFUUIDGetUUIDBytes(kIOMMCDeviceInterfaceID),
		(LPVOID)&mmcInterface);
	if (herror != S_OK) {
		goto bail;
	}

	dict = [[[NSMutableDictionary alloc] initWithCapacity: 3] autorelease];
	//[dict setObject:[NSString stringWithCString:deviceName] forKey:@"Name"];

	sleep(3);

	// PMLOG(2, @"getMediaInfo: deviceName = %s", deviceName);
	for (n = 0; n < [fFormats count]; n++) {
		int format = [[fFormats objectAtIndex: n] intValue];
		[self readDVDStructure: mmcInterface
		 withFormat: format address: 0 layer: 0 intoDictionary: dict];
		//PMLOG(2, @"getMediaInfo: format = %@", [dict objectForKey:[NSNumber numberWithInt:format]]);
	}

bail:
	if (mmcInterface != NULL) {
		(*mmcInterface)->Release(mmcInterface);
	}
	if (plugInInterface != NULL) {
		IODestroyPlugInInterface(plugInInterface);
	}
	//	if( service != NULL )
	//		CFRelease( service );

	{
		// is really DVD?

		//	if( [dict objectForKey:@"ErrorMessage"] == nil )
		//		goto HAVEDVD;

		//	NSData*		data255 = [dict objectForKey:[NSNumber numberWithInt:255]];
		NSData * data255 = [dict objectForKey: @"255"];
		if (data255) {
			NSString * hash255 = [data255 md5String];

			if ([hash255 isEqual: @"ffff456fffff0203ff1aff3dffffff72"]) {
				PMLOG(2, @">>HASH MATCHES FOR CD MEDIA<<");
				goto HAVECD;
			}

			if ([dict count] < 2) {
				PMLOG(2, @"DVD Info has < 2 keys, falling back. DVD Info was: %@", dict);
				goto HAVECD;
			}
		} else {
			PMLOG(2, @"DVDInfo mising format 255, falling back. DVD Info was: %@", dict);
			goto HAVECD;
		}
	}

	// Good luck!
	goto HAVEDVD;

HAVECD:
	dict = nil;

HAVEDVD:
	return dict;
} // getDVDMediaInfo

-(void) readDVDStructure: (MMCDeviceInterface * *) mmcInterface
			  withFormat: (SCSICmdField1Byte) format
				 address: (SCSICmdField4Byte) address
				   layer: (SCSICmdField1Byte) layer
		  intoDictionary: (NSMutableDictionary *) dict
{
	HRESULT  herror     = S_OK;
	NSData * data      = NULL;
	Ptr      buffer    = NULL;
	int      bufferSize = 0;

	SCSITaskStatus taskStatus

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
	if ( (herror != S_OK) || (taskStatus != kSCSITaskStatus_GOOD) ) {
		goto bail;
	}

	bufferSize = header[0] * 0x100 + header[1] + 2;
	buffer     = NewPtrClear(bufferSize);
	if (buffer == NULL) {
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
	if ( (herror != S_OK) || (taskStatus != kSCSITaskStatus_GOOD) ) {
		goto bail;
	}

	data = [[[NSData alloc] initWithBytes: buffer length: bufferSize] autorelease];
	if (data != NULL) {
		// [dict setObject:data forKey:[NSNumber numberWithInt:format]];
		//	Modified by Jack to emit a string key
		[dict setObject: data forKey: [NSString stringWithFormat: @"%ld", format]];
	}

bail:
	if (buffer != NULL) {
		DisposePtr(buffer);
	}

	if (data == NULL) {
		NSString * errorMsg = nil;
		if ( (herror == S_OK) && (taskStatus == kSCSITaskStatus_CHECK_CONDITION) ) {
			UInt8 key  = senseData.SENSE_KEY & 0x0f;
			UInt8 asc  = senseData.ADDITIONAL_SENSE_CODE;
			//          UInt8 ascq = senseData.ADDITIONAL_SENSE_CODE_QUALIFIER;
			if ( (key == kSENSE_KEY_ILLEGAL_REQUEST) && (asc == 0x24) ) {
				errorMsg = [NSString stringWithFormat: @"No support for format %i on this drive", format];
			}
		}
		//if(errorMsg == nil)
		//    errorMsg = @"Could not read DVD structure from the media";
		//if(errorMsg != nil)
		//	[dict setObject:errorMsg forKey:@"ErrorMessage"];
	}
} // readDVDStructure

-(Volume *)initForMountURL: (NSURL *) mountURL
{
	CFDictionaryRef volumeData = NULL;

	if (self = [super init]) {
		FSRef           theRef;
		FSCatalogInfo   theInfo;
		OSStatus        theErr;
		CFDictionaryRef workDict = NULL;
		CFURLRef        iconFileURL = NULL;
		CFStringRef     bundleIDString = NULL;
		CFStringRef     iconResFile = NULL;
		CFStringRef     volumeName = NULL;
		//		CFStringRef		volumeUUIDString = NULL;
		CFStringRef mediaName = NULL;
		NSString  * deviceModel = NULL;
		Boolean     goodModel = FALSE;
		//		CFBooleanRef	wholeMedia = kCFBooleanFalse;

		volumeDiskRef   = NULL;
		mediaType       = nil;
		mediaSize       = nil;
		mediaIcon       = NULL;
		mediaUUID       = NULL;

		//	The Volume FSRef
		theErr = !CFURLGetFSRef( (CFURLRef)mountURL, &theRef );
		if (theErr != 0)
			goto FAILED;

		//	The Volume URL
		volumeURL = [mountURL copy];

		//	The FSVolumeRefNum
		theErr = FSGetCatalogInfo(&theRef, kFSCatInfoVolume, &theInfo, NULL, NULL, NULL);
		if (theErr != 0)
			goto FAILED;
		mountVolume = theInfo.volume;

		//	Locate volume DADisk info
		theErr = FSCopyDADiskForVolume(mountVolume, &volumeDiskRef);
		if (theErr != 0)
			goto FAILED;

		volumeData = DADiskCopyDescription(volumeDiskRef);
		if (volumeData == NULL)
			goto FAILED;

		//CFShow( volumeData );

		//	Extract the volume name
		volumeName = CFDictionaryGetValue( volumeData, CFSTR("DAVolumeName") );
		if (volumeName != NULL)
			mediaTitle = [[NSString alloc] initWithString: (NSString *)volumeName];
		else {
			//	Falback on media name
			volumeName = CFDictionaryGetValue( volumeData, CFSTR("DAMediaName") );
			if (volumeName)
				mediaTitle = [[NSString alloc] initWithString: (NSString *)volumeName];
		}

		if (mediaTitle == nil)      // No title?  Something fishy.
			goto MISMATCH;

		//	The volume UUID doesn't exist for all volumes
		mediaUUID = CFDictionaryGetValue( volumeData, CFSTR("DAVolumeUUID") );
		if (mediaUUID != NULL) {
			mediaUUID = CFUUIDCreateFromUUIDBytes( kCFAllocatorDefault, CFUUIDGetUUIDBytes(mediaUUID) );
		}

		//	These things disqualify the volume from our list
		//	Whole Media tag doesn't seem to work for some media
		//wholeMedia = CFDictionaryGetValue( volumeData, CFSTR("DAMediaWhole") );
		//if( CFEqual( wholeMedia, kCFBooleanFalse ) ) goto MISMATCH;

		deviceModel = (NSString *)CFDictionaryGetValue( volumeData, CFSTR("DADeviceModel") );
		if (deviceModel == NULL)
			goto MISMATCH;

		//	Primitive but effective, only allow devices that have discs
		if ([deviceModel rangeOfString: @"CD"].length > 0)
			goodModel = TRUE;
		else if ([deviceModel rangeOfString: @"DVD"].length > 0)
			goodModel = TRUE;
		else if ([deviceModel rangeOfString: @"BD"].length > 0)
			goodModel = TRUE;

		if (!goodModel)
			goto MISMATCH;

		//	Grab a nonautoreleased copy of the media kind
		mediaName = CFDictionaryGetValue( volumeData, CFSTR("DAMediaKind") );
		if (mediaName != NULL)
			mediaType = [[NSString alloc] initWithString: (NSString *)mediaName];
		else
			goto MISMATCH;

		//	Save the disc size
		mediaSize = (NSNumber *)CFDictionaryGetValue( volumeData, CFSTR("DAMediaSize") );
		if (mediaSize)
			mediaSize = (NSNumber *)CFRetain(mediaSize);

		if (mediaSize)
			PMLOG(2, @"Media Size: %@", [NSString stringFromByteCount: mediaSize]);

		//	Aquire the media "type" icon
		workDict = CFDictionaryGetValue( volumeData, CFSTR("DAMediaIcon") );
		if (workDict) {
			bundleIDString = CFDictionaryGetValue( workDict, CFSTR("CFBundleIdentifier") );
			iconResFile = CFDictionaryGetValue( workDict, CFSTR("IOBundleResourceFile") );

			if (iconResFile && bundleIDString) {
				// Lazy Init the kext bundle identifers
				[[VolumeService sharedVolumeService] lazyInitKextBundles];

				CFBundleRef theIconBundle = CFBundleGetBundleWithIdentifier(bundleIDString);
				if (theIconBundle)
					iconFileURL = CFBundleCopyResourceURL(theIconBundle, iconResFile, NULL, NULL);
				if (iconFileURL) {
					CFURLGetFSRef(iconFileURL, &iconFileRef);
					//if( iconFileURL ) CFShow( iconFileURL );
					//else PMLOG(2,  @"Bad Icon File URL: Bundle:%@ ID:%@ Name:%@", theIconBundle, bundleIDString, iconResFile );
					CFRelease(iconFileURL);
				}
			}
		}

		//if( [self isDVD] == YES ) {
		NSMutableDictionary * dvdInfo = [self getDVDMediaInfo];                             // autoreleased
		if (dvdInfo != nil) {
			//	First add in some others for more uniqueness
			//	[dvdInfo addEntryFromDictionary:volumeData forKey:@""];
			
			//[dvdInfo addEntryFromDictionary:(NSDictionary*)volumeData forKey:@"DAMediaBSDMajor"];
			//[dvdInfo addEntryFromDictionary:(NSDictionary*)volumeData forKey:@"DAMediaBSDMinor"];
			[dvdInfo addEntryFromDictionary: (NSDictionary *)volumeData forKey: @"DAMediaBlockSize"];
			[dvdInfo addEntryFromDictionary: (NSDictionary *)volumeData forKey: @"DAMediaContent"];
			[dvdInfo addEntryFromDictionary: (NSDictionary *)volumeData forKey: @"DAMediaName"];
			[dvdInfo addEntryFromDictionary: (NSDictionary *)volumeData forKey: @"DAMediaSize"];
			[dvdInfo addEntryFromDictionary: (NSDictionary *)volumeData forKey: @"DAMediaWhole"];
			[dvdInfo addEntryFromDictionary: (NSDictionary *)volumeData forKey: @"DAMediaWritable"];
			[dvdInfo addEntryFromDictionary: (NSDictionary *)volumeData forKey: @"DAVolumeKind"];
			[dvdInfo addEntryFromDictionary: (NSDictionary *)volumeData forKey: @"DAVolumeMountable"];
			[dvdInfo addEntryFromDictionary: (NSDictionary *)volumeData forKey: @"DAVolumeName"];
			[dvdInfo addEntryFromDictionary: (NSDictionary *)volumeData forKey: @"DAVolumeUUID"];
			//[dvdInfo addEntryFromDictionary:volumeData forKey:@""];
			//[dvdInfo addEntryFromDictionary:volumeData forKey:@""];
			//[dvdInfo addEntryFromDictionary:volumeData forKey:@""];
			
			CFShow(volumeData);
			PMLOG(2, @"DVD Info Dict: %@", dvdInfo);
			PMLOG(2, @"DVD Info Dict Key Count: %i", [dvdInfo count]);
			
			infoMD5 = [dvdInfo md5String];
			
			PMLOG(2, @"Disc: %@\nProposed DACDiscKey: %@", self, infoMD5);
		}
	}
	if (volumeData != NULL)
		CFRelease(volumeData);
	return self;
	
MISMATCH:
	if (gVerbose == YES) {
		PMLOG(2, @"Media mismatch: %@", [self volumeURL]);
		if (volumeData != NULL)
			CFShow(volumeData);
	}
	
FAILED:
	if (volumeData != NULL)
		CFRelease(volumeData);
	[self dealloc];
	return nil;
} // initForMountURL

+(NSArray*)detectedMounts:(NSArray*)newMounts
{
	NSArray*			outMounts = nil;
	int					newIndex, newCount = [newMounts count];
	NSMutableArray*		newList = [[NSMutableArray alloc] initWithCapacity:newCount];
	NSURL*				newItemURL;
	Volume*				newVolume = nil;
	
	//if( (newList == nil) || (newCount == 0) ) return outMounts;
	
	for( newIndex=0; newIndex < newCount; newIndex++ ) {
		newItemURL = (NSURL*)[newMounts objectAtIndex:newIndex];
		newVolume = [self volumeForMountURL:newItemURL];
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
	BOOL result = [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath: [self volumePath]];
	return result;
}


-(NSString*)description
{ 
	return [NSString stringWithFormat:@"%@ Title:%@",[super description], [self mediaTitle]]; 
}

@end
