/*
 *  dacallib.m
 *  PMTB
 *
 *  Created by Dave Carlton on 05/20/08.
 *  Copyright 2008 Polymicro Systems. All rights reserved.
 *
 */

#include "dacallib.h"
#include "../pmsutility/pmsDACALUtility.h"

//#define __DCDEBUG												// define this in your pch to go verbose debug

#define DACAL_MAXDEVICE_COUNT	64*4							// 64 boxes + 64 hubs = 128 devices/per port for possible 4 ports.  Total 256 devices.
#define	DACAL_MAXCLIENT_COUNT	1								// Only 1 will work for now.

//#define	DACAL_SHORT_SLEEP		usleep(900);
#define	DACAL_SHORT_SLEEP		sleep(1);
#define	DACAL_RESET_SLEEP		sleep(5);

#define DACAL_BOX_BUSY(x)			gDACALBoxes.box[x].isBusy
#define DACAL_BOX_NAME(x)			gDACALBoxes.box[x].boxName
#define DACAL_BOX_MODEL(x)			gDACALBoxes.box[x].boxModel
#define DACAL_BOX_UUID(x)			gDACALBoxes.box[x].boxUUID
#define DACAL_BOX_REF(x)			gDACALBoxes.box[x].boxRef
#define DACAL_BOX_DEVICE(x)			gDACALBoxes.box[x].boxDevice
#define DACAL_BOX_LASTSLOT(x)		gDACALBoxes.box[x].boxLastSlot
#define DACAL_BOX_LASTSLOTTIME(x)	gDACALBoxes.box[x].boxLastSlotTime
#define DACAL_BOX_PATH(x)			gDACALBoxes.box[x].boxPath
#define DACAL_BOX_NODE(x)			gDACALBoxes.box[x].boxNode
#define DACAL_BOX_NOTIFICATION(x)	gDACALBoxes.box[x].boxNotification

#define DACAL_CLIENT_IDENTIFIER(x)	gDACALClients.client[x-1].clientIdentifier
#define DACAL_CLIENT_ALLOCATOR(x)	gDACALClients.client[x-1].clientAllocator
#define DACAL_CLIENT_CALLBACK(x)	gDACALClients.client[x-1].clientCallback
#define DACAL_CLIENT_USERDATA(x)	gDACALClients.client[x-1].clientDataRef

const SInt32	kDACALVendorID	= 0x04b4;
const SInt32	kDACALProductID	= 0x5a9b;
const SInt32	kDACALReleaseID	= 0x0100;

typedef enum {
	/*	undocManufacturer = 1,
	 undocSoftware = 2,
	 undocUnknown1,
	 undocUnknown2,
	 undocUnknown3,
	 undocUnknown4,
	 undocUnknown5,
	 undocUnknown6,
	 undocUnknown7,
	 undocUnknown8,*/
	cmdGetModel = 9,
	cmdGetUUID,
	cmdReset,
	cmdMoveToSlot,
	cmdReserved1,
	cmdCloseDoor,
	cmdLEDOn,
	cmdLEDOff,
	cmdGetStatus,
	cmdGetSlot,
	cmdMoveToDVD,
	cmdEjectDVD,
} dacalCmd;

typedef struct {
	Boolean							isBusy;
	DACALDeviceNode					boxNode;
	CFStringRef						boxName;
	CFStringRef						boxModel;
	CFUUIDRef						boxUUID;
	CFURLRef						boxPath;
	IOUSBDeviceInterface245**		boxRef;
	io_service_t					boxDevice;
	io_object_t						boxNotification;
	DACALSlotNum					boxLastSlot;
	time_t							boxLastSlotTime;
} DACALBox, *DACALBoxRef;

typedef struct {
	DACALCount						boxCount;
	DACALBox						box[DACAL_MAXDEVICE_COUNT];		// Change the constant above if necesary
} DACALArray;

typedef struct {
	char	stringSize;	
	char	stringCode;
	UniChar uniString[128];
} dacalString;

typedef struct {
	CFStringRef						clientIdentifier;
	CFAllocatorRef					clientAllocator;
	void*							clientCallback;
	void*							clientDataRef;
} DACALClientData, *DACALClientDataRef;

typedef struct {
	unsigned int					clientCount;
	DACALClientData					client[DACAL_MAXCLIENT_COUNT];
} DACALClientsArray;

typedef	vm_offset_t		DACALClientRef;

CFStringRef dacalACK = CFSTR("ACK");
CFStringRef dacalBUSY = CFSTR("Busy");
CFStringRef dacalERROR = CFSTR("ERROR");
CFStringRef dacalNUMBER = CFSTR("numbers");
CFStringRef dacalNAN = CFSTR("1234567");
CFStringRef dacalDC101 = CFSTR("DC101");
CFStringRef dacalDC300 = CFSTR("1234567");
CFStringRef dacalDC016RW = CFSTR("DC016RW");
CFStringRef DACALDC101CFName = CFSTR("DC-101");
CFStringRef DACALDC300CFName = CFSTR("DC-300");
CFStringRef DACALDC016RWCFName = CFSTR("DC-016RW");

//CFStringRef		kDACALNameProperty = CFSTR("DACAL Device Name");
CFStringRef		kDACALPreferencesID = CFSTR("com.polymicrosystems.carousellib.devicenames");
CFStringRef		kDACALCarouselDocumentExtension = CFSTR("carousel");
CFStringRef		kDACALCarouselDocumentDotExtension = CFSTR(".carousel");
CFStringRef		kDACALCarouselDocumentInfoFile = CFSTR("carousel.plist");

CFStringRef			kDACALCarouselDocumentDisplayNameFormat		=CFSTR("%@'s Carousel %i");
CFStringRef			kDACALCarouselDocumentInfoKeyName			=CFSTR("Name");
CFStringRef			kDACALCarouselDocumentInfoKeyUUID			=CFSTR("UUID");
//CFStringRef			kDACALCarouselDocumentInfoKeyNode			=CFSTR("Node")

CFStringRef			kDACALCarouselDocumentXAttrCarousel		=CFSTR("com.polymicrosystems.pickadisk.device");
CFStringRef			kDACALCarouselDocumentXAttrSlot			=CFSTR("com.polymicrosystems.pickadisk.device.slot");
CFStringRef			kDACALCarouselDocumentXAttrSlotKind		=CFSTR("com.polymicrosystems.pickadisk.device.slot.kind");
CFStringRef			kDACALCarouselDocumentXAttrSlotAddDate	=CFSTR("com.polymicrosystems.pickadisk.device.slot.added");
CFStringRef			kDACALCarouselDocumentXAttrSlotCheckout	=CFSTR("com.polymicrosystems.pickadisk.device.slot.checkout");
CFStringRef			kDACALCarouselDocumentXAttrVolumeName	=CFSTR("com.polymicrosystems.pickadisk.device.volname");

CFStringRef			kDACALCarouselNoticeDeviceOpen			= CFSTR("Open Device");
CFStringRef			kDACALCarouselNoticeDeviceClose			= CFSTR("Close Device");

#define DACAL_CAROUSEL_FOLDERNAME_CFSTRING	CFSTR("PickADisk")
#define DACAL_CAROUSEL_FOLDERNAME_PSTRING	"\pPickADisk"		// used to register the folder location with the OS for use in FSFindFolder

const DACALDeviceRef	kDACALDefaultDevice = 0;
const DACALDeviceRef	kDACALIllegalDevice = DACAL_MAXDEVICE_COUNT+1;
const DACALDeviceRef	kDACALDevicesMaxCount = DACAL_MAXDEVICE_COUNT;
const DACALDeviceRef	kDACALNullDevice = (DACALDeviceRef)NULL;

#ifdef __DCDEBUG
Boolean			gDACALVerbose = TRUE;
#else
Boolean			gDACALVerbose = FALSE;
#endif

//static	mach_port_t				masterPort = 0;				// requires <mach/mach.h>
static	io_iterator_t			gDACALAddedIter;
static	CFAllocatorRef			gDACALDefaultCFAllocator = NULL;
static	IONotificationPortRef	gDACALNotifyPort;
static	CFRunLoopSourceRef		gDACALRunLoopSource;
static	DACALDeviceRef			gDACALDefaultDevice = 1;
static	DACALArray				gDACALBoxes;
static  DACALClientsArray		gDACALClients;
static	DACALClientRef			gDACALNextClientID = 1;

const DACALResult		kDACALOK = kIOReturnSuccess;
const DACALResult		kDACALBusy = kIOReturnBusy;
const DACALResult		kDACALError = kIOReturnError;
const DACALResult		kDACALInvalidParameter = kIOReturnBadArgument;


// Private Functions


DACALResult		CarouselEstablishInfoFile( CFUUIDRef boxUUID );
DACALResult		CarouselWriteInfoFile( DACALDeviceRef inDevice );
DACALResult		CarouselWriteInfoFileKey( DACALDeviceRef inDevice, CFStringRef inKeyName, CFTypeRef inKeyValue );
DACALResult		CarouselReadInfoFile( DACALDeviceRef indexID );
void*			CarouselReadInfoFileKey( DACALDeviceRef deviceID, CFStringRef inKeyName, DACALResult* outResult );

//CFStringRef		CopyUSBProductData(DACALDeviceRef indexID, DACALDeviceNode* outNode);
//DACALResult		SaveUSBProductData(DACALDeviceRef deviceID, CFStringRef inName, DACALDeviceNode inNode);
CFStringRef		CFStringCreateFromDacalString( dacalString* deviceBlock );
CFStringRef		CFStringCreateFromDacalPipe( CFAllocatorRef inAllocator, CFStringRef inCommandArgs, DACALResult* outError );
IOReturn		dacalGetDescriptor(IOUSBDeviceInterface245 **deviceIntf, UInt16 index, UInt8 descType, UInt8 descIndex, void *buf, UInt16 len, UInt16 *result);
IOReturn		dacalDoRequest(IOUSBDeviceInterface245** indeviceIntf, dacalCmd cmd, dacalString* outResult);
DACALCount		dacalDeviceRefToDeviceIndex( DACALDeviceRef deviceID );

DACALResult		DACALCommandRequest( DACALDeviceRef deviceID, DACALCommand deviceCommand, dacalString* outResult );
DACALResult		DACALCommandRequestNoResult( DACALDeviceRef deviceID, DACALCommand deviceCommand );
CFStringRef		DACALCommandRequestCFString( DACALDeviceRef deviceID, DACALCommand deviceCommand, DACALResult* outError );

DACALDeviceRef	DACALDeviceCreateWithService( io_service_t ioDeviceObj, DACALResult* outError );
DACALResult		DACALDeviceClose( DACALDeviceRef deviceID );


void*			CarouselReadInfoFileKey( DACALDeviceRef deviceID, CFStringRef inKeyName, DACALResult* outResult )
{
	DACALResult			returnResult = kIOReturnBadArgument;
	DACALDeviceRef		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	CFURLRef			docURL = DACAL_BOX_PATH(indexID);
	CFURLRef			infoURL = NULL;
	CFDataRef			infoText = NULL;
	CFDictionaryRef		infoData = NULL;
	Boolean				infoGood = FALSE;
	OSStatus			fileErr;
	
	void*				outData = NULL;
	
	if( !docURL ) goto BAIL;
	
	infoURL = CFURLCreateWithString( NULL, kDACALCarouselDocumentInfoFile, docURL );
	infoGood = CFURLCreateDataAndPropertiesFromResource( NULL, infoURL, &infoText, NULL, NULL, &fileErr );
	if( !infoGood ) {
		returnResult = (DACALResult)fileErr;
		goto BAIL;
	}
	
	infoData = (CFDictionaryRef)CFPropertyListCreateFromXMLData( NULL, infoText, kCFPropertyListImmutable, NULL );
	if( !infoData ) goto BAIL;
	
	outData = (void*)CFDictionaryGetValue( infoData, (const void*)inKeyName );
	if( !outData ) goto BAIL;
	
	CFRetain( (CFTypeRef)outData );
	returnResult = 0;
	
	//CFShow( outData );
	
BAIL:
	if( infoText ) CFRelease( infoText );
//	if( docURL ) CFRelease( docURL );
	if( infoURL ) CFRelease( infoURL );
	
	if( outResult != NULL ) *outResult = returnResult;
	return outData;
}

DACALResult		CarouselReadInfoFile( DACALDeviceRef deviceID )
{
	DACALResult			outResult = kIOReturnBadArgument;
	DACALDeviceRef		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	CFStringRef			boxName = NULL;
	
	boxName = (CFStringRef)CarouselReadInfoFileKey( deviceID, kDACALCarouselDocumentInfoKeyName, &outResult );
	if( boxName )
	{
		//CFShow( boxName );		
		DACAL_BOX_NAME(indexID) = CFStringCreateCopy( NULL, boxName );
		if( DACAL_BOX_NAME(indexID) == NULL ) outResult = kIOReturnBadArgument;
		CFRelease( boxName );
	}
	
	return outResult;
	
}

DACALResult		CarouselWriteInfoFileKey( DACALDeviceRef inDevice, CFStringRef inKeyName, CFTypeRef inKeyValue )
{
	DACALResult		outResult = kIOReturnBadArgument;
	DACALDeviceRef	indexID = dacalDeviceRefToDeviceIndex( inDevice );
	CFURLRef		devicePath = DACAL_BOX_PATH( indexID );
	CFURLRef		savePath = CFURLCreateCopyAppendingPathComponent( NULL, devicePath, kDACALCarouselDocumentInfoFile, FALSE );
	CFUUIDRef		boxUUID = DACAL_BOX_UUID( indexID );
	CFStringRef		boxUUIDString = CFUUIDCreateString( NULL, boxUUID );
	CFDataRef		boxXML = NULL;
	Boolean			goodSave = FALSE;
	Boolean			infoGood = FALSE;
	SInt32			saveErr;
	
	CFMutableDictionaryRef outDict = NULL;

	infoGood = CFURLCreateDataAndPropertiesFromResource( NULL, savePath, &boxXML, NULL, NULL, &saveErr );
	if( !infoGood ) {
		outDict = CFDictionaryCreateMutable( NULL, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks );
		goto HAVEDICT;
	}
		
	outDict = (CFMutableDictionaryRef)CFPropertyListCreateFromXMLData( NULL, boxXML, kCFPropertyListMutableContainersAndLeaves, NULL );
	if( !outDict ) goto BAIL;
	
	CFRelease( boxXML );
	boxXML = NULL;
	
	// Add Key
HAVEDICT:
	CFDictionarySetValue( outDict, (const void*)inKeyName, (const void*)inKeyValue );
		
	// Save the file
	
	boxXML = CFPropertyListCreateXMLData( NULL, (CFPropertyListRef)outDict );
	if( boxXML == NULL ) goto BAIL;
	
	goodSave = CFURLWriteDataAndPropertiesToResource( savePath, boxXML, NULL, &saveErr );
	if( !goodSave ) {
		outResult = saveErr;
		goto BAIL;
	}
	
BAIL:
	if( boxUUIDString ) CFRelease( boxUUIDString );
	if( boxXML ) CFRelease( boxXML );
	if( savePath ) CFRelease( savePath );
	if( outDict ) CFRelease( outDict );
	
	return outResult;
}

DACALResult		CarouselWriteInfoFile( DACALDeviceRef inDevice )
{
	DACALResult		outResult = kIOReturnBadArgument;
	DACALDeviceRef	indexID = dacalDeviceRefToDeviceIndex( inDevice );
	CFURLRef		devicePath = DACAL_BOX_PATH( indexID );
	CFURLRef		savePath = CFURLCreateCopyAppendingPathComponent( NULL, devicePath, kDACALCarouselDocumentInfoFile, FALSE );
	CFUUIDRef		boxUUID = DACAL_BOX_UUID( indexID );
	CFStringRef		boxUUIDString = CFUUIDCreateString( NULL, boxUUID );
	CFDataRef		boxXML = NULL;
	Boolean			goodSave = FALSE;
	SInt32			saveErr;
	
	CFMutableDictionaryRef outDict = NULL;
	
	CFURLSetXattr( devicePath, kDACALCarouselDocumentXAttrCarousel, boxUUIDString );
	
	goodSave = CFURLCreateDataAndPropertiesFromResource( NULL, savePath, &boxXML, NULL, NULL, &saveErr );
	if( !goodSave ) {
		outDict = CFDictionaryCreateMutable( NULL, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks );
		goto HAVEDICT;
	}
	
	outDict = (CFMutableDictionaryRef)CFPropertyListCreateFromXMLData( NULL, boxXML, kCFPropertyListMutableContainersAndLeaves, NULL );
	if( !outDict ) goto BAIL;
	
	CFRelease( boxXML );
	boxXML = NULL;
	
HAVEDICT:
	
	// Add UUID
	
	CFDictionarySetValue( outDict, (const void*)kDACALCarouselDocumentInfoKeyUUID, (const void*)boxUUIDString );
	
	// Add Name

	// If the box doesn't already have a name, assign it one.
	
	if( DACAL_BOX_NAME(indexID) == NULL ) {
		CFStringRef		userShortName = CSCopyUserName( TRUE );
		CFStringRef		newBoxName = CFStringCreateWithFormat( NULL, NULL, kDACALCarouselDocumentDisplayNameFormat, userShortName, indexID+1 );
		if( userShortName ) CFRelease( userShortName );
		if( !newBoxName ) goto BAIL;
		DACAL_BOX_NAME(indexID) = newBoxName;
	}
	
	CFDictionarySetValue( outDict, (const void*)kDACALCarouselDocumentInfoKeyName, (const void*)DACAL_BOX_NAME(indexID) );
	
	// Save the file

	//CFShow( outDict );

	boxXML = CFPropertyListCreateXMLData( NULL, (CFPropertyListRef)outDict );
	if( boxXML == NULL ) goto BAIL;
	
	//CFShow( boxXML );
	
	goodSave = CFURLWriteDataAndPropertiesToResource( savePath, boxXML, NULL, &saveErr );
	if( !goodSave ) {
		outResult = saveErr;
		printf("Write Err: %i\n", (int)saveErr);
		goto BAIL;
	}
	outResult = 0;
	
BAIL:
	if( boxUUIDString ) CFRelease( boxUUIDString );
	if( boxXML ) CFRelease( boxXML );
	if( savePath ) CFRelease( savePath );
	if( outDict ) CFRelease( outDict );
		
	return outResult;
}

DACALResult		CarouselEstablishInfoFile( CFUUIDRef boxUUID )
{
	DACALResult		outResult = kIOReturnBadArgument;
	DACALDeviceRef	indexID = dacalDeviceRefToDeviceIndex( (DACALDeviceRef)boxUUID );
	CFStringRef		uuidString = CFUUIDCreateString( NULL, boxUUID );
	CFStringRef		fileTitle  = CFStringCreateWithFormat( NULL, NULL, CFSTR("%@.%@/"), uuidString, kDACALCarouselDocumentExtension );
	CFURLRef		dataURL = NULL;
	CFURLRef		fileURL = NULL;
	FSRef			userLibraryFolder;
	FSRef			fileFolder;
	Boolean			fileFound = FALSE;
	OSErr			theErr;

	theErr = FSFindFolder( kUserDomain, kDACALCarouselsFolderType, TRUE, &userLibraryFolder );
	if( theErr != 0 ) printf( "CarouselEstablishInfoFile Could not find user library! Error:%i\n", theErr );
	else dataURL = CFURLCreateFromFSRef(NULL, &userLibraryFolder);
	
	if( dataURL ) fileURL = CFURLCreateWithString( NULL, fileTitle, dataURL );
	if( fileURL ) {
		DACAL_BOX_PATH(indexID) = CFRetain( fileURL );
		
		fileFound = CFURLGetFSRef( fileURL, &fileFolder );
		if( fileFound ) { 
			theErr = CarouselReadInfoFile( (DACALDeviceRef)boxUUID );
			goto BAIL;
		}
		
		CFIndex			theUniCount = CFStringGetLength( fileTitle ) - 1;
		UniChar			theUniName[1024];
		
		CFStringGetCharacters( fileTitle, CFRangeMake(0, theUniCount), theUniName );
		theErr = FSCreateDirectoryUnicode( &userLibraryFolder, theUniCount, (const UniChar*)theUniName, kFSCatInfoNone, NULL, &fileFolder, NULL, NULL );
		if( theErr ) goto BAIL;
		
		theErr = CarouselWriteInfoFile( (DACALDeviceRef)boxUUID );
	}

BAIL:

//	if( fileURL ) CFRelease( fileURL );
	if( dataURL ) CFRelease( dataURL );
	if( fileTitle ) CFRelease( fileTitle );
	if( uuidString ) CFRelease( uuidString );
	
	outResult = theErr;	
	return outResult;
}

/*

CFStringRef		CopyUSBProductData( DACALDeviceRef indexID, DACALDeviceNode* outNode )			//note this is really a UUID!
{
	CFStringRef		outName = NULL;
	CFStringRef		uuidName = CFUUIDCreateString( gDACALDefaultCFAllocator, (CFUUIDRef)indexID ); // DACAL_BOX_UUID(indexID) );
	CFStringRef		copyName = NULL;
	CFArrayRef		entryArray = NULL;
	CFNumberRef		copyNode = NULL;
	int				outDeviceNode = 0;
	
	if( indexID == kDACALIllegalDevice ) return( outName );

	entryArray = (CFArrayRef)CFPreferencesCopyValue( uuidName, kDACALPreferencesID, kCFPreferencesAnyUser, kCFPreferencesCurrentHost );
	if( uuidName ) CFRelease( uuidName );

	if( entryArray != NULL )
	{
		copyName = (CFStringRef)CFArrayGetValueAtIndex( entryArray, 0 );
		if( copyName ) {
			outName = CFStringCreateCopy(gDACALDefaultCFAllocator, copyName);
			CFRelease( copyName );
		}
		copyNode = (CFNumberRef)CFArrayGetValueAtIndex( entryArray, 1 );
		if( copyNode ) {
			CFNumberGetValue( copyNode, kCFNumberIntType, &outDeviceNode );
			CFRelease( copyNode );
		}
		CFRelease( entryArray );
	}
	
	if( outNode != NULL ) *outNode = outDeviceNode;
	return( outName );
}

DACALResult		SaveUSBProductData( DACALDeviceRef deviceID, CFStringRef inName, DACALDeviceNode inNode )
{
	DACALDeviceRef	indexID = dacalDeviceRefToDeviceIndex( deviceID );
	CFStringRef		uuidName = CFUUIDCreateString( gDACALDefaultCFAllocator, DACAL_BOX_UUID(indexID) );
	CFStringRef		copyName = NULL;
	CFNumberRef		copyNode = NULL;
	void*			valuePointers[2] = { NULL, NULL };
	CFArrayRef		dataValues = NULL;
	Boolean			prefSaved = FALSE;
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );

	if( inName == NULL ) inName = DACAL_BOX_NAME(indexID);
	if( inName ) copyName = CFStringCreateCopy( gDACALDefaultCFAllocator, inName );
	
	if( inNode == 0 ) inNode = DACAL_BOX_NODE(indexID);
	copyNode = CFNumberCreate( NULL, kCFNumberIntType, &inNode );
	
	valuePointers[0] = (void*)copyName;
	valuePointers[1] = (void*)copyNode;

	dataValues = CFArrayCreate( NULL, (const void**)&valuePointers, 2, &kCFTypeArrayCallBacks );

	CFShow( uuidName );
	CFShow( dataValues );

	CFPreferencesSetValue( uuidName, dataValues, kDACALPreferencesID, kCFPreferencesAnyUser, kCFPreferencesCurrentHost );
	prefSaved = CFPreferencesAppSynchronize( kDACALPreferencesID );

	CFShow( prefSaved ? CFSTR("Synced") : CFSTR("Error") );

	if( dataValues ) CFRelease( dataValues );
	if( copyNode ) CFRelease( copyNode );
	if( copyName ) CFRelease( copyName );
	if( uuidName ) CFRelease( uuidName );	
	return( (prefSaved == FALSE) );
}

*/

CFStringRef		CFStringCreateFromDacalString( dacalString* deviceBlock ) {
	return( CFStringCreateWithCharacters( gDACALDefaultCFAllocator, (UniChar*)&deviceBlock->uniString, deviceBlock->stringSize));
}	

CFStringRef		CFStringCreateFromDacalPipe( CFAllocatorRef inAllocator, CFStringRef inCommandArgs, DACALResult* outError )
{
	DACALResult		outResult = kIOReturnBadArgument;
	CFStringRef		outCFText = NULL;
	CFStringRef		theCommand = CFSTR("carousel");
	CFStringRef		errUnknown = CFSTR("carousel.sh:");
	CFURLRef		commandURL = CFBundleCopyResourceURL( CFBundleGetMainBundle(), theCommand, CFSTR("sh"), NULL );
	CFStringRef		doCFCommand;
	char*			doCommand = NULL;
	char*			utf8Name = NULL;
	FILE*			pipe;
	int				pipeSize = 8192;
	
	
	if( inAllocator == NULL ) inAllocator = gDACALDefaultCFAllocator;
	
	doCFCommand = CFStringCreateWithFormat(	inAllocator, NULL, CFSTR("\"%@\" %@"), commandURL, inCommandArgs );
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
		
		if( CFStringHasPrefix( outCFText, errUnknown ) == TRUE ) {
			CFRelease( outCFText );
			outCFText = (CFStringRef)NULL;
		}
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

IOReturn		dacalGetDescriptor(IOUSBDeviceInterface245 **deviceIntf, UInt16 index, UInt8 descType, UInt8 descIndex, void *buf, UInt16 len, UInt16 *result) {
    IOUSBDevRequest req;
    IOReturn err;
	
	bzero(&req, sizeof(req));
    req.bmRequestType = USBmakebmRequestType(kUSBAnyDirn, kUSBStandard, kUSBDevice);
    req.bRequest = kUSBRqGetDescriptor;
    req.wValue = (descType << 8) | descIndex;
    req.wIndex = index;
    req.wLength = len;
    req.pData = buf;
   	bzero(buf, len);
    err = (*deviceIntf)->DeviceRequest(deviceIntf, &req);
	*result = req.wLenDone;
	return err;
}

IOReturn		dacalDoRequest(IOUSBDeviceInterface245** indeviceIntf, dacalCmd cmd, dacalString* outResult) {
	UInt16		result;
	IOReturn err;
	time_t	waitTime;
	CFStringRef descriptorStr;
	CFComparisonResult compareResult;
	dacalString	uniBuf;
	
	if( gDACALVerbose ) printf("dacal: DoCmd %d\n", cmd);
	
	waitTime = time(NULL);
	if (waitTime == -1) {
		printf("dacal: internal error, could not get time value\n");
		return (IOReturn)kIOReturnError;
	}
	waitTime += 10;
	while( true ) {
	tryagain:
		if (time(NULL) > waitTime) {
			if( gDACALVerbose ) printf("dacal: DoCmd timed out\n");
			return (IOReturn)kIOReturnError;
		}
		err = dacalGetDescriptor(indeviceIntf, 0x0409, kUSBStringDesc, cmdGetStatus, &uniBuf, sizeof(uniBuf), &result);
		if (err == kIOReturnNotResponding) {
			sleep(2);
			goto tryagain;
		}
		if (err) {
			if( gDACALVerbose ) printf("dacal: DoCmd reporting error from device: %x\n", err);
			return err;
		}
		descriptorStr = CFStringCreateFromDacalString(&uniBuf);
#ifdef __DCDEBUG			
	NSLog( @"Device Status: %@\n", descriptorStr );		
#endif
		compareResult = CFStringCompareWithOptions(descriptorStr, dacalERROR, CFRangeMake(0,CFStringGetLength(dacalERROR)), kCFCompareCaseInsensitive);
		if (compareResult == kCFCompareEqualTo) {
			if( gDACALVerbose ) printf("dacal: DoCmd reporting error from device\n");
			return (IOReturn)kDACALError;
		}
		
		compareResult = CFStringCompareWithOptions(descriptorStr, dacalBUSY, CFRangeMake(0,CFStringGetLength(dacalBUSY)), kCFCompareCaseInsensitive);
		if (compareResult == kCFCompareEqualTo) {
			if( gDACALVerbose ) printf("dacal: DoCmd reporting busy\n");
			return (IOReturn)kDACALBusy;
		}

		compareResult = CFStringCompareWithOptions(descriptorStr, dacalACK, CFRangeMake(0,CFStringGetLength(dacalACK)), kCFCompareCaseInsensitive);
		if (compareResult == kCFCompareEqualTo)
			break;
		
		compareResult = CFStringCompareWithOptions(descriptorStr, dacalNUMBER, CFRangeMake(0,CFStringGetLength(dacalNUMBER)), kCFCompareCaseInsensitive);
		if (compareResult == kCFCompareEqualTo)
			break;
		
	}
	err = dacalGetDescriptor(indeviceIntf, 0x0409, kUSBStringDesc, cmd, outResult, sizeof(dacalString), &result);
	return err;
}	

DACALCount			dacalDeviceRefToDeviceIndex( DACALDeviceRef deviceID )
{
	SInt8		checkIndex = 0;

	if( gDACALBoxes.boxCount == 0 ) return( kDACALIllegalDevice );							// No Boxes
	if( deviceID == kDACALDefaultDevice ) return( gDACALDefaultDevice - 1 );				// Default Box
	if( (1 <= deviceID) & (deviceID <= gDACALBoxes.boxCount) ) return ( deviceID - 1 );		// Actual Device
	
//	for( checkIndex = 0; checkIndex < gDACALBoxes.boxCount; checkIndex++ )					// Node ID
//		if( DACAL_BOX_NODE(checkIndex) == deviceID ) return( checkIndex );

	if( deviceID > kDACALIllegalDevice )										
	{
		CFUUIDRef	possibleID = (CFUUIDRef)deviceID;
		CFStringRef	possibleName = (CFStringRef)deviceID;
		
		if( CFGetTypeID(possibleID) == CFUUIDGetTypeID() )									// UUID?
			for( checkIndex=0; checkIndex < gDACALBoxes.boxCount; checkIndex++ )
				if( DACAL_BOX_UUID(checkIndex) )
					if( CFEqual( DACAL_BOX_UUID(checkIndex), possibleID ) ) return( checkIndex );
				
		if( CFGetTypeID(possibleName) == CFStringGetTypeID() )								// Name?
			for( checkIndex=0; checkIndex < gDACALBoxes.boxCount; checkIndex++ )
				if( DACAL_BOX_NAME(checkIndex) )
					if( CFEqual( DACAL_BOX_NAME(checkIndex), possibleName ) ) return( checkIndex );
	}
	
	return( kDACALIllegalDevice );
}

DACALResult		DACALCommandRequest( DACALDeviceRef deviceID, DACALCommand deviceCommand, dacalString* outResult )
{
	DACALCount			indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	
	return dacalDoRequest( gDACALBoxes.box[indexID].boxRef, deviceCommand, outResult );
}

DACALResult		DACALCommandRequestNoResult( DACALDeviceRef deviceID, DACALCommand deviceCommand )
{
	dacalString			ourResult;
	DACALCount			indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	
	return dacalDoRequest( gDACALBoxes.box[indexID].boxRef, deviceCommand, &ourResult );
}

CFStringRef		DACALCommandRequestCFString( DACALDeviceRef deviceID, DACALCommand deviceCommand, DACALResult* outError )
{
	DACALResult			theErr;
	dacalString			ourResult;
	CFStringRef			theString = NULL;
	DACALCount			indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) {
		if( outError ) *outError = kIOReturnNoDevice;
		return( theString );
	}
	
	theErr = DACALCommandRequest( deviceID, deviceCommand, &ourResult );
	if( outError ) *outError = theErr;
	if( theErr ) return( theString );
	
	theString = CFStringCreateFromDacalString( &ourResult );
	
	return( theString );
}

CFStringRef		DACALCommandCopyStatus( DACALDeviceRef deviceID, DACALResult* outError )
{
	DACALResult		theErr;
	dacalString		ourResult;
	CFStringRef		theString = NULL;
	
	theErr = DACALCommandRequest( deviceID, cmdGetStatus, &ourResult );
	if( outError ) *outError = theErr;
	if( theErr ) return( theString );
	
	theString = CFStringCreateFromDacalString( &ourResult );
	
	return( theString );
}

CFUUIDRef		DACALCommandCopyUUID( DACALDeviceRef deviceID, DACALResult* outError )
{
	DACALResult		theErr;
	dacalString		ourResult;
	
	CFUUIDBytes*	bytes;
	CFUUIDRef		deviceUUID = NULL;
	DACALDeviceRef	indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) {
		if( outError ) *outError = kIOReturnNoDevice;
		return( deviceUUID );
	}
	
	deviceUUID = DACAL_BOX_UUID(indexID);
	
	if( deviceUUID != NULL ) return ( CFUUIDCreateFromUUIDBytes(gDACALDefaultCFAllocator, CFUUIDGetUUIDBytes(deviceUUID)) );
	
	bzero(&ourResult, sizeof(ourResult));
	theErr = DACALCommandRequest( deviceID, cmdGetUUID, &ourResult );
	if( outError ) *outError = theErr;
	if( theErr ) return( (CFUUIDRef)NULL );
	
	{
		long long   showlong = 0;
		CFStringRef showIt = NULL;
		CFNumberRef	showNum = CFNumberCreate( NULL, kCFNumberSInt64Type, ourResult.uniString);
		CFNumberGetValue( showNum, kCFNumberSInt64Type, &showlong );
//		CFShow( showNum );
		CFRelease( showNum ); 
		
//		printf("showlong: %lli, big endian: %lli, hex: %#llX\n", showlong, CFSwapInt64(showlong), showlong);
		showIt = CFStringCreateWithFormat( NULL, NULL, CFSTR("UUID(%i) %#llX"),(int)indexID, showlong );
		//CFShow( showIt );	// this is the hex node id?
	}
	
	bytes = (CFUUIDBytes*)ourResult.uniString;	
	deviceUUID = CFUUIDCreateFromUUIDBytes(gDACALDefaultCFAllocator, *bytes);
	if( deviceUUID ) DACAL_BOX_UUID(indexID) = deviceUUID;

	//CFShow( deviceUUID );
	
	if( deviceUUID ) return( CFUUIDCreateFromUUIDBytes(gDACALDefaultCFAllocator, CFUUIDGetUUIDBytes(deviceUUID)) );	
	return( deviceUUID );
}

CFStringRef		DACALCommandCopyModel( DACALDeviceRef deviceID, DACALResult* outError )
{
	DACALResult			theErr;
	CFStringRef			descriptorStr;
	CFComparisonResult	compareResult;
	
	CFStringRef			modelName = NULL;
	DACALCount			indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) {
		if( outError ) *outError = kIOReturnNoDevice;
		return( modelName );
	}
	
	modelName = DACAL_BOX_MODEL(indexID);
	if( modelName != NULL ) return ( CFStringCreateCopy(gDACALDefaultCFAllocator,modelName) );
	
	descriptorStr = DACALCommandRequestCFString( deviceID, cmdGetModel, &theErr );
	if( outError ) *outError = theErr;
	if( theErr ) return( modelName );
	
	compareResult = CFStringCompareWithOptions(descriptorStr, dacalDC300, CFRangeMake(0,CFStringGetLength(dacalDC300)), kCFCompareCaseInsensitive);
	if (compareResult == kCFCompareEqualTo) modelName = DACALDC300CFName;
	else {
		compareResult = CFStringCompareWithOptions(descriptorStr, dacalDC016RW, CFRangeMake(0,CFStringGetLength(dacalDC016RW)), kCFCompareCaseInsensitive);
		if (compareResult == kCFCompareEqualTo) modelName = DACALDC016RWCFName;
		else modelName = descriptorStr;
	}
	
	DACAL_BOX_MODEL(indexID) = modelName;
//	if( modelName ) CFRetain( modelName );
	
	return( modelName );
}

DACALResult		DACALCommandReset( DACALDeviceRef deviceID )
{
	DACALResult theErr = DACALCommandRequestNoResult( deviceID, cmdReset );	

	DACAL_RESET_SLEEP
	
	return( theErr );
}

DACALResult		DACALCommandCloseDoor( DACALDeviceRef deviceID )
{
	DACALResult theErr = DACALCommandRequestNoResult( deviceID, cmdCloseDoor );	

	if( theErr == 0 ) {
		DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
		
		DACAL_BOX_LASTSLOT(indexID)		= 0;
		DACAL_BOX_LASTSLOTTIME(indexID)	= -1;
	} 

	DACAL_SHORT_SLEEP
	
	return( theErr );
}

DACALResult		DACALCommandSetLED( DACALDeviceRef deviceID, Boolean isVisible )
{
	DACALResult		theErr;
	
	if( isVisible )	theErr = DACALCommandRequestNoResult( deviceID, cmdLEDOn );
	else			theErr = DACALCommandRequestNoResult( deviceID, cmdLEDOff );
	
	DACAL_SHORT_SLEEP
	
	return( theErr );	
}

DACALResult		DACALCommandMoveToSlotWithOptions( DACALDeviceRef deviceID, DACALSlotNum newSlot, DACALOptionBits moveOptions )
{
	DACALResult		theErr = kIOReturnNoDevice;
	dacalString		slotBuffer;
	UInt16			result;
	Boolean			moveOnce		= moveOptions == kDACALOptionMoveOnce;
	Boolean			moveOpenSlot	= moveOptions == kDACALOptionMoveOpenSlot;
	Boolean			moveToggle		= moveOptions == kDACALOptionMoveToggle;
	Boolean			doClose			= !moveOpenSlot;
	Boolean			doOpen			= TRUE;
	
	
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	DACALSlotNum	theLastSlot = DACAL_BOX_LASTSLOT(indexID);
	time_t			theLastTime = DACAL_BOX_LASTSLOTTIME(indexID);
	
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	
	if( moveToggle ) {
		if( theLastSlot != newSlot ) {
			doClose = TRUE;
			doOpen = TRUE;
		} else {
			doClose = (theLastTime != -1);
			doOpen = !doClose;
		}
	}
	
	if( moveOnce ) 
		if( theLastSlot == newSlot ) return( kDACALBusy );
	
	if( doClose )	{
		theErr = DACALCommandCloseDoor( deviceID );
		if( theErr ) goto ERRORBAIL;
	}
	
	if( doClose && doOpen ) DACAL_SHORT_SLEEP
	
	if( doOpen )	{
		theErr = DACALCommandRequestNoResult( deviceID, cmdMoveToSlot );	
		theErr = dacalGetDescriptor(gDACALBoxes.box[indexID].boxRef, 0x0409, kUSBStringDesc, newSlot, &slotBuffer, sizeof(slotBuffer), &result);
	}
	
ERRORBAIL:
	if( (theErr == 0) && (moveToggle) ) 
		if( theLastSlot == newSlot )
		{
			if( theLastTime == -1 ) 
				DACAL_BOX_LASTSLOTTIME(indexID) = time(NULL);
			if( theLastTime != -1 )
				DACAL_BOX_LASTSLOTTIME(indexID) = -1;
			return( theErr );
		}
		
	if( theErr == 0 ) {
		DACAL_BOX_LASTSLOT(indexID)		= newSlot;
		DACAL_BOX_LASTSLOTTIME(indexID)	= time(NULL);
	} else {
		DACAL_BOX_LASTSLOT(indexID)		= 0;
		DACAL_BOX_LASTSLOTTIME(indexID)	= -1;
	}
	
	return( theErr );
}

DACALResult		DACALCommandMoveToSlot( DACALDeviceRef deviceID, DACALSlotNum newSlot )
	{	return DACALCommandMoveToSlotWithOptions( deviceID, newSlot, kDACALOptionMoveDefault );	}
/*
{
	DACALResult		theErr;
	dacalString		slotBuffer;
	UInt16			result;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	
	theErr = DACALCommandCloseDoor( indexID );
	if( theErr ) return theErr;
	DACAL_SHORT_SLEEP
	
	theErr = DACALCommandRequestNoResult( indexID, cmdMoveToSlot );	
	DACAL_SHORT_SLEEP
	theErr = dacalGetDescriptor(gDACALBoxes.box[indexID].boxRef, 0x0409, kUSBStringDesc, newSlot, &slotBuffer, sizeof(slotBuffer), &result);
//	DACAL_SHORT_SLEEP

	if( theErr == 0 ) {
		DACAL_BOX_LASTSLOT(indexID)		= newSlot;
		DACAL_BOX_LASTSLOTTIME(indexID)	= time(NULL);
	} else {
		DACAL_BOX_LASTSLOT(indexID)		= 0;
		DACAL_BOX_LASTSLOTTIME(indexID)	= -1;
	}
	return( theErr );
}
*/

DACALSlotNum	DACALCommandDVDGetSlot( DACALDeviceRef deviceID, DACALResult* outError )
{
	DACALResult			theErr;
	CFStringRef			descriptorStr;
	CFComparisonResult	compareResult;
	
	DACALSlotNum		outSlot = 0;
	
	descriptorStr = DACALCommandRequestCFString( deviceID, cmdGetSlot, &theErr );
	if( outError ) *outError = theErr;
	if( theErr ) return( outSlot );
	DACAL_SHORT_SLEEP
	
	compareResult = CFStringCompareWithOptions(descriptorStr, dacalNAN, CFRangeMake(0,CFStringGetLength(dacalDC300)), kCFCompareCaseInsensitive);
	if (compareResult == kCFCompareEqualTo) outSlot = 0;
	else outSlot = CFStringGetIntValue( descriptorStr );
	
	if( descriptorStr ) CFRelease( descriptorStr );
	
	return( outSlot );
}

DACALResult		DACALCommandDVDMoveTo( DACALDeviceRef deviceID, DACALSlotNum newSlot )
{
	DACALResult		theErr;
	dacalString		slotBuffer;
	UInt16			result;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	
	theErr = DACALCommandRequestNoResult( deviceID, cmdMoveToDVD );
	if( theErr ) return( theErr );
	DACAL_SHORT_SLEEP

	theErr = dacalGetDescriptor(gDACALBoxes.box[indexID].boxRef, 0x0409, kUSBStringDesc, newSlot, &slotBuffer, sizeof(slotBuffer), &result);
	DACAL_SHORT_SLEEP
	
	return( theErr );
}

DACALResult		DACALCommandDVDEject( DACALDeviceRef deviceID )
{
	DACALResult theErr = DACALCommandRequestNoResult( deviceID, cmdEjectDVD );	
	DACAL_SHORT_SLEEP
	
	return( theErr );	
}

CFStringRef		DACALCommandCopyName( DACALDeviceRef deviceID, DACALResult* outError )
{
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	CFStringRef		nameCopy = NULL;
	
	if( indexID == kDACALIllegalDevice ) {
		if( outError ) *outError = kIOReturnNoDevice;
		return( nameCopy );
	}
	
	if( outError ) *outError = 0;
	nameCopy = DACAL_BOX_NAME(indexID);
	if( nameCopy ) return( CFStringCreateCopy(gDACALDefaultCFAllocator, nameCopy) );

	return( nameCopy );
}

DACALResult			DACALCommandSetName( DACALDeviceRef deviceID, CFStringRef deviceName )
{
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	
	
	if( deviceName && DACAL_BOX_NAME(indexID) ) CFRelease( DACAL_BOX_NAME(indexID) );
	if( deviceName ) DACAL_BOX_NAME(indexID) = CFStringCreateCopy( NULL, deviceName );
//	else DACAL_BOX_NAME(indexID) = deviceName;

	return CarouselWriteInfoFile( deviceID );
//	return SaveUSBProductData( deviceID, deviceName, 0 );
}

DACALDeviceNode		DACALCommandCopyNode( DACALDeviceRef deviceID, DACALResult* outError )
{
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) {
		if( outError ) *outError = kIOReturnNoDevice;
		return( 0 );
	}
	
	if( outError ) *outError = 0;
	return( (DACALDeviceNode)indexID+1 );
}

/*
 DACALResult			DACALCommandSetNode( DACALDeviceRef deviceID, DACALDeviceNode deviceNode )
{
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	
//	DACAL_BOX_NODE(indexID) = deviceNode;

	return CarouselWriteInfoFile( deviceID );
//	return SaveUSBProductData( deviceID, DACAL_BOX_NAME(indexID), deviceNode );
}
*/

DACALSlotNum		DACALCommandGetSlotCount( DACALDeviceRef deviceID )
{
	DACALSlotNum	badSlotCount = 0;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) return( badSlotCount );
	if( DACAL_BOX_MODEL(indexID) == NULL ) return( badSlotCount );
	
	return( DACALDevicesGetSlotCount(DACAL_BOX_MODEL(indexID)) );
}

CFURLRef		DACALCommandCopyPath( DACALDeviceRef deviceID, DACALResult* outError )
{
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	CFURLRef		pathCopy = NULL;
	
	if( indexID == kDACALIllegalDevice ) {
		if( outError ) *outError = kIOReturnNoDevice;
		return( pathCopy );
	}
	
	if( outError ) *outError = 0;
	pathCopy = DACAL_BOX_PATH(indexID);
	if( pathCopy ) return( CFURLCreateCopyAppendingPathComponent(gDACALDefaultCFAllocator, pathCopy, CFSTR(""), FALSE) );
	
	return( pathCopy );
}	

CFMutableArrayRef		DACALCommandCopyAllSlotPaths( DACALDeviceRef deviceID, DACALResult* outError )
{
	DACALCount			indexID = dacalDeviceRefToDeviceIndex( deviceID );
	DACALResult			outResult;
	CFURLRef			pathCopy = NULL;
	CFDictionaryRef		dataDict = NULL;
	CFArrayRef			dataProps = CFArrayCreate(NULL, (const void**)&kCFURLFileDirectoryContents, 1, &kCFTypeArrayCallBacks);
	CFArrayRef			folderList = NULL;
	CFMutableArrayRef	slotList = NULL;
	CFURLRef			testSlot = NULL;
	Boolean				wasFound = FALSE;
	SInt32				cfError;
	int					index;
	
	if( indexID == kDACALIllegalDevice ) {
		if( outError ) *outError = kIOReturnNoDevice;
		return( slotList );
	}
	
	pathCopy = DACALCommandCopyPath( deviceID, outError);
	if( pathCopy == NULL) return( slotList );
	
	wasFound = CFURLCreateDataAndPropertiesFromResource(NULL, pathCopy, NULL, &dataDict, dataProps, &cfError);
	if( wasFound ) {
		folderList = (CFArrayRef)CFDictionaryGetValue( dataDict, kCFURLFileDirectoryContents );
		if( folderList != NULL )	
		{
			// CFShow( folderList );
			slotList = CFArrayCreateMutable(NULL, CFArrayGetCount(folderList) , &kCFTypeArrayCallBacks );
			if( slotList ) {
				for( index=0; index < CFArrayGetCount(folderList); index++ ) {
					testSlot = (CFURLRef)CFArrayGetValueAtIndex( folderList, index );
					if( CFURLIsSlot( testSlot ) ) CFArrayAppendValue( slotList, (const void*)testSlot );
				}
			// CFShow( slotList );
			}
		}
		CFRelease( dataDict );
		outResult = 0;
	} else {
		outResult = cfError;
	}
	
	if( outError != NULL ) *outError = outResult;
	return( slotList );
}

DACALResult		DACALSlotCreateIndex( DACALDeviceRef deviceID, DACALSlotNum slotNum, CFStringRef slotTitle, DACALCount indexLevel, CFURLRef sourcePath )
{
	DACALResult		outResult = kIOReturnBadArgument;
	CFStringRef		doCFCommand;
	CFStringRef		doCommand;
	CFStringRef		sourceType = CFSTR("-n");
	UTF8Char*		sourceFilePath;
	Boolean			goodPath;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	CFStringRef		boxUUID = CFUUIDCreateString( NULL, DACAL_BOX_UUID(indexID) );
	
	CFURLRef		slotURL = NULL;
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	
	if( sourcePath != NULL ) {
		sourceFilePath = (UTF8Char*)calloc(1,4096);
		goodPath = CFURLGetFileSystemRepresentation( sourcePath, TRUE, sourceFilePath, 4096 );
		sourceType = CFStringCreateWithFormat( gDACALDefaultCFAllocator, NULL, CFSTR("-d \"%s\""), sourceFilePath );
		free( sourceFilePath );
	}
	
//	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL,
//										   CFSTR("-x -c %i -s %i -t \"%@\" -l %i %@"), 
//										   indexID + 1, slotNum, slotTitle, indexLevel, sourceType );
	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL,
											CFSTR("-x -c %@ -s %i -t \"%@\" -l %i %@"), 
											boxUUID, slotNum, slotTitle, indexLevel, sourceType );
	if( doCFCommand == NULL ) goto BAIL;

	CFShow(CFSTR("Driver call:"));
	CFShow( doCFCommand );
	
	doCommand = CFStringCreateFromDacalPipe( gDACALDefaultCFAllocator, doCFCommand, &outResult );	
	if( doCommand != NULL ) CFRelease( doCommand );

	slotURL = DACALSlotCopyPath( deviceID, slotNum, &outResult );
	if( slotURL ) CFURLSetXattr( slotURL, kDACALCarouselDocumentXAttrSlotAddDate, (CFStringRef)[[NSDate date] description]);
	if( slotURL)		CFRelease( slotURL );
	
BAIL:
	if( doCFCommand )	CFRelease( doCFCommand );
	if( sourceType )	CFRelease( sourceType );
	if( boxUUID )		CFRelease( boxUUID );
	return( outResult );
}

DACALResult		DACALSlotDeleteIndex( DACALDeviceRef deviceID, DACALSlotNum slotNum )
{
	DACALResult		outResult;
	CFStringRef		doCFCommand = NULL;
	CFStringRef		pipeResult = NULL;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	CFStringRef		boxUUID = CFUUIDCreateString( NULL, DACAL_BOX_UUID(indexID) );
	
	if( indexID == kDACALIllegalDevice ) {
		outResult = kIOReturnNoDevice;
		goto BAIL;
	}
	
//	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL, CFSTR("-c %i -s %i -k"), indexID + 1, slotNum );
	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL, CFSTR("-c %@ -s %i -k"), boxUUID, slotNum );
	if( doCFCommand == NULL ) {
		outResult = kIOReturnNoDevice;
		goto BAIL;
	}

	pipeResult = CFStringCreateFromDacalPipe( gDACALDefaultCFAllocator, doCFCommand, &outResult );	

BAIL:
	if( pipeResult != NULL ) CFRelease( pipeResult );
	if( boxUUID ) CFRelease( boxUUID );	
	CFRelease( doCFCommand );
	return( outResult );
}

CFStringRef		DACALSlotCopyTitle( DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult* outError )
{
	DACALResult		theErr = kIOReturnBadArgument;
	CFStringRef		outputString = NULL;
	CFStringRef		doCFCommand = NULL;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	CFStringRef		boxUUID = NULL;
	
	if( indexID == kDACALIllegalDevice ) {
		theErr = kIOReturnNoDevice;
		goto BAIL;
	}

	boxUUID = CFUUIDCreateString( NULL, DACAL_BOX_UUID(indexID) );
	if( boxUUID == NULL ) goto BAIL;
	
//	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL, CFSTR("-c %i -s %i -w"), indexID + 1, slotNum );
	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL, CFSTR("-c %@ -s %i -w"), boxUUID, slotNum );
	if( doCFCommand == NULL ) goto BAIL;
	
	outputString = CFStringCreateFromDacalPipe( gDACALDefaultCFAllocator, doCFCommand, outError );
	theErr = kDACALOK;
	
BAIL:
	if( doCFCommand )	CFRelease( doCFCommand );
	if( boxUUID )		CFRelease( boxUUID );	
	
	if( outError ) *outError = theErr;
	return( outputString );
}

DACALResult		DACALSlotSetTitle( DACALDeviceRef deviceID, DACALSlotNum slotNum, CFStringRef slotTitle )
{
	DACALResult		outResult = kIOReturnBadArgument;
	CFStringRef		doCFCommand;
	CFStringRef		doCommand;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	CFStringRef		boxUUID = CFUUIDCreateString( NULL, DACAL_BOX_UUID(indexID) );
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
		
	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL,
										   CFSTR("-c %@ -s %i -R \"%@\""), 
										   boxUUID, slotNum, slotTitle );
	if( doCFCommand == NULL ) goto BAIL;
	
	if( gDACALVerbose )
	{
		CFShow(CFSTR("Driver call DACALSlotSetTitle:"));
		CFShow( doCFCommand );
	}
	
	doCommand = CFStringCreateFromDacalPipe( gDACALDefaultCFAllocator, doCFCommand, &outResult );	
	if( doCommand != NULL ) CFRelease( doCommand );
	
BAIL:
	if( doCFCommand )	CFRelease( doCFCommand );
	if( boxUUID )		CFRelease( boxUUID );
	return( outResult );
}

CFURLRef		DACALSlotCopyPath( DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult* outError )
{
	CFURLRef	outURL = NULL;
	CFURLRef	boxURL = DACALCommandCopyPath( deviceID, outError );
	CFStringRef	slotName = NULL;
	FSRef		slotRef;
	Boolean		goodSlot = FALSE;
	
	if( boxURL == NULL ) return outURL;
	
	slotName = CFStringCreateWithFormat( gDACALDefaultCFAllocator, NULL, CFSTR("Slot %i"), (int)slotNum );
	if( slotName ) {
		outURL = CFURLCreateCopyAppendingPathComponent( gDACALDefaultCFAllocator, boxURL, slotName, TRUE );
		CFRelease( slotName );
	}
	
	// check if real?
	if( outURL ) {
		goodSlot = CFURLGetFSRef( outURL, &slotRef );
		if( !goodSlot) {
			CFRelease( outURL );
			outURL = NULL;
		}
	}
	
	return outURL;
}	
/*
CFURLRef		DACALSlotCopyPath( DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult* outError )
{
	DACALResult		outResult = kIOReturnBadArgument;
	CFURLRef		outPathURL = NULL;
	CFStringRef		outPathString = NULL;
	CFStringRef		doCFCommand = NULL;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	CFStringRef		boxUUID = NULL;
	
	if( indexID == kDACALIllegalDevice ) {
		outResult = kIOReturnNoDevice;
		goto BAIL;
	}
	
	boxUUID = CFUUIDCreateString( gDACALDefaultCFAllocator, DACAL_BOX_UUID(indexID) );
	if( boxUUID == NULL ) goto BAIL;
	
	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL, CFSTR("-c %@ -s %i -p"), boxUUID, slotNum );
	if( doCFCommand == NULL ) goto BAIL;

	outPathString = CFStringCreateFromDacalPipe( gDACALDefaultCFAllocator, doCFCommand, &outResult );	
	if( outPathString == NULL ) goto BAIL;

	//NSLog(@"Slot: %i  Path: %@", slotNum, (NSString*)outPathString);
	
	outPathURL = CFURLCreateWithFileSystemPath( gDACALDefaultCFAllocator, outPathString, kCFURLPOSIXPathStyle, TRUE );

BAIL:
	if( outError ) *outError = outResult;
	if( outPathString )	CFRelease( outPathString );
	if( doCFCommand )	CFRelease( doCFCommand );
	if( boxUUID )		CFRelease( boxUUID );	
	return( outPathURL );
}
 */

CFStringRef		DACALSlotCopyType( DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult* outError )
{
	DACALResult		outResult = kIOReturnBadArgument;
	CFStringRef		slotType = NULL;
	CFURLRef		slotURL = DACALSlotCopyPath(deviceID, slotNum, &outResult );
	
	if( outResult != 0 ) goto BAIL;
	if( slotURL == NULL ) {
		outResult = kIOReturnBadArgument;
		goto BAIL;
	}
	
	slotType = CFURLCopyXattr( gDACALDefaultCFAllocator, slotURL, kDACALCarouselDocumentXAttrSlotKind, (OSStatus*)&outResult );
	
BAIL:
	if( outError ) *outError = outResult;
	if( slotURL )	CFRelease( slotURL );
	return( slotType );
}

DACALResult		DACALSlotSetType( DACALDeviceRef deviceID, DACALSlotNum slotNum, CFStringRef slotType )
{
	DACALResult		outResult = kIOReturnBadArgument;
	CFURLRef		slotURL = DACALSlotCopyPath(deviceID, slotNum, &outResult );
	
	if( outResult != 0 ) goto BAIL;
	if( slotURL == NULL ) {
		outResult = kIOReturnBadArgument;
		goto BAIL;
	}
	
	outResult = CFURLSetXattr( slotURL, kDACALCarouselDocumentXAttrSlotKind, slotType );
	
BAIL:
	if( slotURL )	CFRelease( slotURL );
	return( outResult );
}

	
	
/*	DACALResult		outResult = kIOReturnBadArgument;
	CFStringRef		doCFCommand;
	CFStringRef		doCommand;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	CFStringRef		boxUUID = CFUUIDCreateString( NULL, DACAL_BOX_UUID(indexID) );
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	
	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL,
										   CFSTR("-c %@ -s %i -K \"%@\""), 
										   boxUUID, slotNum, slotType );
	if( doCFCommand == NULL ) goto BAIL;
	
	if( gDACALVerbose )
	{
		CFShow(CFSTR("Driver call DACALSlotSetType:"));
		CFShow( doCFCommand );
	}
	
	doCommand = CFStringCreateFromDacalPipe( gDACALDefaultCFAllocator, doCFCommand, &outResult );	
	if( doCommand != NULL ) CFRelease( doCommand );
	
BAIL:
	if( doCFCommand )	CFRelease( doCFCommand );
	if( boxUUID )		CFRelease( boxUUID );
	return( outResult );
*/


DACALSlotNum	DACALSlotNextFreeNumber( DACALDeviceRef deviceID, DACALSlotNum lowestSlot, DACALSlotNum highestSlot, DACALResult* outError )
{
	DACALSlotNum	outSlot = 0;
	DACALSlotNum	maxSlot = DACALCommandGetSlotCount( deviceID );
	
	if( lowestSlot == 0 ) lowestSlot = 1;		// Unused!  :(
	if( (highestSlot == 0) | (highestSlot > maxSlot) ) highestSlot = maxSlot;
	if( lowestSlot > highestSlot ) {
		maxSlot = lowestSlot;
		lowestSlot = highestSlot;
		highestSlot = maxSlot;
	}
	
	DACALResult		outResult = kIOReturnBadArgument;
	CFURLRef		outPathURL = NULL;
	CFStringRef		outPathString = NULL;
	CFStringRef		doCFCommand = NULL;
	CFStringRef		outSlotConstName = NULL;
	CFMutableStringRef		outSlotName = NULL;
	CFRange			slotRange;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	CFStringRef		boxUUID = NULL;
	
	if( indexID == kDACALIllegalDevice ) {
		outResult = kIOReturnNoDevice;
		goto BAIL;
	}

	boxUUID = CFUUIDCreateString( NULL, DACAL_BOX_UUID(indexID) );
	if( boxUUID == NULL ) goto BAIL;
	
//	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL, CFSTR("-c %i -s %i -N"), indexID + 1, highestSlot );
	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL, CFSTR("-c %@ -m %i -s %i -N"), boxUUID, lowestSlot, highestSlot );
	if( doCFCommand == NULL ) goto BAIL;

	outPathString = CFStringCreateFromDacalPipe( gDACALDefaultCFAllocator, doCFCommand, &outResult );	
	if( outPathString == NULL ) goto BAIL;

	outPathURL = CFURLCreateWithFileSystemPath( gDACALDefaultCFAllocator, outPathString, kCFURLPOSIXPathStyle, TRUE );
	if( outPathURL != NULL ) {
		outSlotConstName = CFURLCopyLastPathComponent( outPathURL );
		outSlotName = CFStringCreateMutableCopy( gDACALDefaultCFAllocator, 0, outSlotConstName );
		slotRange = CFRangeMake( 0, 5 );
		CFStringDelete( outSlotName, slotRange );
		outSlot = (DACALSlotNum)CFStringGetIntValue( outSlotName );
		
		CFRelease( outSlotName );
		CFRelease( outSlotConstName );
	}

BAIL:
	if( outError ) *outError = outResult;
	if( outPathString )	CFRelease( outPathString );
	if( doCFCommand )	CFRelease( doCFCommand );
	if( boxUUID )		CFRelease( boxUUID );	
	
	return( outSlot );
}


DACALResult		DACALDevicesSetCFAllocator( CFAllocatorRef defaultAlloc )
{
	gDACALDefaultCFAllocator = defaultAlloc;
	return( kDACALOK );
}

CFAllocatorRef	DACALDevicesGetCFAllocator( void )
{
	return( gDACALDefaultCFAllocator );
}


DACALResult		DACALDevicesSetDefaultDevice( DACALDeviceRef deviceID )
{
	DACALCount				indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	gDACALDefaultDevice = deviceID;
	return( kDACALOK );
}

DACALDeviceRef	DACALDevicesGetDefaultDevice( void )
{
	return( gDACALDefaultDevice );
}

DACALCount	DACALDevicesGetCountForModel( CFStringRef aDeviceType )
{
	DACALCount		actualBoxCount = gDACALBoxes.boxCount;
	DACALCount		outBoxCount = 0;
	DACALCount		index;
	
	if( aDeviceType == NULL ) return( actualBoxCount );
	
	for( index=0; index<actualBoxCount; index++ )
		if( DACAL_BOX_MODEL(index) )
			if( CFStringCompare( DACAL_BOX_MODEL(index), aDeviceType, 0) == 0 ) outBoxCount++;
	
	return( outBoxCount );
}

DACALSlotNum		DACALDevicesGetSlotCount( CFStringRef aDeviceType )
{
	DACALSlotNum	badSlotCount = 0;
	DACALSlotNum	dc101SlotCount = 150;
	DACALSlotNum	dc300SlotCount = 150;
	DACALSlotNum	dc016SlotCount = 100;

	if( aDeviceType == NULL ) return( badSlotCount );
	if( CFGetTypeID(aDeviceType) != CFStringGetTypeID() )	return( badSlotCount );
	
	if( CFStringCompare( aDeviceType, dacalDC300, 0 ) )		return( dc300SlotCount );
	if( CFStringCompare( aDeviceType, dacalDC016RW, 0 ) )	return( dc016SlotCount );
	if( CFStringCompare( aDeviceType, dacalDC101, 0 ) )		return( dc101SlotCount );
	
	return( badSlotCount );
}

DACALCount	DACALDevicesGetCount( void )
{
	return( gDACALBoxes.boxCount );
}

DACALDeviceRef	DACALDevicesCopyDeviceRefForIndex( DACALCount deviceID, DACALResult* outError )
{
	DACALDeviceRef			outDevice = kDACALNullDevice;
	DACALResult				anyErr;
	
	outDevice = (DACALDeviceRef)DACALCommandCopyUUID( (DACALDeviceRef)deviceID, &anyErr );
	if( anyErr ) outDevice = kDACALNullDevice;
	
	if( outError ) *outError = anyErr;
	return( outDevice );
}

DACALDeviceRef DACALDeviceRetain( DACALDeviceRef inDevice )
{
	DACALDeviceRef	outDevice = inDevice;
		
	if( inDevice > kDACALIllegalDevice )										
	{
		CFUUIDRef	possibleID = (CFUUIDRef)inDevice;
		CFStringRef	possibleName = (CFStringRef)inDevice;
		
		if( CFGetTypeID(possibleID) == CFUUIDGetTypeID() )									// UUID?
			outDevice = (DACALDeviceRef)CFRetain( (CFTypeRef)inDevice );
		
		if( CFGetTypeID(possibleName) == CFStringGetTypeID() )								// Name?
			outDevice = (DACALDeviceRef)CFRetain( (CFTypeRef)inDevice );
	}
	
	return( outDevice );
}

void DACALDeviceRelease( DACALDeviceRef inDevice )
{
	if( inDevice > kDACALIllegalDevice )										
	{
		CFUUIDRef	possibleID = (CFUUIDRef)inDevice;
		CFStringRef	possibleName = (CFStringRef)inDevice;
		
		if( CFGetTypeID(possibleID) == CFUUIDGetTypeID() )									// UUID?
			CFRelease( (CFTypeRef)inDevice );
		
		if( CFGetTypeID(possibleName) == CFStringGetTypeID() )								// Name?
			CFRelease( (CFTypeRef)inDevice );
	}
	
}

CFArrayRef	DACALDevicesCopyAllNames( void )
{
	DACALCount		boxIndex = 0;
	DACALCount		boxCount = DACALDevicesGetCount();	
	CFStringRef*	boxNames;
	CFArrayRef		boxArray;
	
	if( boxCount == 0 ) return( CFArrayCreate( gDACALDefaultCFAllocator, NULL, 0, &kCFTypeArrayCallBacks ) );
	
	boxNames = (CFStringRef*)malloc( sizeof(CFStringRef)*boxCount );
	
	for( boxIndex=0; boxIndex < boxCount; boxIndex++ )
		boxNames[boxIndex] = CFStringCreateCopy(gDACALDefaultCFAllocator, DACAL_BOX_NAME(boxIndex));
	
	boxArray = CFArrayCreate( gDACALDefaultCFAllocator, (const void**)boxNames, boxCount, &kCFTypeArrayCallBacks );

	free( boxNames );
	return( boxArray );
}

DACALResult		DACALDeviceClose( DACALDeviceRef deviceID )
{
    io_service_t			  theDevice;
	IOUSBDeviceInterface245** theInterface;
	
	DACALResult				err;
	DACALCount				indexID = dacalDeviceRefToDeviceIndex( deviceID );
	UInt8					count, thisRef = 0;
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	deviceID = indexID + 1;
	
	theDevice = gDACALBoxes.box[indexID].boxDevice;
	theInterface = gDACALBoxes.box[indexID].boxRef;
	
	err = (*theInterface)->USBDeviceClose(theInterface);
	if (err) {
		if( err != kIOReturnNoDevice ) {
			if( gDACALVerbose ) printf("dacal: Unable to close device: %08x\n", err);
			return( err );
		}
	}
	(void) (*theInterface)->Release(theInterface);
	
	IOObjectRelease( theDevice );
	
	DACALClientNotifyAll( (DACALDeviceRef)DACAL_BOX_UUID(indexID), kDACALCarouselNoticeDeviceClose, (CFDictionaryRef)NULL );
		
	if( DACAL_BOX_NAME(indexID) )	CFRelease( DACAL_BOX_NAME(indexID) );
	if( DACAL_BOX_MODEL(indexID) ) CFRelease( DACAL_BOX_MODEL(indexID) );
	if( DACAL_BOX_UUID(indexID) )	CFRelease( DACAL_BOX_UUID(indexID) );
	if( DACAL_BOX_NOTIFICATION(indexID) )	IOObjectRelease( DACAL_BOX_NOTIFICATION(indexID) );
	
	//gDACALBoxes.boxCount--;
	thisRef = gDACALBoxes.boxCount--;
	DACAL_BOX_DEVICE(indexID)	= 0;
	DACAL_BOX_REF(indexID)		= NULL;
	DACAL_BOX_BUSY(indexID)		= FALSE;
	DACAL_BOX_NAME(indexID)		= NULL;
	DACAL_BOX_MODEL(indexID)	= NULL;
	DACAL_BOX_UUID(indexID)		= NULL;
	DACAL_BOX_NOTIFICATION(indexID)	= (io_object_t)NULL;
	
	if( gDACALDefaultDevice == deviceID ) gDACALDefaultDevice = 1;				// If we just closed the default device, reset it to box 1.
	
	if( thisRef > deviceID )
		for( count = indexID; count <= deviceID; count++ ) {
			gDACALBoxes.box[count].boxDevice= gDACALBoxes.box[count+1].boxDevice;
			gDACALBoxes.box[count].boxRef	= gDACALBoxes.box[count+1].boxRef;
			gDACALBoxes.box[count].isBusy	= gDACALBoxes.box[count+1].isBusy;
			gDACALBoxes.box[count].boxName	= gDACALBoxes.box[count+1].boxName;
			gDACALBoxes.box[count].boxModel	= gDACALBoxes.box[count+1].boxModel;
			gDACALBoxes.box[count].boxUUID	= gDACALBoxes.box[count+1].boxUUID;
			gDACALBoxes.box[count].boxNotification	= gDACALBoxes.box[count+1].boxNotification;		
		}
	
	return( err );
}

void DACALDeviceNotification( void* refCon, io_service_t service, natural_t messageType, void* messageArgument );
void DACALDeviceNotification( void* refCon, io_service_t service, natural_t messageType, void* messageArgument )
{
	DACALDeviceRef	theDevice = (DACALDeviceRef)refCon;
	
	//NSLog(@"Device:%i Message:%i",(int)theDevice, messageType);
	
	switch ( messageType ) {
		case kIOMessageServiceIsTerminated:
			DACALDeviceClose( theDevice );
			break;
		default:
			break;
	}
	
}

DACALDeviceRef	DACALDeviceCreateWithService( io_service_t ioDeviceObj, DACALResult* outErr )
{
	DACALResult					err;
	vm_offset_t					thisRef = 0;
	IOCFPlugInInterface			**ioPlugin;
	IOUSBDeviceInterface245		**deviceIntf = NULL;
	SInt32						score;
	CFUUIDRef					newID;
	CFStringRef					newModel;
//	CFStringRef					newName;
//	CFStringRef					userName;
	DACALDeviceNode				newNode;
//	DACALDeviceRef				originalDefault = DACALDevicesGetDefaultDevice();
//	DACALDeviceRef				currentDefault;
	
	err = IOCreatePlugInInterfaceForService(ioDeviceObj, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &ioPlugin, &score);
	if (err || !ioPlugin) {
		IOObjectRelease( ioDeviceObj );
		if( gDACALVerbose ) printf("dacal: unable to create plugin. ret = %08x, iodev = %p\n", err, ioPlugin);
		if( outErr != NULL ) *outErr = err;
		return( thisRef );
	}
	err = (*ioPlugin)->QueryInterface(ioPlugin, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID), (LPVOID)&deviceIntf);
	IODestroyPlugInInterface(ioPlugin);		// done with this
	ioPlugin = NULL;
	
	if (err || !deviceIntf) {
		if( gDACALVerbose ) printf("dacal: unable to create a device interface. ret = %08x, dev = %p\n", err, ioPlugin);
		if( outErr != NULL ) *outErr = err;
		return( thisRef );
	}
		
	if( gDACALVerbose ) printf("dacal: Found device %p\n", (void*)ioDeviceObj);
		
	err = (*deviceIntf)->USBDeviceOpen(deviceIntf);
	if (err) {
		if( gDACALVerbose ) printf("dacal: Unable to open device: %08x\n", err);
		(void) (*deviceIntf)->Release(deviceIntf);
		if( outErr != NULL ) *outErr = err;
		return( thisRef );
	}
	
	thisRef = gDACALBoxes.boxCount++;
	newNode = thisRef+1;
	
	DACAL_BOX_DEVICE(thisRef)		= ioDeviceObj;
	DACAL_BOX_REF(thisRef)			= deviceIntf;
	DACAL_BOX_BUSY(thisRef)			= FALSE;
	DACAL_BOX_UUID(thisRef)			= NULL;
	DACAL_BOX_MODEL(thisRef)		= NULL;
	DACAL_BOX_LASTSLOT(thisRef)		= 0;
	DACAL_BOX_LASTSLOTTIME(thisRef)	= -1;
//	DACAL_BOX_NODE(thisRef)			= index+1;
	
	newID							= DACALCommandCopyUUID( newNode, NULL );
	newModel						= DACALCommandCopyModel( newNode, NULL );

	if( newID == NULL ) {
		sleep( 5 );

		newID							= DACALCommandCopyUUID( newNode, NULL );
		newModel						= DACALCommandCopyModel( newNode, NULL );
		
		if( newID == NULL ) {
			err = kDACALError;
			if( gDACALVerbose ) printf("dacal: Could Not Identify Device %p\n", (void*)ioDeviceObj);
			if( outErr != NULL ) *outErr = err;
			return( thisRef );
		}
	}
	
	
	err = CarouselEstablishInfoFile( newID );
	if (err) {
		if( gDACALVerbose ) printf("dacal: unable to create a device file. ret = %i, dev = %p\n", err, (void*)ioDeviceObj);
		if( outErr != NULL ) *outErr = err;
		return( thisRef );
	}
	
	err = IOServiceAddInterestNotification( gDACALNotifyPort, ioDeviceObj, kIOGeneralInterest, DACALDeviceNotification, (void*)newID, &(DACAL_BOX_NOTIFICATION(thisRef)) );
	
	DACALClientNotifyAll( (DACALDeviceRef)newID, kDACALCarouselNoticeDeviceOpen, (CFDictionaryRef)NULL );
	
	// Use the default device ID to bootstrap the new node
	// Can't use the API because it checks for a valid id!
//	gDACALDefaultDevice = thisRef + 1;
	
//	DACAL_BOX_NODE(thisRef)			= thisRef + 1;
//	newID = DACALCommandCopyUUID( thisRef+1, NULL );
//	newModel = DACALCommandCopyModel( thisRef+1, NULL );
//	DACAL_BOX_NAME(thisRef)			= CopyUSBProductData( thisRef, &newNode );

//	newID							= DACALCommandCopyUUID( kDACALDefaultDevice, NULL );
//	newModel						= DACALCommandCopyModel( kDACALDefaultDevice, NULL );
//	DACAL_BOX_NAME(thisRef)			= CopyUSBProductData( (DACALDeviceRef)newID, &newNode );

	// If the node doesn't exist assign a new one.
//	if( newNode == 0 ) newNode = thisRef + 1;
	
//	NSLog(@"Opened node: %i", newNode);
	
/*	if( DACAL_BOX_NAME(thisRef)	== NULL )
	{
		userName = CSCopyUserName(TRUE);
		newName = CFStringCreateWithFormat( NULL, NULL, CFSTR("%@'s Carousel %i"), userName, newNode );
		//SaveUSBProductData( (DACALDeviceRef)newID, newName, newNode );
		SaveUSBProductData( kDACALDefaultDevice, newName, newNode );
		DACAL_BOX_NAME(thisRef) = newName;
		CFRelease( userName );
	}
		
	if( newID ) CFRelease( newID );
	if( newModel) CFRelease( newModel );
*/	
//	DACALDevicesSetDefaultDevice( originalDefault );
	
	if( outErr != NULL ) *outErr = err;
	return( thisRef );
}

void			DACALDevicesAdded( void* refCon, io_iterator_t iterator );
void			DACALDevicesAdded( void* refCon, io_iterator_t iterator )
{
    io_service_t		aCarousel;

	while( (aCarousel = IOIteratorNext(iterator)) )
		DACALDeviceCreateWithService( aCarousel, NULL );
}


DACALResult		DACALDevicesFinalize( void )
{
	DACALResult		closeErr, outErr = 0;
	DACALCount		index, count = gDACALBoxes.boxCount;
	
	if( count == 0 ) return( outErr );
	
	for( index=count; index>0; index-- ) {
		closeErr = DACALDeviceClose( (DACALDeviceRef)DACAL_BOX_UUID(index-1) );
		if( outErr == 0 ) outErr = closeErr;
	}
	
	return( outErr );
}

DACALResult		DACALDevicesInitialize( void )
{
	DACALResult				err;
    CFMutableDictionaryRef 	matchingDictionary = 0;		
    CFNumberRef				numberRef;
	
	mach_port_t				masterPort = 0;				// requires <mach/mach.h>

//    io_iterator_t			devIter = 0;
//    io_service_t			ioDeviceObj;
	
/*
	FSRef					topFolder;
	OSErr					ffErr;
	
	gDACALBoxes.boxCount = 0;							// start fresh
	
	DACALDevicesSetCFAllocator( kCFAllocatorDefault );	// initialize with default allocator
	
	{
		
		ffErr = FSFindFolder( kUserDomain, kDomainLibraryFolderType, FALSE, &topFolder );
		if( ffErr ) fprintf( stderr,"No Local Library?");
		
		CFURLRef	sysURL = CFURLCreateFromFSRef( kCFAllocatorDefault, &topFolder );
		CFURLRef	padURL = CFURLCreateCopyAppendingPathComponent( kCFAllocatorDefault, sysURL, DACAL_CAROUSEL_FOLDERNAME_CFSTRING, TRUE );
		FSRef		padFS;
		FSCatalogInfo			permCatInfo;
		FSPermissionInfo		*permInfo = (FSPermissionInfo*)&(permCatInfo.permissions);
	
		Boolean		foundPAD = CFURLGetFSRef( padURL, &padFS );
		CFIndex		theUniCount = CFStringGetLength( DACAL_CAROUSEL_FOLDERNAME_CFSTRING );
		UniChar		theUniName[1024];
		
		if( foundPAD == FALSE ) {
			permInfo->mode = 0755;			// drwxr-xr-x
			CFStringGetCharacters( DACAL_CAROUSEL_FOLDERNAME_CFSTRING, CFRangeMake(0, theUniCount), theUniName );

			ffErr = FSCreateDirectoryUnicode( &topFolder, theUniCount, (const UniChar*)theUniName, kFSCatInfoPermissions, &permCatInfo, &padFS, NULL, NULL );
			if( ffErr ) fprintf( stderr, "FSCreateDirectoryUnicode: %i\n", ffErr );
		}
		
		if( padURL != NULL ) CFRelease( padURL );
		if( sysURL != NULL ) CFRelease( sysURL );
	}
	
	
	
	
	// setup a system folder descriptor to make finding the Carousel folder easy
	AddFolderDescriptor( kDACALCarouselsFolderType, kFolderInLocalOrRemoteUserFolder, 
							kRelativeFolder, kDomainLibraryFolderType, 0, 0, 
							DACAL_CAROUSEL_FOLDERNAME_PSTRING, TRUE );

	
	ffErr = FSFindFolder( kOnAppropriateDisk, kDACALCarouselsFolderType, TRUE, &topFolder );
	
 */
 
														// Find USB Interface
    err = IOMasterPort(MACH_PORT_NULL, &masterPort);				
    if (err) {
        if( gDACALVerbose ) printf("dacal: could not create master port, err = %08x\n", err);
        return err;
    }
																	// Looking for USBD device
    matchingDictionary = IOServiceMatching(kIOUSBDeviceClassName);	// requires <IOKit/usb/IOUSBLib.h>
																	// Specifiy vendor, product and revision
    if (!matchingDictionary) {
        if( gDACALVerbose ) printf("dacal: could not create matching dictionary\n");
        return kIOReturnNoDevice;
    }
	
	// Setup vendorID
		numberRef = CFNumberCreate(gDACALDefaultCFAllocator, kCFNumberSInt32Type, &kDACALVendorID);
		if (!numberRef) {
			if( gDACALVerbose ) printf("dacal: could not create CFNumberRef for vendor\n");
			return kIOReturnNoMemory;
		}
		CFDictionaryAddValue(matchingDictionary, CFSTR(kUSBVendorID), numberRef);
		CFRelease(numberRef);
		numberRef = 0;
	
	// Setup productID
		numberRef = CFNumberCreate(gDACALDefaultCFAllocator, kCFNumberSInt32Type, &kDACALProductID);
		if (!numberRef) {
			if( gDACALVerbose ) printf("dacal: could not create CFNumberRef for product\n");
			return kIOReturnNoMemory;
		}
		CFDictionaryAddValue(matchingDictionary, CFSTR(kUSBProductID), numberRef);
		CFRelease(numberRef);
		numberRef = 0;
	
	// Setup bRelease
	//	numberRef = CFNumberCreate(gDACALDefaultCFAllocator, kCFNumberSInt32Type, &kDACALReleaseID);
	//	if (!numberRef) {
	//		if( gDACALVerbose ) printf("dacal: could not create CFNumberRef for product\n");
	//		return kIOReturnNoMemory;
	//	}
	//	CFDictionaryAddValue(matchingDictionary, CFSTR(kUSBDeviceReleaseNumber), numberRef);
	//	CFRelease(numberRef);
	//	numberRef = 0;
    
   // err = IOServiceGetMatchingServices(masterPort, matchingDictionary, &devIter);
   // matchingDictionary = 0;			// this was consumed by the above call
    
	gDACALNotifyPort = IONotificationPortCreate( masterPort );
	gDACALRunLoopSource = IONotificationPortGetRunLoopSource( gDACALNotifyPort );
	
	CFRunLoopAddSource( CFRunLoopGetCurrent(), gDACALRunLoopSource, kCFRunLoopDefaultMode);
	
    //while ( (ioDeviceObj = IOIteratorNext(devIter)) )
	//	DACALDeviceCreateWithService( ioDeviceObj, NULL );
	
	err = IOServiceAddMatchingNotification( gDACALNotifyPort, kIOFirstMatchNotification, matchingDictionary, DACALDevicesAdded, NULL, &gDACALAddedIter);
	
	DACALDevicesAdded( NULL, gDACALAddedIter );
	
    //IOObjectRelease(devIter);
    //devIter = 0;
    
    mach_port_deallocate(mach_task_self(), masterPort);			// Don't do this in the future so we can get hot plugs.
	masterPort = 0;
	
    return kIOReturnSuccess;	
}

DACALClientRef	DACALClientGetIndexForID( CFStringRef aClient );
DACALClientRef	DACALClientGetIndexForID( CFStringRef aClient )
{
	DACALClientRef	index, count = (DACALClientRef)gDACALClients.clientCount;
	for( index=1; index <= count; index++ )
		if( CFEqual( DACAL_CLIENT_IDENTIFIER(index), aClient ) ) return index;

	return 0;
}


void			DACALClientNotify( CFStringRef noticeClient, DACALDeviceRef noticeDevice, CFStringRef noticeMessage, CFDictionaryRef noticeData );
void			DACALClientNotify( CFStringRef noticeClient, DACALDeviceRef noticeDevice, CFStringRef noticeMessage, CFDictionaryRef noticeData )
{
	DACALClientRef							clientIndex = DACALClientGetIndexForID( noticeClient );
	DACALClientNotificationCallback*		userCallback = DACAL_CLIENT_CALLBACK(clientIndex);
	
	if( gDACALVerbose ) NSLog( @"DACALClientNotify: Device: %i Message: %@", (int)noticeDevice, noticeMessage );

	if( userCallback != NULL ) userCallback( DACAL_CLIENT_USERDATA(clientIndex), noticeDevice, noticeMessage, noticeData );
}

void			DACALClientNotifyAll( DACALDeviceRef noticeDevice, CFStringRef	noticeMessage, CFDictionaryRef	noticeData )
{
	DACALClientRef	index, count = (DACALClientRef)gDACALClients.clientCount;
	for( index=1; index <= count; index++ )
		DACALClientNotify( DACAL_CLIENT_IDENTIFIER(index), noticeDevice, noticeMessage, noticeData );
}


DACALResult		DACALClientCreate( CFAllocatorRef useAllocator, CFStringRef clientID, void* useDataRef, void* useCallback )
{
	DACALClientRef	ourClientRef = gDACALNextClientID++;
	DACALResult		outError = kDACALError;
	
	if( ourClientRef > DACAL_MAXCLIENT_COUNT ) {
		ourClientRef = 0;
		goto BAIL;
	}
	
	if( clientID ) CFRetain( clientID );
	if( useAllocator ) CFRetain( useAllocator );
	
	DACAL_CLIENT_IDENTIFIER(ourClientRef) = clientID;
	DACAL_CLIENT_CALLBACK(ourClientRef) = useCallback;
	DACAL_CLIENT_USERDATA(ourClientRef) = useDataRef;
	DACAL_CLIENT_ALLOCATOR(ourClientRef) = useAllocator;
	
	gDACALClients.clientCount = ourClientRef;
	outError = kDACALOK;
	
	if( ourClientRef == 1 )
	{
		FSRef					topFolder;
		OSErr					ffErr;

		gDACALBoxes.boxCount = 0;							// start fresh
		
		DACALDevicesSetCFAllocator( useAllocator );			// initialize with default allocator
		
		{													// this is a workaround because AddFolderDescriptor
															// creates a folder with silly permissions
			
			ffErr = FSFindFolder( kUserDomain, kDomainLibraryFolderType, FALSE, &topFolder );
			if( ffErr ) fprintf( stderr,"No Local Library?");
			
			CFURLRef	sysURL = CFURLCreateFromFSRef( useAllocator, &topFolder );
			CFURLRef	padURL = CFURLCreateCopyAppendingPathComponent( useAllocator, sysURL, DACAL_CAROUSEL_FOLDERNAME_CFSTRING, TRUE );
			FSRef		padFS;
			FSCatalogInfo			permCatInfo;
			FSPermissionInfo		*permInfo = (FSPermissionInfo*)&(permCatInfo.permissions);
			
			Boolean		foundPAD = CFURLGetFSRef( padURL, &padFS );
			CFIndex		theUniCount = CFStringGetLength( DACAL_CAROUSEL_FOLDERNAME_CFSTRING );
			UniChar		theUniName[1024];
			
			if( foundPAD == FALSE ) {
				permInfo->mode = 0755;						// drwxr-xr-x
				CFStringGetCharacters( DACAL_CAROUSEL_FOLDERNAME_CFSTRING, CFRangeMake(0, theUniCount), theUniName );
				
				ffErr = FSCreateDirectoryUnicode( &topFolder, theUniCount, (const UniChar*)theUniName, kFSCatInfoPermissions, &permCatInfo, &padFS, NULL, NULL );
				if( ffErr ) fprintf( stderr, "FSCreateDirectoryUnicode: %i\n", ffErr );
			}
			
			if( padURL != NULL ) CFRelease( padURL );
			if( sysURL != NULL ) CFRelease( sysURL );	
		}
		
		// setup a system folder descriptor to make finding the Carousel folder easy
		AddFolderDescriptor( kDACALCarouselsFolderType, kFolderInLocalOrRemoteUserFolder, 
							kRelativeFolder, kDomainLibraryFolderType, 0, 0, 
							DACAL_CAROUSEL_FOLDERNAME_PSTRING, TRUE );
		
		ffErr = FSFindFolder( kOnAppropriateDisk, kDACALCarouselsFolderType, TRUE, &topFolder );
	}
	
	
BAIL:	
	return( outError );
}

void		DACALClientRelease( CFStringRef clientID )
{
	DACALClientRef		clientIndex = DACALClientGetIndexForID( clientID );
	DACALClientRef		clientCount	= gDACALClients.clientCount;
	DACALClientRef		index;
	
	if( clientIndex ) {
		if( DACAL_CLIENT_IDENTIFIER(clientIndex) ) CFRelease( DACAL_CLIENT_IDENTIFIER(clientIndex) );
		if( DACAL_CLIENT_ALLOCATOR(clientIndex) )  CFRelease( DACAL_CLIENT_ALLOCATOR(clientIndex) );
		
		DACAL_CLIENT_IDENTIFIER(clientIndex)	= NULL;
		DACAL_CLIENT_ALLOCATOR(clientIndex)		= NULL;
		DACAL_CLIENT_USERDATA(clientIndex)		= NULL;
		DACAL_CLIENT_CALLBACK(clientIndex)		= NULL;
		
		if( clientIndex < clientCount ) {
			for( index=clientIndex; index < clientCount ; index++ ) {
				DACAL_CLIENT_IDENTIFIER(index)	= DACAL_CLIENT_IDENTIFIER(index+1);			
				DACAL_CLIENT_ALLOCATOR(index)	= DACAL_CLIENT_ALLOCATOR(index+1); 			
				DACAL_CLIENT_USERDATA(index)	= DACAL_CLIENT_USERDATA(index+1);			
				DACAL_CLIENT_CALLBACK(index)	= DACAL_CLIENT_CALLBACK(index+1);			
			}
		}
		
		clientCount--;
		gDACALClients.clientCount = clientCount;
	}
	
	if( clientCount == 0 ) DACALDevicesFinalize();
}

