/*
 *  dacallib.c
 *  PMTB
 *
 *  Created by Dave Carlton on 05/20/08.
 *  Copyright 2008 Polymicro Systems. All rights reserved.
 *
 */

#include "dacallib.h"
#define DACALDEBUG "Debug"

//#define __DCDEBUG__				

#define DACAL_MAXDEVICE_COUNT	64*4							// 64 boxes + 64 hubs = 128 devices/per port for possible 4 ports.  Total 256 devices.
#define	DACAL_SHORT_SLEEP		sleep(1);
#define	DACAL_RESET_SLEEP		sleep(5);

#define DACAL_BOX_BUSY(x)		gDACALBoxes.box[x].isBusy
#define DACAL_BOX_NAME(x)		gDACALBoxes.box[x].boxName
#define DACAL_BOX_MODEL(x)		gDACALBoxes.box[x].boxModel
#define DACAL_BOX_UUID(x)		gDACALBoxes.box[x].boxUUID
#define DACAL_BOX_REF(x)		gDACALBoxes.box[x].boxRef
#define DACAL_BOX_DEVICE(x)		gDACALBoxes.box[x].boxDevice

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
	CFStringRef						boxName;
	CFStringRef						boxModel;
	CFUUIDRef						boxUUID;
	IOUSBDeviceInterface245**		boxRef;
	io_service_t					boxDevice;
} DACALBox, *DACALBoxRef;

typedef struct {
	DACALCount						boxCount;
	DACALBox						box[DACAL_MAXDEVICE_COUNT];		// Change the constant below if necesary
} DACALArray;

typedef struct {
	char	stringSize;	
	char	stringCode;
	UniChar uniString[128];
} dacalString;

CFStringRef dacalACK = CFSTR("ACK");
CFStringRef dacalBUSY = CFSTR("Busy");
CFStringRef dacalERROR = CFSTR("ERROR");
CFStringRef dacalNUMBER = CFSTR("numbers");
CFStringRef dacalNAN = CFSTR("1234567");
CFStringRef dacalDC300 = CFSTR("1234567");
CFStringRef dacalDC016RW = CFSTR("DC016RW");
CFStringRef DACALDC300CFName = CFSTR("DC-300");
CFStringRef DACALDC016RWCFName = CFSTR("DC-016RW");

//CFStringRef		kDACALNameProperty = CFSTR("DACAL Device Name");
CFStringRef		kDACALPreferencesID = CFSTR("com.polymicrosystems.pmtblib.devicenames");

const DACALDeviceRef	kDACALDefaultDevice = 0;
const DACALDeviceRef	kDACALIllegalDevice = DACAL_MAXDEVICE_COUNT+1;
const DACALDeviceRef	kDACALDevicesMaxCount = DACAL_MAXDEVICE_COUNT;

#ifdef __DCDEBUG__
Boolean			gDACALVerbose = TRUE;
#else
Boolean			gDACALVerbose = FALSE;
#endif

CFAllocatorRef	gDACALDefaultCFAllocator = NULL;
mach_port_t 	masterPort = 0;				// requires <mach/mach.h>
DACALDeviceRef	gDACALDefaultDevice = 1;
DACALArray		gDACALBoxes;

const DACALResult		kDACALOK = kIOReturnSuccess;
const DACALResult		kDACALBusy = kIOReturnBusy;
const DACALResult		kDACALError = kIOReturnError;

// Private Functions

CFStringRef		CopyUSBProductName(DACALDeviceRef indexID);
DACALResult		SaveUSBProductName(DACALDeviceRef deviceID, CFStringRef inName);
CFStringRef		CFStringCreateFromDacalString( dacalString* deviceBlock );
char*			CFStringCreateCString( CFStringRef theString, CFStringEncoding theEncoding );
IOReturn		dacalGetDescriptor(IOUSBDeviceInterface245 **deviceIntf, UInt16 index, UInt8 descType, UInt8 descIndex, void *buf, UInt16 len, UInt16 *result);
IOReturn		dacalDoRequest(IOUSBDeviceInterface245** indeviceIntf, dacalCmd cmd, dacalString* outResult);
DACALCount		dacalDeviceRefToDeviceIndex( DACALDeviceRef deviceID );

DACALResult		DACALCommandRequest( DACALDeviceRef deviceID, DACALCommand deviceCommand, dacalString* outResult );
DACALResult		DACALCommandRequestNoResult( DACALDeviceRef deviceID, DACALCommand deviceCommand );
CFStringRef		DACALCommandRequestCFString( DACALDeviceRef deviceID, DACALCommand deviceCommand, DACALResult* outError );

DACALDeviceRef	DACALDeviceCreateWithService( io_service_t ioDeviceObj, DACALResult* outError );
DACALResult		DACALDeviceClose( DACALDeviceRef deviceID );


CFStringRef		CopyUSBProductName(DACALDeviceRef indexID)			//note this is really a indexID!
{
	CFStringRef		outName = NULL;
	CFStringRef		uuidName = CFUUIDCreateString( gDACALDefaultCFAllocator, DACAL_BOX_UUID(indexID) );
	CFStringRef		copyName = NULL;
	
	if( indexID == kDACALIllegalDevice ) return( outName );

	outName = (CFStringRef)CFPreferencesCopyValue( uuidName, kDACALPreferencesID, kCFPreferencesAnyUser, kCFPreferencesCurrentHost );
	if( uuidName ) CFRelease( uuidName );
	if( outName ) {
		copyName = CFStringCreateCopy(gDACALDefaultCFAllocator, outName);
		CFRelease( outName );
		return( copyName );
	}

	return( outName );
}

DACALResult		SaveUSBProductName(DACALDeviceRef deviceID, CFStringRef inName)
{
	DACALDeviceRef	indexID = dacalDeviceRefToDeviceIndex( deviceID );
	CFStringRef		uuidName = CFUUIDCreateString( gDACALDefaultCFAllocator, DACAL_BOX_UUID(indexID) );
	CFStringRef		copyName = NULL;
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );

	if( inName ) copyName = CFStringCreateCopy(gDACALDefaultCFAllocator, inName);

	CFPreferencesSetValue( uuidName, copyName, kDACALPreferencesID, kCFPreferencesAnyUser, kCFPreferencesCurrentHost );
	CFPreferencesAppSynchronize( kDACALPreferencesID );

	if( copyName ) CFRelease( copyName );
	if( uuidName ) CFRelease( uuidName );	
	return( 0 );
}

CFStringRef		CFStringCreateFromDacalString( dacalString* deviceBlock ) {
	return( CFStringCreateWithCharacters( gDACALDefaultCFAllocator, (UniChar*)&deviceBlock->uniString, deviceBlock->stringSize));
}	

char*		CFStringCreateCString( CFStringRef theString, CFStringEncoding theEncoding )
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
#ifdef __DCDEBUG__			
		CFLog( NULL, NULL, CFSTR("Device Status: %@\n"), descriptorStr );		
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
	if( gDACALBoxes.boxCount == 0 ) return( kDACALIllegalDevice );				// No Boxes
	if( deviceID == kDACALDefaultDevice ) return( gDACALDefaultDevice - 1 );	// Default Box
	if( (1 <= deviceID) & (deviceID <= gDACALBoxes.boxCount) ) return ( deviceID - 1 );		// Actual Device
	
	if( deviceID > kDACALIllegalDevice )										// UUID?
	{
		CFUUIDRef	possibleID = (CFUUIDRef)deviceID;
		SInt8		checkIndex = 0;
		
		if( CFGetTypeID(possibleID) == CFUUIDGetTypeID() )
			for( checkIndex=0; checkIndex < gDACALBoxes.boxCount; checkIndex++ )
				if( DACAL_BOX_UUID(checkIndex) )
					if( CFEqual( DACAL_BOX_UUID(checkIndex), possibleID ) ) return( checkIndex );
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
	
	bytes = (CFUUIDBytes*)ourResult.uniString;	
	deviceUUID = CFUUIDCreateFromUUIDBytes(gDACALDefaultCFAllocator, *bytes);
	if( deviceUUID ) DACAL_BOX_UUID(indexID) = deviceUUID;

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

DACALResult		DACALCommandMoveToSlot( DACALDeviceRef deviceID, DACALSlotNum newSlot )
{
	DACALResult		theErr;
	dacalString		slotBuffer;
	UInt16			result;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	
	theErr = DACALCommandCloseDoor( deviceID );
	if( theErr ) return theErr;
	DACAL_SHORT_SLEEP
	
	theErr = DACALCommandRequestNoResult( deviceID, cmdMoveToSlot );	
	DACAL_SHORT_SLEEP
	theErr = dacalGetDescriptor(gDACALBoxes.box[indexID].boxRef, 0x0409, kUSBStringDesc, newSlot, &slotBuffer, sizeof(slotBuffer), &result);
	DACAL_SHORT_SLEEP
	
	return( theErr );
}

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
	
	if( deviceName ) DACAL_BOX_NAME(indexID) = CFRetain( deviceName );
	else DACAL_BOX_NAME(indexID) = deviceName;
	
	return SaveUSBProductName( indexID, deviceName );
}

DACALSlotNum		DACALCommandGetSlotCount( DACALDeviceRef deviceID )
{
	DACALSlotNum	badSlotCount = 0;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) return( badSlotCount );
	if( DACAL_BOX_MODEL(indexID) == NULL ) return( badSlotCount );
	
	return( DACALDevicesGetSlotCount(DACAL_BOX_MODEL(indexID)) );
}

DACALResult		DACALSlotCreateIndex( DACALDeviceRef deviceID, DACALSlotNum slotNum, CFStringRef slotTitle, DACALCount indexLevel, CFURLRef sourcePath )
{
	DACALResult		outResult;
	CFStringRef		theCommand = CFSTR("carousel");
	CFURLRef		commandURL = CFBundleCopyResourceURL( CFBundleGetMainBundle(), theCommand, CFSTR("sh"), NULL );
	CFStringRef		doCFCommand;
	CFStringRef		sourceType = CFSTR(" -n");
	UTF8Char*		sourceFilePath;
	Boolean			goodPath;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	char*			doCommand;
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	
	if( sourcePath != NULL ) {
		CFShow( sourcePath );
		sourceFilePath = (UTF8Char*)calloc(1,4096);
		goodPath = CFURLGetFileSystemRepresentation( sourcePath, TRUE, sourceFilePath, 4096 );
		sourceType = CFStringCreateWithFormat( gDACALDefaultCFAllocator, NULL, CFSTR(" -d \"%s\""), sourceFilePath );
	}
	
	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL,
											CFSTR("\"%@\" -x -c %i -s %i -t \"%@\" -l %i%@"), 
											commandURL, indexID+1, slotNum, slotTitle, indexLevel, sourceType );
	if( doCFCommand == NULL ) return( paramErr );

	doCommand = CFStringCreateCString( doCFCommand, kCFStringEncodingUTF8 );	
	if( doCommand == NULL ) return( paramErr );

	outResult = system( doCommand );

	CFRelease( doCFCommand );
	free( doCommand );
	return( outResult );
}

DACALResult		DACALSlotDeleteIndex( DACALDeviceRef deviceID, DACALSlotNum slotNum )
{
	DACALResult		outResult;
	CFStringRef		theCommand = CFSTR("carousel");
	CFURLRef		commandURL = CFBundleCopyResourceURL( CFBundleGetMainBundle(), theCommand, CFSTR("sh"), NULL );
	CFStringRef		doCFCommand;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	char*			doCommand;
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	
	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL,
											CFSTR("\"%@\" -c %i -s %i -k"), 
											commandURL, indexID+1, slotNum );
	if( doCFCommand == NULL ) return( paramErr );

	doCommand = CFStringCreateCString( doCFCommand, kCFStringEncodingUTF8 );	
	if( doCommand == NULL ) return( paramErr );

	outResult = system( doCommand );

	CFRelease( doCFCommand );
	free( doCommand );
	return( outResult );
}

CFStringRef		DACALSlotCopyTitle( DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult* outError )
{
	DACALResult		outResult;
	CFStringRef		outTitle = NULL;
	CFStringRef		theCommand = CFSTR("carousel");
	CFURLRef		commandURL = CFBundleCopyResourceURL( CFBundleGetMainBundle(), theCommand, CFSTR("sh"), NULL );
	CFStringRef		doCFCommand;
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	char*			doCommand = NULL;
	char*			utf8Name = NULL;
	FILE*			pipe;
	
	
	if( indexID == kDACALIllegalDevice ) {
		if( outError ) *outError = kIOReturnNoDevice;
		return( outTitle );
	}
	
	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL,
											CFSTR("\"%@\" -c %i -s %i -w"), 
											commandURL, indexID+1, slotNum );
	if( doCFCommand == NULL ) {
		outResult = paramErr;
		goto BAIL;
	}

	doCommand = CFStringCreateCString( doCFCommand, kCFStringEncodingUTF8 );	
	if( doCommand == NULL ) {
		outResult = paramErr;
		goto BAIL;
	}

	utf8Name = (char*)calloc(1, 1024);
	if( doCommand == NULL ) {
		outResult = paramErr;
		goto BAIL;
	}

	pipe = popen( doCommand, "r" );
	if ( pipe )
	{
		fread( utf8Name, 1, 1024, pipe ) ;
		pclose( pipe );
	}
	
	if( strlen(utf8Name) > 2 ) {
		utf8Name[strlen(utf8Name)-1] = 0;
		outTitle = CFStringCreateWithCString( gDACALDefaultCFAllocator, utf8Name, kCFStringEncodingUTF8 );
		outResult = noErr;
	} else {
		outResult = paramErr;
		goto BAIL;
	}
	
	if( CFStringCompare( outTitle, CFSTR("Carousel.app"), 0 ) == 0 ) {
		CFRelease( outTitle );
		outTitle = (CFStringRef)NULL;
	}

BAIL:
	if( outError ) *outError = outResult;
	if( utf8Name ) free( utf8Name );
	if( doCFCommand ) CFRelease( doCFCommand );
	if( doCommand ) free( doCommand );
	return( outTitle );
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
	DACALSlotNum	dc300SlotCount = 150;
	DACALSlotNum	dc016SlotCount = 100;

	if( aDeviceType == NULL ) return( badSlotCount );
	if( CFGetTypeID(aDeviceType) != CFStringGetTypeID() )	return( badSlotCount );
	
	if( CFStringCompare( aDeviceType, dacalDC300, 0 ) )		return( dc300SlotCount );
	if( CFStringCompare( aDeviceType, dacalDC016RW, 0 ) )	return( dc016SlotCount );
	
	return( badSlotCount );
}

DACALCount	DACALDevicesGetCount( void )
{
	return( gDACALBoxes.boxCount );
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
		if( gDACALVerbose ) printf("dacal: Unable to close device: %08x\n", err);
		return( err );
	}
	(void) (*theInterface)->Release(theInterface);
	
	IOObjectRelease( theDevice );
		
	if( DACAL_BOX_NAME(indexID) )	CFRelease( DACAL_BOX_NAME(indexID) );
	if( DACAL_BOX_MODEL(indexID) ) CFRelease( DACAL_BOX_MODEL(indexID) );
	if( DACAL_BOX_UUID(indexID) )	CFRelease( DACAL_BOX_UUID(indexID) );
	
	thisRef = gDACALBoxes.boxCount--;
	DACAL_BOX_DEVICE(indexID)	= 0;
	DACAL_BOX_REF(indexID)		= NULL;
	DACAL_BOX_BUSY(indexID)		= FALSE;
	DACAL_BOX_NAME(indexID)		= NULL;
	DACAL_BOX_MODEL(indexID)	= NULL;
	DACAL_BOX_UUID(indexID)		= NULL;
	
	if( gDACALDefaultDevice == deviceID ) gDACALDefaultDevice = 1;				// If we just closed the default device, reset it to box 1.
	
	if( thisRef > deviceID )
		for( count = deviceID; count < thisRef; count++ ) {
			gDACALBoxes.box[count].boxDevice= gDACALBoxes.box[count+1].boxDevice;
			gDACALBoxes.box[count].boxRef	= gDACALBoxes.box[count+1].boxRef;
			gDACALBoxes.box[count].isBusy	= gDACALBoxes.box[count+1].isBusy;
			gDACALBoxes.box[count].boxName	= gDACALBoxes.box[count+1].boxName;
			gDACALBoxes.box[count].boxModel	= gDACALBoxes.box[count+1].boxModel;
			gDACALBoxes.box[count].boxUUID	= gDACALBoxes.box[count+1].boxUUID;
		}
	
	return( err );
}

DACALDeviceRef	DACALDeviceCreateWithService( io_service_t ioDeviceObj, DACALResult* outErr )
{
	DACALResult					err;
	UInt8						thisRef = 0;
	IOCFPlugInInterface			**ioPlugin;
	IOUSBDeviceInterface245		**deviceIntf = NULL;
	SInt32						score;
	CFUUIDRef					newID;
	CFStringRef					newModel;
	
	err = IOCreatePlugInInterfaceForService(ioDeviceObj, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &ioPlugin, &score);
	if( outErr != NULL ) *outErr = err;
	if (err || !ioPlugin) {
		IOObjectRelease( ioDeviceObj );
		if( gDACALVerbose ) printf("dacal: unable to create plugin. ret = %08x, iodev = %p\n", err, ioPlugin);
		return( thisRef );
	}
	err = (*ioPlugin)->QueryInterface(ioPlugin, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID), (LPVOID)&deviceIntf);
	IODestroyPlugInInterface(ioPlugin);		// done with this
	ioPlugin = NULL;
	
	if( outErr != NULL ) *outErr = err;
	if (err || !deviceIntf) {
		if( gDACALVerbose ) printf("dacal: unable to create a device interface. ret = %08x, dev = %p\n", err, ioPlugin);
		return( thisRef );
	}
		
	if( gDACALVerbose ) printf("dacal: Found device %p\n", (void*)ioDeviceObj);
		
	err = (*deviceIntf)->USBDeviceOpen(deviceIntf);
	if( outErr != NULL ) *outErr = err;
	if (err) {
		if( gDACALVerbose ) printf("dacal: Unable to open device: %08x\n", err);
		(void) (*deviceIntf)->Release(deviceIntf);
		return( thisRef );
	}
	
	thisRef = gDACALBoxes.boxCount++;
	DACAL_BOX_DEVICE(thisRef) = ioDeviceObj;
	DACAL_BOX_REF(thisRef) = deviceIntf;
	DACAL_BOX_BUSY(thisRef) = FALSE;
	DACAL_BOX_UUID(thisRef) = NULL;
	DACAL_BOX_MODEL(thisRef) = NULL;
	newID = DACALCommandCopyUUID( thisRef+1, NULL );
	newModel = DACALCommandCopyModel( thisRef+1, NULL );
	DACAL_BOX_NAME(thisRef) = CopyUSBProductName( thisRef );
		
	if( newID ) CFRelease( newID );
	if( newModel) CFRelease( newModel );
	
	return( thisRef );
}

DACALResult		DACALDevicesFinalize( void )
{
	DACALResult		closeErr, outErr = 0;
	DACALCount		index, count = gDACALBoxes.boxCount;
	
	if( count == 0 ) return( outErr );
	
	for( index=count; index>0; index-- ) {
		closeErr = DACALDeviceClose( index );
		if( outErr == 0 ) outErr = closeErr;
	}
	
	return( outErr );
}

DACALResult		DACALDevicesInitialize( void )
{
	DACALResult				err;
    CFMutableDictionaryRef 	matchingDictionary = 0;		
    CFNumberRef				numberRef;
    io_iterator_t			devIter = 0;
    io_service_t			ioDeviceObj;
	
	gDACALBoxes.boxCount = 0;							// start fresh
	
	DACALDevicesSetCFAllocator( kCFAllocatorDefault );	// initialize with default allocator
	
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
		numberRef = CFNumberCreate(gDACALDefaultCFAllocator, kCFNumberSInt32Type, &kDACALReleaseID);
		if (!numberRef) {
			if( gDACALVerbose ) printf("dacal: could not create CFNumberRef for product\n");
			return kIOReturnNoMemory;
		}
		CFDictionaryAddValue(matchingDictionary, CFSTR(kUSBDeviceReleaseNumber), numberRef);
		CFRelease(numberRef);
		numberRef = 0;
    
    err = IOServiceGetMatchingServices(masterPort, matchingDictionary, &devIter);
    matchingDictionary = 0;			// this was consumed by the above call
    
    while ( (ioDeviceObj = IOIteratorNext(devIter)) )
		DACALDeviceCreateWithService( ioDeviceObj, NULL );
	
    IOObjectRelease(devIter);
    devIter = 0;
    
    mach_port_deallocate(mach_task_self(), masterPort);			// Don't do this in the future so we can get hot plugs.
	
    return kIOReturnSuccess;	
}

