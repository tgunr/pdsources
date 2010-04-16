//
//  DeviceVolume.m
//  DACALTester
//
//  Created by Dave Carlton on 01/19/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import "DeviceVolume.h"
#import <IOKit/IOMessage.h>
#import <IOKit/storage/IODVDMedia.h>
#import "daclconstants.h"
//#import "NSData_Extensions.h"
//#import "NSString_Extensions.h"

@implementation DeviceVolume

int		DeviceVolume_nextIconID = 0;

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
	
	volumeDiskRef	= NULL;
	mediaTitle		= nil;
	mediaType		= nil;
	mediaSize		= nil;
	mediaIcon		= NULL;
	mediaUUID		= NULL;
	
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
	
    // PMLOG(2, @"getMediaInfo: deviceName = %s", deviceName);
    for(n = 0; n < [fFormats count]; n++) {
        int format = [[fFormats objectAtIndex:n] intValue];
        [self readDVDStructure:mmcInterface
					withFormat:format address:0 layer:0 intoDictionary:dict];
        //PMLOG(2, @"getMediaInfo: format = %@", [dict objectForKey:[NSNumber numberWithInt:format]]);
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
				PMLOG(2, @">>HASH MATCHES FOR CD MEDIA<<");
				goto HAVECD;
			}
			
			if( [dict count] < 2 ) {
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



-(DeviceVolume*)initForMountURL:(NSURL*)mountURL
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
				RegisterIconRefFromFSRef( kDACALCarouselsFolderType, DeviceVolume_nextIconID++, &iconFileRef, &mediaIcon );
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
				
				NSString*			infoMD5 = [dvdInfo md5String];
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
							PMLOG(2, @"TOC DACDiskKey: %@", hashTOC);
						}
					}
				}
			}
		}
	}
		
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

-(NSString*)description
{ return [NSString stringWithFormat:@"%@ Title:%@",[super description], [self mediaTitle]]; }

+(DeviceVolume*)volumeForMountURL:(NSURL*)mountURL
{ return [[DeviceVolume alloc] initForMountURL:mountURL]; }

+(NSArray*)detectedMounts:(NSArray*)newMounts
{
	NSArray*			outMounts = nil;
	int					newIndex, newCount = [newMounts count];
	NSMutableArray*		newList = [[NSMutableArray alloc] initWithCapacity:newCount];
	NSURL*				newItemURL;
	DeviceVolume*			newVolume = nil;
	
	//if( (newList == nil) || (newCount == 0) ) return outMounts;
	
	for( newIndex=0; newIndex < newCount; newIndex++ ) {
		newItemURL = (NSURL*)[newMounts objectAtIndex:newIndex];
		newVolume = [DeviceVolume volumeForMountURL:newItemURL];
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

@end

@implementation DACALDeviceVolume 

@synthesize dacalKnownDevice;

@end

