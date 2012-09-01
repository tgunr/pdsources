/*
 *  dacallib.m
 *  PMTB
 *
 *  Created by Dave Carlton on 05/20/08.
 *  Copyright 2008 Polymicro Systems. All rights reserved.
 *
 */

#import "pad.h"
#import <DACAL/pmsDACALUtility.h>

#define __DCDEBUG                                                // define this in your pch to go verbose debug

// Interface Level

const SInt32 kDACALVendorID       = 0x04b4;
const SInt32 kDACALDC300ProductID = 0x5a9b;
const SInt32 kDACALDC016ProductID = 0x4611;
const SInt32 kDACALProductID      = 0x5a9b;
const SInt32 kDACALReleaseID      = 0x0100;

CFStringRef dacalACK         = CFSTR("ACK");
CFStringRef dacalBUSY        = CFSTR("Busy");
CFStringRef dacalERROR       = CFSTR("ERROR");
CFStringRef dacalNUMBER      = CFSTR("numbers");
CFStringRef dacalNAN         = CFSTR("1234567");
CFStringRef dacalDC101       = CFSTR("DC101");
CFStringRef dacalDC300       = CFSTR("1234567");
CFStringRef dacalDC016RW     = CFSTR("DC016RW");
CFStringRef DACALDC101CFName = CFSTR("DC-101");
CFStringRef DACALDC300CFName = CFSTR("DC-300");
CFStringRef DACALDC016CFName = CFSTR("DC-016RW");

//CFStringRef		kDACALNameProperty = CFSTR("DACAL Device Name");
CFStringRef kDACALPreferencesID                = CFSTR("com.polymicrosystems.carousellib.devicenames");
CFStringRef kDACALCarouselDocumentExtension    = CFSTR("carousel");
CFStringRef kDACALCarouselDocumentDotExtension = CFSTR(".carousel");
CFStringRef kDACALCarouselDocumentInfoFile     = CFSTR("carousel.plist");

CFStringRef kDACALCarouselDocumentDisplayNameFormat = CFSTR("%@'s Carousel %i");
CFStringRef kDACALCarouselDocumentInfoKeyName       = CFSTR("Name");
CFStringRef kDACALCarouselDocumentInfoKeyUUID       = CFSTR("UUID");
//CFStringRef			kDACALCarouselDocumentInfoKeyNode			=CFSTR("Node")

#define    kSTRDACALCarouselDocumentXAttrCarousel "com.polymicrosystems.pickadisk.device"

CFStringRef kDACALCarouselDocumentXAttrCarousel     = CFSTR(kSTRDACALCarouselDocumentXAttrCarousel);
CFStringRef kDACALCarouselDocumentXAttrSlot         = CFSTR("com.polymicrosystems.pickadisk.device.slot");
CFStringRef kDACALCarouselDocumentXAttrSlotID       = CFSTR("com.polymicrosystems.pickadisk.device.slot.id");
CFStringRef kDACALCarouselDocumentXAttrSlotKind     = CFSTR("com.polymicrosystems.pickadisk.device.slot.kind");
CFStringRef kDACALCarouselDocumentXAttrSlotAddDate  = CFSTR("com.polymicrosystems.pickadisk.device.slot.added");
CFStringRef kDACALCarouselDocumentXAttrSlotIsOut    = CFSTR("com.polymicrosystems.pickadisk.device.slot.isout");
CFStringRef kDACALCarouselDocumentXAttrSlotCheckout = CFSTR("com.polymicrosystems.pickadisk.device.slot.checkout");
CFStringRef kDACALCarouselDocumentXAttrSlotCheckIn  = CFSTR("com.polymicrosystems.pickadisk.device.slot.checkin");
CFStringRef kDACALCarouselDocumentXAttrVolumeName   = CFSTR("com.polymicrosystems.pickadisk.device.volname");
CFStringRef kDACALCarouselDocumentXAttrVolumeSize   = CFSTR("com.polymicrosystems.pickadisk.device.vol.size");

CFStringRef kDACALCarouselDocumentXAttrUserTitle    = CFSTR("com.polymicrosystems.pickadisk.item.usertitle");
CFStringRef kDACALCarouselDocumentXAttrUserComments = CFSTR("com.polymicrosystems.pickadisk.item.user.description");
CFStringRef kDACALCarouselDocumentXAttrUserTags     = CFSTR("com.polymicrosystems.pickadisk.item.user.tags");
CFStringRef kDACALCarouselDocumentXAttrUserStars    = CFSTR("com.polymicrosystems.pickadisk.item.user.starrating");
CFStringRef kDACALCarouselDocumentXAttrUserLinks    = CFSTR("com.polymicrosystems.pickadisk.item.user.urls");
CFStringRef kDACALCarouselDocumentXAttrUserArtwork  = CFSTR("com.polymicrosystems.pickadisk.item.user.artwork");
CFStringRef kDACALCarouselDocumentXAttrUserRating   = CFSTR("com.polymicrosystems.pickadisk.item.user.rating");
CFStringRef kDACALCarouselDocumentXAttrBookmarks    = CFSTR("com.polymicrosystems.pickadisk.item.bookmarks");

CFStringRef kDACALCarouselNoticeDeviceOpen  = CFSTR("Open Device");
CFStringRef kDACALCarouselNoticeDeviceClose = CFSTR("Close Device");

CFStringRef kPADClientIdentifier  = CFSTR("PAD.DACAL.CLIENT");

const DACALDeviceRef kDACALDefaultDevice                 = 0;
const DACALDeviceRef kDACALIllegalDevice                 = DACAL_MAXDEVICE_COUNT+ 1;
const DACALDeviceRef kDACALDevicesMaxCount               = DACAL_MAXDEVICE_COUNT;
const DACALDeviceRef kDACALNullDevice                    = (DACALDeviceRef)NULL;

//static	mach_port_t				masterPort = 0;				// requires <mach/mach.h>
static  io_iterator_t           gDACALAddedIter;
static    CFAllocatorRef        gDACALDefaultCFAllocator = NULL;
static    IONotificationPortRef gDACALNotifyPort;
static    CFRunLoopSourceRef    gDACALRunLoopSource;
static    DACALDeviceRef        gDACALDefaultDevice      = 1;
static    DACALArray            gDACALBoxes;
static  DACALClientsArray       gDACALClients;
static    DACALClientRef        gDACALNextClientID       = 1;

const DACALResult kDACALOK   = kIOReturnSuccess;
const DACALResult kDACALBusy = kIOReturnBusy;
const DACALResult kDACALError = kIOReturnError;
const DACALResult kDACALInvalidParameter = kIOReturnBadArgument;


// Private Functions


DACALResult CarouselEstablishInfoFile(CFUUIDRef boxUUID);

DACALResult CarouselWriteInfoFile(DACALDeviceRef inDevice);

DACALResult CarouselWriteInfoFileKey(DACALDeviceRef inDevice, CFStringRef inKeyName, CFTypeRef inKeyValue);

DACALResult CarouselWriteInfoFileWithDictionary(DACALDeviceRef inDevice, CFDictionaryRef keyValueDictionary);

DACALResult CarouselReadInfoFile(DACALDeviceRef indexID);

CFTypeRef CarouselReadInfoFileKey(DACALDeviceRef deviceID, CFStringRef inKeyName, DACALResult *outResult);

CFDictionaryRef CarouselReadInfoFileKeys(DACALDeviceRef deviceID, CFArrayRef inKeyNames, DACALResult *outResult);

//CFStringRef		CopyUSBProductData(DACALDeviceRef indexID, DACALDeviceNode* outNode);
//DACALResult		SaveUSBProductData(DACALDeviceRef deviceID, CFStringRef inName, DACALDeviceNode inNode);
CFStringRef CFStringCreateFromDacalString(dacalString *deviceBlock);

CFStringRef CFStringCreateFromDacalPipe(CFAllocatorRef inAllocator, CFStringRef inCommandArgs, DACALResult *outError);

void dacalStringSwapDeviceToHost(dacalStringRef inString);

IOReturn dacalGetDescriptor(DACALIOUSBDeviceInterface **deviceIntf, UInt16 index, UInt8 descType, UInt8 descIndex, void *buf, UInt16 len, UInt32 *result);

IOReturn dacalDoRequest(DACALIOUSBDeviceInterface **indeviceIntf, dacalCmd cmd, dacalString *outResult);

DACALCount dacalDeviceRefToDeviceIndex(DACALDeviceRef deviceID);

DACALResult DACALCommandRequest(DACALDeviceRef deviceID, dacalCmd deviceCommand, dacalString *outResult);

DACALResult DACALCommandRequestNoResult(DACALDeviceRef deviceID, dacalCmd deviceCommand);

CFStringRef DACALCommandRequestCFString(DACALDeviceRef deviceID, dacalCmd deviceCommand, DACALResult *outError);

DACALDeviceRef DACALDeviceCreateWithService(io_service_t ioDeviceObj, DACALResult *outError);

DACALResult DACALDeviceClose(DACALDeviceRef deviceID);

CFTypeRef CarouselReadInfoFileKey(DACALDeviceRef deviceID, CFStringRef inKeyName, DACALResult *outResult) {
	DACALResult returnResult = kIOReturnBadArgument;
	DACALDeviceRef  indexID  = dacalDeviceRefToDeviceIndex(deviceID);
	CFURLRef        docURL   = DACAL_BOX_PATH(indexID);
	CFURLRef        infoURL  = NULL;
	CFDataRef       infoText = NULL;
	CFDictionaryRef infoData = NULL;
	Boolean         infoGood = FALSE;
	OSStatus        fileErr;

	CFTypeRef outData = NULL;

	if (!docURL)
		goto BAIL;

	infoURL  = CFURLCreateWithString(NULL, kDACALCarouselDocumentInfoFile, docURL);
	infoGood = CFURLCreateDataAndPropertiesFromResource(NULL, infoURL, &infoText, NULL, NULL, &fileErr);
	if (!infoGood) {
		returnResult = (DACALResult)fileErr;
		goto BAIL;
	}

	infoData = (CFDictionaryRef)CFPropertyListCreateFromXMLData(NULL, infoText, kCFPropertyListImmutable, NULL);
	if (!infoData)
		goto BAIL;

	outData = (CFTypeRef)CFDictionaryGetValue(infoData, (const void *)inKeyName);
	if (!outData)
		goto BAIL;

	CFRetain(outData);
	returnResult = 0;

	//CFShow( outData );

	BAIL:
			CFRelease(infoData);
	if (infoText)
		CFRelease(infoText);
//	if( docURL ) CFRelease( docURL );
	if (infoURL)
		CFRelease(infoURL);

	if (outResult != NULL)
		*outResult = returnResult;
	return outData;
}

CFDictionaryRef CarouselReadInfoFileKeys(DACALDeviceRef deviceID, CFArrayRef inKeyNames, DACALResult *outResult) {
	DACALResult returnResult = kIOReturnBadArgument;
	DACALDeviceRef  indexID     = dacalDeviceRefToDeviceIndex(deviceID);
	CFURLRef        docURL      = DACAL_BOX_PATH(indexID);
	CFURLRef        infoURL     = NULL;
	CFDataRef       infoText    = NULL;
	CFDictionaryRef infoData    = NULL;
	Boolean         infoGood    = FALSE;
	CFStringRef     workKeyName = NULL;
	CFIndex         keyIndex    = 0;
	CFIndex         keyCount    = CFArrayGetCount(inKeyNames);
	OSStatus        fileErr;

	CFMutableDictionaryRef workData = CFDictionaryCreateMutable(gDACALDefaultCFAllocator, keyCount, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFDictionaryRef        outData  = NULL;
	void *workKeyValue = NULL;

	if (!docURL)
		goto BAIL;

	infoURL  = CFURLCreateWithString(NULL, kDACALCarouselDocumentInfoFile, docURL);
	infoGood = CFURLCreateDataAndPropertiesFromResource(NULL, infoURL, &infoText, NULL, NULL, &fileErr);
	if (!infoGood) {
		returnResult = (DACALResult)fileErr;
		goto BAIL;
	}

	infoData = (CFDictionaryRef)CFPropertyListCreateFromXMLData(NULL, infoText, kCFPropertyListImmutable, NULL);
	if (!infoData)
		goto BAIL;

	for (keyIndex = 0; keyIndex < keyCount; keyIndex++) {
		workKeyName  = (CFStringRef)CFArrayGetValueAtIndex(inKeyNames, keyIndex);
		workKeyValue = (void *)CFDictionaryGetValue(infoData, (const void *)workKeyName);
		if (workKeyValue != NULL)
			CFDictionarySetValue(workData, workKeyName, workKeyValue);
	}

	outData      = CFDictionaryCreateCopy(gDACALDefaultCFAllocator, (CFDictionaryRef)workData);
	returnResult = 0;

	//CFShow( outData );

	BAIL:
			if (infoText)
				CFRelease(infoText);
	if (workData)
		CFRelease(workData);
	if (infoURL)
		CFRelease(infoURL);

	if (outResult != NULL)
		*outResult = returnResult;
	return outData;
}

DACALResult CarouselReadInfoFile(DACALDeviceRef deviceID) {
	DACALResult outResult = kIOReturnBadArgument;
	DACALDeviceRef indexID = dacalDeviceRefToDeviceIndex(deviceID);
	CFStringRef    boxName = NULL;

	boxName = (CFStringRef)CarouselReadInfoFileKey(deviceID, kDACALCarouselDocumentInfoKeyName, &outResult);
	if (boxName) {
		//CFShow( boxName );
		DACAL_BOX_NAME(indexID) = CFStringCreateCopy(NULL, boxName);
		if (DACAL_BOX_NAME(indexID) == NULL)
			outResult = kIOReturnBadArgument;
		CFRelease(boxName);
	}

	return outResult;

}

DACALResult CarouselWriteInfoFileKey(DACALDeviceRef inDevice, CFStringRef inKeyName, CFTypeRef inKeyValue) {
	DACALResult outResult = kIOReturnBadArgument;
	DACALDeviceRef indexID       = dacalDeviceRefToDeviceIndex(inDevice);
	CFURLRef       devicePath    = DACAL_BOX_PATH( indexID );
	CFURLRef       savePath      = CFURLCreateCopyAppendingPathComponent(NULL, devicePath, kDACALCarouselDocumentInfoFile, FALSE);
	CFUUIDRef      boxUUID       = DACAL_BOX_UUID( indexID );
	CFStringRef    boxUUIDString = CFUUIDCreateString(NULL, boxUUID);
	CFDataRef      boxXML        = NULL;
	Boolean        goodSave      = FALSE;
	Boolean        infoGood      = FALSE;
	SInt32         saveErr;

	CFMutableDictionaryRef outDict = NULL;

	infoGood = CFURLCreateDataAndPropertiesFromResource(NULL, savePath, &boxXML, NULL, NULL, &saveErr);
	if (!infoGood) {
		outDict = CFDictionaryCreateMutable(NULL, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		goto HAVEDICT;
	}

	outDict = (CFMutableDictionaryRef)CFPropertyListCreateFromXMLData(NULL, boxXML, kCFPropertyListMutableContainersAndLeaves, NULL);
	if (!outDict)
		goto BAIL;

	CFRelease(boxXML);
	boxXML = NULL;

	// Add Key
	HAVEDICT:
			CFDictionarySetValue(outDict, (const void *)inKeyName, (const void *)inKeyValue);

	// Save the file

	boxXML = CFPropertyListCreateXMLData(NULL, (CFPropertyListRef)outDict);
	if (boxXML == NULL)
		goto BAIL;

	goodSave = CFURLWriteDataAndPropertiesToResource(savePath, boxXML, NULL, &saveErr);
	if (!goodSave) {
		outResult = saveErr;
		goto BAIL;
	}

	BAIL:
			if (boxUUIDString)
				CFRelease(boxUUIDString);
	if (boxXML)
		CFRelease(boxXML);
	if (savePath)
		CFRelease(savePath);
	if (outDict)
		CFRelease(outDict);

	return outResult;
}

DACALResult CarouselWriteInfoFileWithDictionary(DACALDeviceRef inDevice, CFDictionaryRef keyValueDictionary) {
	DACALResult outResult = kIOReturnBadArgument;
	DACALDeviceRef indexID       = dacalDeviceRefToDeviceIndex(inDevice);
	CFURLRef       devicePath    = DACAL_BOX_PATH( indexID );
	CFURLRef       savePath      = CFURLCreateCopyAppendingPathComponent(NULL, devicePath, kDACALCarouselDocumentInfoFile, FALSE);
	CFUUIDRef      boxUUID       = DACAL_BOX_UUID( indexID );
	CFStringRef    boxUUIDString = CFUUIDCreateString(NULL, boxUUID);
	CFDataRef      boxXML        = NULL;
	Boolean        goodSave      = FALSE;
	Boolean        infoGood      = FALSE;
	SInt32         saveErr;

	CFMutableDictionaryRef outDict = NULL;

	infoGood = CFURLCreateDataAndPropertiesFromResource(NULL, savePath, &boxXML, NULL, NULL, &saveErr);
	if (!infoGood) {
		outDict = CFDictionaryCreateMutable(NULL, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		goto HAVEDICT;
	}

	outDict = (CFMutableDictionaryRef)CFPropertyListCreateFromXMLData(NULL, boxXML, kCFPropertyListMutableContainersAndLeaves, NULL);
	if (!outDict)
		goto BAIL;

	CFRelease(boxXML);
	boxXML = NULL;

	// Add keys and values from dict
	HAVEDICT:
			[(NSMutableDictionary *)outDict addEntriesFromDictionary: (NSDictionary *)keyValueDictionary];

	// Save the file

	boxXML = CFPropertyListCreateXMLData(NULL, (CFPropertyListRef)outDict);
	if (boxXML == NULL)
		goto BAIL;

	goodSave = CFURLWriteDataAndPropertiesToResource(savePath, boxXML, NULL, &saveErr);
	if (!goodSave) {
		outResult = saveErr;
		goto BAIL;
	}

	BAIL:
			if (boxUUIDString)
				CFRelease(boxUUIDString);
	if (boxXML)
		CFRelease(boxXML);
	if (savePath)
		CFRelease(savePath);
	if (outDict)
		CFRelease(outDict);

	return outResult;
}

DACALResult CarouselWriteInfoFile(DACALDeviceRef inDevice) {
	DACALResult outResult = kIOReturnBadArgument;
	DACALDeviceRef indexID       = dacalDeviceRefToDeviceIndex(inDevice);
	CFURLRef       devicePath    = DACAL_BOX_PATH( indexID );
	CFURLRef       savePath      = CFURLCreateCopyAppendingPathComponent(NULL, devicePath, kDACALCarouselDocumentInfoFile, FALSE);
	CFUUIDRef      boxUUID       = DACAL_BOX_UUID( indexID );
	CFStringRef    boxUUIDString = CFUUIDCreateString(NULL, boxUUID);
	CFDataRef      boxXML        = NULL;
	Boolean        goodSave      = FALSE;
	SInt32         saveErr;

	CFMutableDictionaryRef outDict = NULL;

	CFURLSetXattr(devicePath, kDACALCarouselDocumentXAttrCarousel, boxUUIDString);

	goodSave = CFURLCreateDataAndPropertiesFromResource(NULL, savePath, &boxXML, NULL, NULL, &saveErr);
	if (!goodSave) {
		outDict = CFDictionaryCreateMutable(NULL, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		goto HAVEDICT;
	}

	outDict = (CFMutableDictionaryRef)CFPropertyListCreateFromXMLData(NULL, boxXML, kCFPropertyListMutableContainersAndLeaves, NULL);
	if (!outDict)
		goto BAIL;

	CFRelease(boxXML);
	boxXML = NULL;

	HAVEDICT:

			// Add UUID

			CFDictionarySetValue(outDict, (const void *)kDACALCarouselDocumentInfoKeyUUID, (const void *)boxUUIDString);

	// Add Name

	// If the box doesn't already have a name, assign it one.

	if (DACAL_BOX_NAME(indexID) == NULL) {
		CFStringRef userShortName = CSCopyUserName(TRUE);
		CFStringRef newBoxName    = CFStringCreateWithFormat(NULL, NULL, kDACALCarouselDocumentDisplayNameFormat, userShortName, indexID + 1);
		if (userShortName)
			CFRelease(userShortName);
		if (!newBoxName)
			goto BAIL;
		DACAL_BOX_NAME(indexID) = newBoxName;
	}

	CFDictionarySetValue(outDict, (const void *)kDACALCarouselDocumentInfoKeyName, (const void *)DACAL_BOX_NAME(indexID));

	// Save the file

	//CFShow( outDict );

	boxXML = CFPropertyListCreateXMLData(NULL, (CFPropertyListRef)outDict);
	if (boxXML == NULL)
		goto BAIL;

	//CFShow( boxXML );

	goodSave  = CFURLWriteDataAndPropertiesToResource(savePath, boxXML, NULL, &saveErr);
	if (!goodSave) {
		outResult = saveErr;
		printf("Write Err: %i\n", (int)saveErr);
		goto BAIL;
	}
	outResult = 0;

	BAIL:
			if (boxUUIDString)
				CFRelease(boxUUIDString);
	if (boxXML)
		CFRelease(boxXML);
	if (savePath)
		CFRelease(savePath);
	if (outDict)
		CFRelease(outDict);

	return outResult;
}

DACALResult CarouselEstablishInfoFile(CFUUIDRef boxUUID) {
	DACALResult outResult = kIOReturnBadArgument;
	DACALDeviceRef indexID    = dacalDeviceRefToDeviceIndex((DACALDeviceRef)boxUUID);
	CFStringRef    uuidString = CFUUIDCreateString(NULL, boxUUID);
	CFStringRef    fileTitle  = CFStringCreateWithFormat(NULL, NULL, CFSTR("%@.%@/"), uuidString, kDACALCarouselDocumentExtension);
	CFURLRef       dataURL    = NULL;
	CFURLRef       fileURL    = NULL;
	FSRef          userLibraryFolder;
	FSRef          fileFolder;
	Boolean        fileFound  = FALSE;
	OSErr           osErr;
	DACALResult     resultErr;

	osErr = FSFindFolder(kUserDomain, kDACALCarouselsFolderType, TRUE, &userLibraryFolder);
	if (osErr != 0) {
		if (osErr == fnfErr) {
			FSRef topFolder;
			osErr = DACALCreateLibraryFolder(&topFolder);
            osErr = FSFindFolder(kUserDomain, kDACALCarouselsFolderType, TRUE, &userLibraryFolder);
		} else
            PMLOGEMERG(@"Error finding user library! - err::%i", osErr );
	}
    dataURL = CFURLCreateFromFSRef(NULL, &userLibraryFolder);

	if (dataURL)
		fileURL = CFURLCreateWithString(NULL, fileTitle, dataURL);
	if (fileURL) {
		DACAL_BOX_PATH(indexID) = CFRetain(fileURL);

		fileFound = CFURLGetFSRef(fileURL, &fileFolder);
		if (fileFound) {
			resultErr = CarouselReadInfoFile((DACALDeviceRef)boxUUID);
			goto BAIL;
		}

		UniCharCount theUniCount = (UniCharCount)(CFStringGetLength(fileTitle) - 1);
		UniChar theUniName[1024];

		CFStringGetCharacters(fileTitle, CFRangeMake(0, theUniCount), theUniName);
		osErr = FSCreateDirectoryUnicode(&userLibraryFolder, theUniCount, (const UniChar *)theUniName, kFSCatInfoNone, NULL, &fileFolder, NULL, NULL);
		if (osErr)
			goto BAIL;

		resultErr = CarouselWriteInfoFile((DACALDeviceRef)boxUUID);
	}

	BAIL:

//	if( fileURL ) CFRelease( fileURL );
			if (dataURL)
				CFRelease(dataURL);
	if (fileTitle)
		CFRelease(fileTitle);
	if (uuidString)
		CFRelease(uuidString);

	outResult = osErr;
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

CFStringRef CFStringCreateFromDacalString(dacalString *deviceBlock) {
	return (CFStringCreateWithCharacters(gDACALDefaultCFAllocator, (UniChar *)deviceBlock->uniString, deviceBlock->stringSize));
}

CFStringRef CFStringCreateFromDacalPipe(CFAllocatorRef inAllocator, CFStringRef inCommandArgs, DACALResult *outError) {
	DACALResult outResult = kIOReturnBadArgument;
	CFStringRef outCFText  = NULL;
	CFStringRef theCommand = CFSTR("carousel");
	CFStringRef errUnknown = CFSTR("carousel.sh:");
	CFStringRef doCFCommand;
	char  *doCommand = NULL;
	char  *utf8Name  = NULL;
	UInt8 *urlBuff;
	FILE  *pipe;
	size_t pipeSize = 8192;


	if (inAllocator == NULL)
		inAllocator = gDACALDefaultCFAllocator;

	CFURLRef commandURL  = CFBundleCopyResourceURL(CFBundleGetMainBundle(), theCommand, CFSTR("sh"), NULL);
	size_t urlBuffSize = (size_t)CFStringGetLength(CFURLGetString(commandURL));
	urlBuff = (UInt8 *)calloc(1, urlBuffSize);
	Boolean result = CFURLGetFileSystemRepresentation(commandURL, TRUE, urlBuff, urlBuffSize);

	doCFCommand = CFStringCreateWithFormat(inAllocator, NULL, CFSTR("\"%s\" %@"), urlBuff, inCommandArgs);
	if (doCFCommand == NULL)
		goto BAIL;

	doCommand = CFStringCreateCString(doCFCommand, kCFStringEncodingUTF8);
	if (doCommand == NULL)
		goto BAIL;

	PMLOGDEBUG(@"Carousel command: %s", doCommand);

	utf8Name = (char *)calloc(1, pipeSize);

	pipe = popen(doCommand, "r");
	if (pipe) {
		pipeSize  = fread(utf8Name, 1, pipeSize, pipe);
		outResult = pclose(pipe);
	}

	if (pipeSize > 2) {
		utf8Name[pipeSize - 1] = 0;
		outCFText = CFStringCreateWithCString(inAllocator, utf8Name, kCFStringEncodingUTF8);

		if (CFStringHasPrefix(outCFText, errUnknown) == TRUE) {
			CFRelease(outCFText);
			outCFText = (CFStringRef)NULL;
		}
	}

	BAIL:
			if (outError)
				*outError = outResult;
	if (utf8Name)
		free(utf8Name);
	if (doCFCommand)
		CFRelease(doCFCommand);
//	if( commandURL ) CFRelease( commandURL );
//	if( commandPathURL ) CFRelease( commandPathURL );
	if (doCommand)
		free(doCommand);
	return (outCFText);
}

void dacalStringSwapDeviceToHost(dacalStringRef inString) {
#ifdef __BIG_ENDIAN__
	
	char				swapCode = inString->stringSize;
	char				swapSize = inString->stringCode;
	int					uIndex;
	
	inString->stringSize = swapSize;
	inString->stringCode = swapCode;
	
	for( uIndex=0; uIndex < swapSize; uIndex++ ) 
		inString->uniString[uIndex] = CFSwapInt16( inString->uniString[uIndex] );
	
#endif
}

IOReturn dacalGetDescriptor(DACALIOUSBDeviceInterface **deviceIntf, UInt16 index, UInt8 descType, UInt8 descIndex, void *buf, UInt16 len, UInt32 *result) {
	IOUSBDevRequest  req;
	IOReturn         err;
	USBDeviceAddress usbAddr;
	int              i;

    bzero(&req, sizeof(req));
    req.bmRequestType = USBmakebmRequestType(kUSBAnyDirn, kUSBStandard, kUSBDevice);
    req.bRequest      = kUSBRqGetDescriptor;
    req.wValue        = (descType << 8) | descIndex;
    req.wIndex        = index;
    req.wLength       = len;
    req.pData         = buf;

	for (i = 0; i < 3; i++) {
		bzero(buf, len);
		err = (*deviceIntf)->DeviceRequest(deviceIntf, &req);
		*result = req.wLenDone;
		// DAC-2008-09-24 This should be changed to use CFSwapInt16BigToHost or something similar
		// also, result has to even or swab will fail
//#ifdef __BIG_ENDIAN__
//	if(!err)
//		swab(buf, buf, *result);
//#endif
		if (!err) {
			dacalStringSwapDeviceToHost((dacalStringRef)buf);
			break;
		}
		else if (err == kIOUSBPipeStalled) {
			PMLOGALERT(@"Received kIOUSBPipeStalled: %x", err);
//			usleep(3000);
//			req.bmRequestType = 0x02;
//			req.bRequest = kUSBRqClearFeature;
//			req.wValue = 0;
//			req.wIndex = 0x86;
//			req.wLength = 0;
//			req.pData = buf;
//			err = (*deviceIntf)->DeviceRequest(deviceIntf, &req);
//			*result = req.wLenDone;			
//			err = (*deviceIntf)->USBDeviceAbortPipeZero(deviceIntf);
//			PMLOGALERT(@"Aborting default pipe");
		}
		usleep(50000);
	}
	return err;
}

IOReturn dacalDoRequest(DACALIOUSBDeviceInterface **indeviceIntf, dacalCmd cmd, dacalString *outResult) {
	UInt32             result;
	IOReturn           err = 0;
	time_t             waitTime;
	CFStringRef        descriptorStr;
	CFComparisonResult compareResult;
	dacalString        uniBuf;
	char               cmdStr[128];

	if (gDebugLevel > 1) {
		switch (cmd) {
			case undocManufacturer:
		        strcpy(cmdStr, "undocManufacturer");
		        break;
			case undocSoftware:
		        strcpy(cmdStr, "undocSoftware");
		        break;
			case undocUnknown3:
		        strcpy(cmdStr, "undocUnknown3");
		        break;
			case undocUnknown4:
		        strcpy(cmdStr, "undocUnknown4");
		        break;
			case undocUnknown5:
		        strcpy(cmdStr, "undocUnknown5");
		        break;
			case undocUnknown6:
		        strcpy(cmdStr, "undocUnknown6");
		        break;
			case undocUnknown7:
		        strcpy(cmdStr, "undocUnknown7");
		        break;
			case undocUnknown8:
		        strcpy(cmdStr, "undocUnknown8");
		        break;
			case cmdGetModel:
		        strcpy(cmdStr, "cmdGetModel");
		        break;
			case cmdGetUUID:
		        strcpy(cmdStr, "cmdGetUUID");
		        break;
			case cmdReset:
		        strcpy(cmdStr, "cmdReset");
		        break;
			case cmdMoveToSlot:
		        strcpy(cmdStr, "cmdMoveToSlot");
		        break;
			case cmdReserved1:
		        strcpy(cmdStr, "cmdReserved1");
		        break;
			case cmdCloseDoor:
		        strcpy(cmdStr, "cmdCloseDoor");
		        break;
			case cmdLEDOn:
		        strcpy(cmdStr, "cmdLEDOn");
		        break;
			case cmdLEDOff:
		        strcpy(cmdStr, "cmdLEDOff");
		        break;
			case cmdGetStatus:
		        strcpy(cmdStr, "cmdGetStatus");
		        break;
			case cmdGetSlot:
		        strcpy(cmdStr, "cmdGetSlot");
		        break;
			case cmdMoveToDVD:
		        strcpy(cmdStr, "cmdMoveToDVD");
		        break;
			case cmdEjectDVD:
		        strcpy(cmdStr, "cmdEjectDVD");
		        break;
			default:
		        break;
		}
	}

	PMLOG(PMLogLevelDebug3, @"DoCmd %d - %s\n", cmd, cmdStr);

	//	goto doCmd;

	waitTime    = time(NULL);
	if (waitTime == -1) {
		PMLOGEMERG(@"internal error, could not get time value\n");
		return (IOReturn)kIOReturnError;
	}
	waitTime += 2;
	while (true) {
		tryagain:
				PMLOG(PMLogLevelDebug3, @"Trying cmd %d", cmd);
		if (time(NULL) > waitTime) {
			PMLOGEMERG(@"DoCmd timed out\n");
			return (IOReturn)kIOReturnError;
		}
		err = dacalGetDescriptor(indeviceIntf, 0x0409, kUSBStringDesc, cmdGetStatus, &uniBuf, (UInt16)PMBUFSIZE(dacalString), &result);
		if (err == kIOReturnNotResponding) {
			PMLOGEMERG(@"Device not responding");
			usleep(5000);
			goto tryagain;
		}
		if (err == kIOUSBPipeStalled) {
			PMLOGALERT(@"DoCmd reporting stall from device: %x\n", err);
			// reset stall on endpoint
			err = dacalGetDescriptor(indeviceIntf, 0x0086, kUSBAnyDesc, 0, &uniBuf, 0, &result);
			goto tryagain;
		}
		if (err) {
			PMLOGALERT(@"DoCmd reporting error from device: %x\n", err);
			return err;
		}
		descriptorStr = CFStringCreateFromDacalString(&uniBuf);

		PMLOG(PMLogLevelDebug2, @"Device Status: %@\n", descriptorStr );

		compareResult = CFStringCompareWithOptions(descriptorStr, dacalERROR, CFRangeMake(0, CFStringGetLength(dacalERROR)), kCFCompareCaseInsensitive);
		if (compareResult == kCFCompareEqualTo) {
			PMLOGALERT(@"DoCmd reporting error from device\n");
			return (IOReturn)kDACALError;
		}

		compareResult = CFStringCompareWithOptions(descriptorStr, dacalBUSY, CFRangeMake(0, CFStringGetLength(dacalBUSY)), kCFCompareCaseInsensitive);
		if (compareResult == kCFCompareEqualTo) {
			PMLOG(PMLogLevelDebug3, @"DoCmd reporting busy\n");
			return (IOReturn)kDACALBusy;
		}

		compareResult = CFStringCompareWithOptions(descriptorStr, dacalACK, CFRangeMake(0, CFStringGetLength(dacalACK)), kCFCompareCaseInsensitive);
		if (compareResult == kCFCompareEqualTo)
			break;

		compareResult = CFStringCompareWithOptions(descriptorStr, dacalDC300, CFRangeMake(0, CFStringGetLength(dacalNUMBER)), kCFCompareCaseInsensitive);
		if (compareResult == kCFCompareEqualTo)
			break;

		compareResult = CFStringCompareWithOptions(descriptorStr, dacalDC016RW, CFRangeMake(0, CFStringGetLength(dacalNUMBER)), kCFCompareCaseInsensitive);
		if (compareResult == kCFCompareEqualTo)
			break;
	}
	doCmd:
			err = dacalGetDescriptor(indeviceIntf, 0x0409, kUSBStringDesc, cmd, outResult, (UInt16)PMBUFSIZE(dacalString), &result);
	return err;
}

DACALCount dacalDeviceRefToDeviceIndex(DACALDeviceRef deviceID) {
	SInt8 checkIndex = 0;

	if (gDACALBoxes.boxCount == 0)
		return (DACALCount)(kDACALIllegalDevice);                            // No Boxes
	if (deviceID == kDACALDefaultDevice)
		return (DACALCount)(gDACALDefaultDevice - 1);                // Default Box
	if ((1 <= deviceID) & (deviceID <= gDACALBoxes.boxCount))
		return (DACALCount)(deviceID - 1);        // Actual Device

//	for( checkIndex = 0; checkIndex < gDACALBoxes.boxCount; checkIndex++ )					// Node ID
//		if( DACAL_BOX_NODE(checkIndex) == deviceID ) return( checkIndex );

    // TODO: This looks wrong, should never be > 256
	if (deviceID > kDACALIllegalDevice) {
		CFUUIDRef   possibleID   = (CFUUIDRef)deviceID;
		CFStringRef possibleName = (CFStringRef)deviceID;

		if (CFGetTypeID(possibleID) == CFUUIDGetTypeID())                                    // UUID?
			for (checkIndex = 0; checkIndex < gDACALBoxes.boxCount; checkIndex++)
				if (DACAL_BOX_UUID(checkIndex))
                    if (CFEqual(DACAL_BOX_UUID(checkIndex), possibleID))
	                    return (DACALCount)(checkIndex);

		if (CFGetTypeID(possibleName) == CFStringGetTypeID())                                // Name?
			for (checkIndex = 0; checkIndex < gDACALBoxes.boxCount; checkIndex++)
				if (DACAL_BOX_NAME(checkIndex)) if (CFEqual(DACAL_BOX_NAME(checkIndex), possibleName))
					return (DACALCount)(checkIndex);
	}

	return (DACALCount)(kDACALIllegalDevice);
}

DACALResult DACALCommandRequest(DACALDeviceRef deviceID, dacalCmd deviceCommand, dacalString *outResult) {
	DACALCount  indexID = dacalDeviceRefToDeviceIndex(deviceID);
	DACALResult result;

	if (indexID == kDACALIllegalDevice)
		return( kIOReturnNoDevice );

	result = dacalDoRequest(gDACALBoxes.box[indexID].boxRef, deviceCommand, outResult);
	return result;
}

DACALResult DACALCommandRequestNoResult(DACALDeviceRef deviceID, dacalCmd deviceCommand) {
	dacalString ourResult;
	DACALCount  indexID = dacalDeviceRefToDeviceIndex(deviceID);

	if (indexID == kDACALIllegalDevice)
		return( kIOReturnNoDevice );

	return dacalDoRequest(gDACALBoxes.box[indexID].boxRef, deviceCommand, &ourResult);
}

CFStringRef DACALCommandRequestCFString(DACALDeviceRef deviceID, dacalCmd deviceCommand, DACALResult *outError) {
	DACALResult theErr;
	dacalString ourResult;
	CFStringRef theString = NULL;
	DACALCount  indexID   = dacalDeviceRefToDeviceIndex(deviceID);

	if (indexID == kDACALIllegalDevice) {
		if (outError)
			*outError = kIOReturnNoDevice;
		return (theString);
	}

	theErr = DACALCommandRequest(deviceID, deviceCommand, &ourResult);
	if (outError)
		*outError = theErr;
	if (theErr)
		return (theString);

	theString = CFStringCreateFromDacalString(&ourResult);

	return (theString);
}

CFStringRef DACALCommandCopyStatus(DACALDeviceRef deviceID, DACALResult *outError) {
	DACALResult theErr;
	dacalString ourResult;
	CFStringRef theString = NULL;

	theErr = DACALCommandRequest(deviceID, cmdGetStatus, &ourResult);
	if (outError)
		*outError = theErr;
	if (theErr)
		return (theString);

	theString = CFStringCreateFromDacalString(&ourResult);

	return (theString);
}

CFUUIDRef DACALCommandCopyUUID(DACALDeviceRef deviceID, DACALResult *outError) {
	DACALResult theErr;
	dacalString ourResult;

	CFUUIDBytes *bytes;
	CFUUIDRef      deviceUUID = NULL;
	DACALDeviceRef indexID    = dacalDeviceRefToDeviceIndex(deviceID);

	if (indexID == kDACALIllegalDevice) {
		if (outError)
			*outError = kIOReturnNoDevice;
		return (deviceUUID);
	}

	deviceUUID = DACAL_BOX_UUID(indexID);

	if (deviceUUID != NULL) {
		if (outError)
			*outError = kDACALOK;
		return (CFUUIDCreateFromUUIDBytes(gDACALDefaultCFAllocator, CFUUIDGetUUIDBytes(deviceUUID)));
	}

	bzero(&ourResult, sizeof(ourResult));
	theErr = DACALCommandRequest(deviceID, cmdGetUUID, &ourResult);
	if (outError)
		*outError = theErr;
	if (theErr)
		return ((CFUUIDRef)NULL);
/*	
	{
		// DAC-2008-09-25 This should be changed to use CFSwapInt16BigToHost or something similar
		// also, result has to even or swab will fail
#ifdef __BIG_ENDIAN__
		swab(ourResult.uniString, ourResult.uniString, ourResult.stringSize*2);
#endif
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
*/
	bytes      = (CFUUIDBytes *)ourResult.uniString;
	deviceUUID = CFUUIDCreateFromUUIDBytes(gDACALDefaultCFAllocator, *bytes);
	if (deviceUUID)
	DACAL_BOX_UUID(indexID) = deviceUUID;

	//CFShow( deviceUUID );

	if (deviceUUID)
		return (CFUUIDCreateFromUUIDBytes(gDACALDefaultCFAllocator, CFUUIDGetUUIDBytes(deviceUUID)));
	return (deviceUUID);
}

CFStringRef DACALCommandCopyModel(DACALDeviceRef deviceID, DACALResult *outError) {
	DACALResult        theErr;
	CFStringRef        descriptorStr;
	CFComparisonResult compareResult;

	CFStringRef modelName = NULL;
	DACALCount  indexID   = dacalDeviceRefToDeviceIndex(deviceID);

	if (indexID == kDACALIllegalDevice) {
		if (outError)
			*outError = kIOReturnNoDevice;
		return (modelName);
	}

	modelName = DACAL_BOX_MODEL(indexID);
	if (modelName != NULL)
		return (CFStringCreateCopy(gDACALDefaultCFAllocator, modelName));

	descriptorStr = DACALCommandRequestCFString(deviceID, cmdGetModel, &theErr);
	if (outError)
		*outError = theErr;
	if (theErr)
		return (modelName);

	compareResult = CFStringCompareWithOptions(descriptorStr, dacalDC300, CFRangeMake(0, CFStringGetLength(dacalDC300)), kCFCompareCaseInsensitive);
	if (compareResult == kCFCompareEqualTo)
		modelName = DACALDC300CFName;
	else {
		compareResult = CFStringCompareWithOptions(descriptorStr, dacalDC016RW, CFRangeMake(0, CFStringGetLength(dacalDC016RW)), kCFCompareCaseInsensitive);
		if (compareResult == kCFCompareEqualTo)
			modelName = DACALDC016CFName;
		else
			modelName = descriptorStr;
	}

	DACAL_BOX_MODEL(indexID) = modelName;
//	if( modelName ) CFRetain( modelName );

	return (modelName);
}

DACALResult
DACALCommandReset(DACALDeviceRef deviceID) {
	DACALResult theErr = DACALCommandRequestNoResult(deviceID, cmdReset);

	DACAL_RESET_SLEEP

	return (theErr);
}

DACALResult
DACALCommandCloseDoor(DACALDeviceRef deviceID) {
	DACALResult theErr = DACALCommandRequestNoResult(deviceID, cmdCloseDoor);

	if (theErr == 0) {
		DACALCount indexID = dacalDeviceRefToDeviceIndex(deviceID);

		DACAL_BOX_LASTSLOT(indexID) = 0;
		DACAL_BOX_LASTSLOTTIME(indexID) = -1;
	}

	DACAL_SHORT_SLEEP

	return (theErr);
}

DACALResult
DACALCommandSetLED(DACALDeviceRef deviceID, Boolean isVisible) {
	DACALResult theErr;

	if (isVisible)
		theErr = DACALCommandRequestNoResult(deviceID, cmdLEDOn);
	else
		theErr = DACALCommandRequestNoResult(deviceID, cmdLEDOff);

	DACAL_SHORT_SLEEP

	return (theErr);
}

DACALResult
DACALCommandMoveToSlotWithOptions(DACALDeviceRef deviceID, DACALSlotNum newSlot, DACALOptionBits moveOptions) {
	DACALResult theErr       = kIOReturnNoDevice;
	dacalString slotBuffer;
	UInt32      result;
	Boolean     moveOnce     = moveOptions == kDACALOptionMoveOnce;
	Boolean     moveOpenSlot = moveOptions == kDACALOptionMoveOpenSlot;
	Boolean     moveToggle   = moveOptions == kDACALOptionMoveToggle;
	Boolean     doClose      = !moveOpenSlot;
	Boolean     doOpen       = TRUE;


	DACALCount   indexID     = dacalDeviceRefToDeviceIndex(deviceID);
	DACALSlotNum theLastSlot = DACAL_BOX_LASTSLOT(indexID);
	time_t       theLastTime = DACAL_BOX_LASTSLOTTIME(indexID);


	if (indexID == kDACALIllegalDevice)
		return( kIOReturnNoDevice );

	if (moveToggle) {
		if (theLastSlot != newSlot) {
			doClose = TRUE;
			doOpen  = TRUE;
		}
		else {
			doClose = (theLastTime != -1);
			doOpen  = !doClose;
		}
	}

	if (moveOnce) if (theLastSlot == newSlot)
		return (kDACALBusy);

	if (doClose) {
		theErr = DACALCommandCloseDoor(deviceID);
		if (theErr)
			goto ERRORBAIL;
	}

	if (doClose && doOpen)
        DACAL_SHORT_SLEEP

	if (doOpen) {
		theErr = DACALCommandRequestNoResult(deviceID, cmdMoveToSlot);
		theErr = dacalGetDescriptor(gDACALBoxes.box[indexID].boxRef, 0x0409, kUSBStringDesc, (UInt8)newSlot, &slotBuffer, (UInt16)PMBUFSIZE(slotBuffer), &result);
	}

	ERRORBAIL:
    if ((theErr == 0) && (moveToggle))
        if (theLastSlot == newSlot) {
            if (theLastTime == -1)
				DACAL_BOX_LASTSLOTTIME(indexID) = time(NULL);
            if (theLastTime != -1)
				DACAL_BOX_LASTSLOTTIME(indexID) = -1;
            return (theErr);
        }

	if (theErr == 0) {
		DACAL_BOX_LASTSLOT(indexID) = newSlot;
		DACAL_BOX_LASTSLOTTIME(indexID) = time(NULL);
	}
	else {
		DACAL_BOX_LASTSLOT(indexID) = 0;
		DACAL_BOX_LASTSLOTTIME(indexID) = -1;
	}

	return (theErr);
}

DACALResult
DACALCommandMoveToSlot(DACALDeviceRef deviceID, DACALSlotNum newSlot) {
	return DACALCommandMoveToSlotWithOptions(deviceID, newSlot, kDACALOptionMoveDefault);
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
	theErr = dacalGetDescriptor(gDACALBoxes.box[indexID].boxRef, 0x0409, kUSBStringDesc, newSlot, &slotBuffer, PMBUFSIZE(slotBuffer), &result);
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
}

DACALSlotNum
DACALCommandDVDGetSlot(DACALDeviceRef deviceID, DACALResult *outError) {
	DACALResult        theErr;
	CFStringRef        descriptorStr;
	CFComparisonResult compareResult;

	DACALSlotNum outSlot = 0;

	descriptorStr = DACALCommandRequestCFString(deviceID, cmdGetSlot, &theErr);
	if (outError)
		*outError = theErr;
	if (theErr)
		return (outSlot);
	DACAL_SHORT_SLEEP

	compareResult = CFStringCompareWithOptions(descriptorStr, dacalNAN, CFRangeMake(0, CFStringGetLength(dacalDC300)), kCFCompareCaseInsensitive);
	if (compareResult == kCFCompareEqualTo)
		outSlot   = 0;
	else
		outSlot = (DACALSlotNum)CFStringGetIntValue(descriptorStr);

	if (descriptorStr)
		CFRelease(descriptorStr);

	return (outSlot);
}

DACALResult
DACALCommandDVDMoveTo(DACALDeviceRef deviceID, DACALSlotNum newSlot) {
	DACALResult theErr;
	dacalString slotBuffer;
	UInt32      result;
	DACALCount  indexID = dacalDeviceRefToDeviceIndex(deviceID);

	if (indexID == kDACALIllegalDevice)
		return( kIOReturnNoDevice );

	theErr = DACALCommandRequestNoResult(deviceID, cmdMoveToDVD);
	if (theErr)
		return (theErr);
	DACAL_SHORT_SLEEP

	theErr = dacalGetDescriptor(gDACALBoxes.box[indexID].boxRef, 0x0409, kUSBStringDesc, (UInt8)newSlot, &slotBuffer, (UInt16)PMBUFSIZE(slotBuffer), &result);
	DACAL_SHORT_SLEEP

	return (theErr);
}

DACALResult
DACALCommandDVDEject(DACALDeviceRef deviceID) {
	DACALResult theErr = DACALCommandRequestNoResult(deviceID, cmdEjectDVD);
	DACAL_SHORT_SLEEP

	return (theErr);
}

CFStringRef
DACALCommandCopyName(DACALDeviceRef deviceID, DACALResult *outError) {
	DACALCount  indexID  = dacalDeviceRefToDeviceIndex(deviceID);
	CFStringRef nameCopy = NULL;

	if (indexID == kDACALIllegalDevice) {
		if (outError)
			*outError = kIOReturnNoDevice;
		return (nameCopy);
	}

	if (outError)
		*outError = 0;
	nameCopy = DACAL_BOX_NAME(indexID);
	if (nameCopy)
		return (CFStringCreateCopy(gDACALDefaultCFAllocator, nameCopy));

	return (nameCopy);
}

DACALResult
DACALCommandSetName(DACALDeviceRef deviceID, CFStringRef deviceName) {
	DACALCount indexID = dacalDeviceRefToDeviceIndex(deviceID);

	if (indexID == kDACALIllegalDevice)
		return( kIOReturnNoDevice );


	if (deviceName && DACAL_BOX_NAME(indexID))
		CFRelease(DACAL_BOX_NAME(indexID));
	if (deviceName) DACAL_BOX_NAME(indexID) = CFStringCreateCopy(NULL, deviceName);
//	else DACAL_BOX_NAME(indexID) = deviceName;

	return CarouselWriteInfoFile(deviceID);
//	return SaveUSBProductData( deviceID, deviceName, 0 );
}

DACALDeviceRefNode
DACALCommandCopyNode(DACALDeviceRef deviceID, DACALResult *outError) {
	DACALCount indexID = dacalDeviceRefToDeviceIndex(deviceID);

	if (indexID == kDACALIllegalDevice) {
		if (outError)
			*outError = kIOReturnNoDevice;
		return (0);
	}

	if (outError)
		*outError = 0;
	return ((DACALDeviceRefNode)indexID + 1);
}

/*
 DACALResult			
 DACALCommandSetNode( DACALDeviceRef deviceID, DACALDeviceNode deviceNode ) {
	DACALCount		indexID = dacalDeviceRefToDeviceIndex( deviceID );
	
	if( indexID == kDACALIllegalDevice ) return( kIOReturnNoDevice );
	
//	DACAL_BOX_NODE(indexID) = deviceNode;

	return CarouselWriteInfoFile( deviceID );
//	return SaveUSBProductData( deviceID, DACAL_BOX_NAME(indexID), deviceNode );
}
*/

DACALSlotNum
DACALCommandGetSlotCount(DACALDeviceRef deviceID) {
	DACALSlotNum badSlotCount = 0;
	DACALCount   indexID      = dacalDeviceRefToDeviceIndex(deviceID);

	if (indexID == kDACALIllegalDevice)
		return (badSlotCount);
	if (DACAL_BOX_MODEL(indexID) == NULL)
		return (badSlotCount);

	return (DACALDevicesGetSlotCount(DACAL_BOX_MODEL(indexID)));
}

CFURLRef
DACALCommandCopyPath(DACALDeviceRef deviceID, DACALResult *outError) {
	DACALCount indexID  = dacalDeviceRefToDeviceIndex(deviceID);
	CFURLRef   pathCopy = NULL;

	if (indexID == kDACALIllegalDevice) {
		if (outError)
			*outError = kIOReturnNoDevice;
		return (pathCopy);
	}

	if (outError)
		*outError = 0;
	pathCopy = DACAL_BOX_PATH(indexID);
	if (pathCopy)
		return (CFURLCreateCopyAppendingPathComponent(gDACALDefaultCFAllocator, pathCopy, CFSTR(""), FALSE));

	return (pathCopy);
}

CFMutableArrayRef
DACALCommandCopyAllSlotPaths(DACALDeviceRef deviceID, DACALResult *outError) {
	DACALCount        indexID    = dacalDeviceRefToDeviceIndex(deviceID);
	DACALResult       outResult;
	CFURLRef          pathCopy   = NULL;
	CFDictionaryRef   dataDict   = NULL;
	CFArrayRef        dataProps  = CFArrayCreate(NULL, (const void **)&kCFURLFileDirectoryContents, 1, &kCFTypeArrayCallBacks);
	CFArrayRef        folderList = NULL;
	CFMutableArrayRef slotList   = NULL;
	CFURLRef          testSlot   = NULL;
	Boolean           wasFound   = FALSE;
	SInt32            cfError;
	int               index;

	if (indexID == kDACALIllegalDevice) {
		if (outError)
			*outError = kIOReturnNoDevice;
		return (slotList);
	}

	pathCopy = DACALCommandCopyPath(deviceID, outError);
	if (pathCopy == NULL)
		return (slotList);

	wasFound = CFURLCreateDataAndPropertiesFromResource(NULL, pathCopy, NULL, &dataDict, dataProps, &cfError);
	if (wasFound) {
		folderList = (CFArrayRef)CFDictionaryGetValue(dataDict, kCFURLFileDirectoryContents);
		if (folderList != NULL) {
			// CFShow( folderList );
			slotList = CFArrayCreateMutable(NULL, CFArrayGetCount(folderList), &kCFTypeArrayCallBacks);
			if (slotList) {
				for (index = 0; index < CFArrayGetCount(folderList); index++) {
					testSlot = (CFURLRef)CFArrayGetValueAtIndex(folderList, index);
					if (CFURLIsSlot(testSlot))
						CFArrayAppendValue(slotList, (const void *)testSlot);
				}
				// CFShow( slotList );
			}
		}
		CFRelease(dataDict);
		outResult = 0;
	}
	else {
		outResult = cfError;
	}

	if (outError != NULL)
		*outError = outResult;
	return (slotList);
}

DACALResult
DACALSlotCreateIndex(
		DACALDeviceRef deviceID, DACALSlotNum slotNum, CFStringRef slotTitle,
		DACALCount indexLevel, CFURLRef sourcePath
                    ) {
	DACALResult outResult  = kIOReturnBadArgument;
	CFStringRef doCFCommand;
	CFStringRef doCommand;
	CFStringRef sourceType = CFSTR("-n");
	UTF8Char *sourceFilePath;
	Boolean     goodPath;
	DACALCount  indexID    = dacalDeviceRefToDeviceIndex(deviceID);
	CFStringRef boxUUID    = CFUUIDCreateString(NULL, DACAL_BOX_UUID(indexID));

	CFURLRef slotURL = NULL;

	if (indexID == kDACALIllegalDevice)
		return( kIOReturnNoDevice );

	if (sourcePath != NULL) {
		sourceFilePath = (UTF8Char *)calloc(1, 4096);
		goodPath       = CFURLGetFileSystemRepresentation(sourcePath, TRUE, sourceFilePath, 4096);
		sourceType     = CFStringCreateWithFormat(gDACALDefaultCFAllocator, NULL, CFSTR("-d \"%s\""), sourceFilePath);
		free(sourceFilePath);
	}

//	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL,
//										   CFSTR("-x -c %i -s %i -t \"%@\" -l %i %@"), 
//										   indexID + 1, slotNum, slotTitle, indexLevel, sourceType );
	doCFCommand = CFStringCreateWithFormat(
			gDACALDefaultCFAllocator, NULL,
			CFSTR("-x -c %@ -s %i -t \"%@\" -l %i %@"),
			boxUUID, slotNum, slotTitle, indexLevel, sourceType
	                                      );
	if (doCFCommand == NULL)
		goto BAIL;

	CFShow(CFSTR("Driver call:"));
	CFShow(doCFCommand);

	doCommand = CFStringCreateFromDacalPipe(gDACALDefaultCFAllocator, doCFCommand, &outResult);
	if (doCommand != NULL)
		CFRelease(doCommand);

	slotURL = DACALSlotCopyPath(deviceID, slotNum, &outResult);
	if (slotURL)
		CFURLSetXattr(slotURL, kDACALCarouselDocumentXAttrSlotAddDate, (CFStringRef)[[NSDate date] description]);
	if (slotURL)
		CFRelease(slotURL);

	BAIL:
			if (doCFCommand)
				CFRelease(doCFCommand);
	if (sourceType)
		CFRelease(sourceType);
	if (boxUUID)
		CFRelease(boxUUID);
	return (outResult);
}

DACALResult
DACALSlotDeleteIndex(DACALDeviceRef deviceID, DACALSlotNum slotNum) {
	DACALResult outResult;
	CFStringRef doCFCommand = NULL;
	CFStringRef pipeResult  = NULL;
	DACALCount  indexID     = dacalDeviceRefToDeviceIndex(deviceID);
	CFStringRef boxUUID     = CFUUIDCreateString(NULL, DACAL_BOX_UUID(indexID));

	if (indexID == kDACALIllegalDevice) {
		outResult = kIOReturnNoDevice;
		goto BAIL;
	}

//	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL, CFSTR("-c %i -s %i -k"), indexID + 1, slotNum );
	doCFCommand = CFStringCreateWithFormat(gDACALDefaultCFAllocator, NULL, CFSTR("-c %@ -s %i -k"), boxUUID, slotNum);
	if (doCFCommand == NULL) {
		outResult = kIOReturnNoDevice;
		goto BAIL;
	}

	pipeResult = CFStringCreateFromDacalPipe(gDACALDefaultCFAllocator, doCFCommand, &outResult);

	BAIL:
			if (pipeResult != NULL)
				CFRelease(pipeResult);
	if (boxUUID)
		CFRelease(boxUUID);
	CFRelease(doCFCommand);
	return (outResult);
}

DACALResult
DACALSlotMove(
		DACALDeviceRef fromDeviceID, DACALSlotNum fromSlotNum,
		DACALDeviceRef toDeviceID, DACALSlotNum toSlotNum
             ) {
	DACALResult outResult = kIOReturnNoDevice;
	CFStringRef returnText   = NULL;
	CFStringRef scriptArgs   = NULL;
	CFStringRef scriptFormat = CFSTR("--from-carousel %@ --from-slot %i --to-carousel %@ --to-slot %i");
	CFStringRef fromBoxUUID  = NULL;
	CFStringRef destBoxUUID  = NULL;
	DACALCount  fromIndexID  = 0;
	DACALCount  toIndexID    = 0;

	if (toDeviceID == kDACALNullDevice)
		toDeviceID = fromDeviceID;
	if (toSlotNum == 0)
		toSlotNum  = fromSlotNum;

	fromIndexID = dacalDeviceRefToDeviceIndex(fromDeviceID);
	toIndexID   = dacalDeviceRefToDeviceIndex(toDeviceID);

	if ((fromIndexID == kDACALIllegalDevice) || (toIndexID == kDACALIllegalDevice))
		goto BAIL;

	if ((fromSlotNum < 1) || (fromSlotNum > DACALCommandGetSlotCount(fromDeviceID)))
		goto BAIL;
	if ((toSlotNum < 1) || (toSlotNum > DACALCommandGetSlotCount(toDeviceID)))
		goto BAIL;

	fromBoxUUID = CFUUIDCreateString(gDACALDefaultCFAllocator, DACAL_BOX_UUID(fromIndexID));
	destBoxUUID = CFUUIDCreateString(gDACALDefaultCFAllocator, DACAL_BOX_UUID(toIndexID));

	if ((fromBoxUUID == NULL) || (destBoxUUID == NULL))
		goto BAIL;

	scriptArgs = CFStringCreateWithFormat(gDACALDefaultCFAllocator, NULL, scriptFormat, fromBoxUUID, fromSlotNum, destBoxUUID, toSlotNum);

	returnText = CFBundleRunShellScript(gDACALDefaultCFAllocator, CFBundleGetMainBundle(), CFSTR("swapslot"), scriptArgs, (OSStatus *)&outResult);

	BAIL:
    if (fromBoxUUID)
        CFRelease(fromBoxUUID);
	if (destBoxUUID)
		CFRelease(destBoxUUID);
	if (scriptArgs)
		CFRelease(scriptArgs);
	if (returnText)
		CFRelease(returnText);
	return outResult;
}

CFStringRef
DACALSlotCopyTitle(DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult *outError) {
	DACALResult theErr = kIOReturnBadArgument;
	CFStringRef outputString = NULL;
	CFStringRef doCFCommand  = NULL;
	DACALCount  indexID      = dacalDeviceRefToDeviceIndex(deviceID);
	CFStringRef boxUUID      = NULL;

	if (indexID == kDACALIllegalDevice) {
		theErr = kIOReturnNoDevice;
		goto BAIL;
	}

	boxUUID = CFUUIDCreateString(NULL, DACAL_BOX_UUID(indexID));
	if (boxUUID == NULL)
		goto BAIL;

//	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL, CFSTR("-c %i -s %i -w"), indexID + 1, slotNum );
	doCFCommand = CFStringCreateWithFormat(gDACALDefaultCFAllocator, NULL, CFSTR("-c %@ -s %i -w"), boxUUID, slotNum);
	if (doCFCommand == NULL)
		goto BAIL;

	outputString = CFStringCreateFromDacalPipe(gDACALDefaultCFAllocator, doCFCommand, outError);
	theErr       = kDACALOK;

	BAIL:
			if (doCFCommand)
				CFRelease(doCFCommand);
	if (boxUUID)
		CFRelease(boxUUID);

	if (outError)
		*outError = theErr;
	return (outputString);
}

DACALResult
DACALSlotSetTitle(DACALDeviceRef deviceID, DACALSlotNum slotNum, CFStringRef slotTitle) {
	DACALResult outResult = kIOReturnBadArgument;
	CFStringRef doCFCommand;
	CFStringRef doCommand;
	DACALCount  indexID   = dacalDeviceRefToDeviceIndex(deviceID);
	CFStringRef boxUUID   = CFUUIDCreateString(NULL, DACAL_BOX_UUID(indexID));

	if (indexID == kDACALIllegalDevice)
		return( kIOReturnNoDevice );

	doCFCommand = CFStringCreateWithFormat(
			gDACALDefaultCFAllocator, NULL,
			CFSTR("-c %@ -s %i -R \"%@\""),
			boxUUID, slotNum, slotTitle
	                                      );
	if (doCFCommand == NULL)
		goto BAIL;

	if (gDebugLevel > 1) {
		CFShow(CFSTR("Driver call DACALSlotSetTitle:"));
		CFShow(doCFCommand);
	}

	doCommand = CFStringCreateFromDacalPipe(gDACALDefaultCFAllocator, doCFCommand, &outResult);
	if (doCommand != NULL)
		CFRelease(doCommand);

	BAIL:
			if (doCFCommand)
				CFRelease(doCFCommand);
	if (boxUUID)
		CFRelease(boxUUID);
	return (outResult);
}

CFURLRef
DACALSlotCopyPath(DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult *outError) {
	CFURLRef    outURL   = NULL;
	CFURLRef    boxURL   = DACALCommandCopyPath(deviceID, outError);
	CFStringRef slotName = NULL;
	FSRef       slotRef;
	Boolean     goodSlot = FALSE;

	if (boxURL == NULL)
		return outURL;

	slotName = CFStringCreateWithFormat(gDACALDefaultCFAllocator, NULL, CFSTR("Slot %i"), (int)slotNum);
	if (slotName) {
		outURL = CFURLCreateCopyAppendingPathComponent(gDACALDefaultCFAllocator, boxURL, slotName, TRUE);
		CFRelease(slotName);
	}

	// check if real?
	if (outURL) {
		goodSlot = CFURLGetFSRef(outURL, &slotRef);
		if (!goodSlot) {
			CFRelease(outURL);
			outURL = NULL;
		}
	}

	return outURL;
}
/*
CFURLRef		
DACALSlotCopyPath( DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult* outError ) {
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

CFStringRef
DACALSlotCopyType(DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult *outError) {
	DACALResult outResult = kIOReturnBadArgument;
	CFStringRef slotType = NULL;
	CFURLRef    slotURL  = DACALSlotCopyPath(deviceID, slotNum, &outResult);

	if (outResult != 0)
		goto BAIL;
	if (slotURL == NULL) {
		outResult = kIOReturnBadArgument;
		goto BAIL;
	}

	slotType = CFURLCopyXattr(gDACALDefaultCFAllocator, slotURL, kDACALCarouselDocumentXAttrSlotKind, (OSStatus *)&outResult);

	BAIL:
			if (outError)
				*outError = outResult;
	if (slotURL)
		CFRelease(slotURL);
	return (slotType);
}

DACALResult DACALSlotSetType(DACALDeviceRef deviceID, DACALSlotNum slotNum, CFStringRef slotType) {
	DACALResult outResult = kIOReturnBadArgument;
	CFURLRef slotURL = DACALSlotCopyPath(deviceID, slotNum, &outResult);

	if (outResult != 0)
		goto BAIL;
	if (slotURL == NULL) {
		outResult = kIOReturnBadArgument;
		goto BAIL;
	}

	outResult = CFURLSetXattr(slotURL, kDACALCarouselDocumentXAttrSlotKind, slotType);

	BAIL:
			if (slotURL)
				CFRelease(slotURL);
	return (outResult);
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
	
	if( pmCFUtilityVerbose )
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

DACALSlotNum
DACALSlotNextFreeNumber(
		DACALDeviceRef deviceID, DACALSlotNum lowestSlot,
		DACALSlotNum highestSlot, DACALResult *outError
                       ) {
	DACALSlotNum outSlot = 0;
	DACALSlotNum maxSlot = DACALCommandGetSlotCount(deviceID);

	if (lowestSlot == 0)
		lowestSlot  = 1;        // Unused!  :(
	if ((highestSlot == 0) | (highestSlot > maxSlot))
		highestSlot = maxSlot;
	if (lowestSlot > highestSlot) {
		maxSlot     = lowestSlot;
		lowestSlot  = highestSlot;
		highestSlot = maxSlot;
	}

	DACALResult outResult = kIOReturnBadArgument;
	CFURLRef           outPathURL       = NULL;
	CFStringRef        outPathString    = NULL;
	CFStringRef        doCFCommand      = NULL;
	CFStringRef        outSlotConstName = NULL;
	CFMutableStringRef outSlotName      = NULL;
	CFRange            slotRange;
	DACALCount         indexID          = dacalDeviceRefToDeviceIndex(deviceID);
	CFStringRef        boxUUID          = NULL;

	if (indexID == kDACALIllegalDevice) {
		outResult = kIOReturnNoDevice;
		goto BAIL;
	}

	boxUUID = CFUUIDCreateString(NULL, DACAL_BOX_UUID(indexID));
	if (boxUUID == NULL)
		goto BAIL;

//	doCFCommand = CFStringCreateWithFormat(	gDACALDefaultCFAllocator, NULL, CFSTR("-c %i -s %i -N"), indexID + 1, highestSlot );
	doCFCommand = CFStringCreateWithFormat(gDACALDefaultCFAllocator, NULL, CFSTR("-c %@ -m %i -s %i -N"), boxUUID, lowestSlot, highestSlot);
	if (doCFCommand == NULL)
		goto BAIL;

	outPathString = CFStringCreateFromDacalPipe(gDACALDefaultCFAllocator, doCFCommand, &outResult);
	if (outPathString == NULL)
		goto BAIL;

	outPathURL = CFURLCreateWithFileSystemPath(gDACALDefaultCFAllocator, outPathString, kCFURLPOSIXPathStyle, TRUE);
	if (outPathURL != NULL) {
		outSlotConstName = CFURLCopyLastPathComponent(outPathURL);
		outSlotName      = CFStringCreateMutableCopy(gDACALDefaultCFAllocator, 0, outSlotConstName);
		slotRange        = CFRangeMake(0, 5);
		CFStringDelete(outSlotName, slotRange);
		outSlot = (DACALSlotNum)CFStringGetIntValue(outSlotName);

		CFRelease(outSlotName);
		CFRelease(outSlotConstName);
	}

	BAIL:
			if (outError)
				*outError = outResult;
	if (outPathString)
		CFRelease(outPathString);
	if (doCFCommand)
		CFRelease(doCFCommand);
	if (boxUUID)
		CFRelease(boxUUID);

	return (outSlot);
}

DACALResult
DACALDevicesSetCFAllocator(CFAllocatorRef defaultAlloc) {
	gDACALDefaultCFAllocator = defaultAlloc;
	return (kDACALOK);
}

CFAllocatorRef
DACALDevicesGetCFAllocator(void) {
	return (gDACALDefaultCFAllocator);
}


DACALResult
DACALDevicesSetDefaultDevice(DACALDeviceRef deviceID) {
	DACALCount indexID = dacalDeviceRefToDeviceIndex(deviceID);

	if (indexID == kDACALIllegalDevice)
		return( kIOReturnNoDevice );
	gDACALDefaultDevice = deviceID;
	return (kDACALOK);
}

DACALDeviceRef
DACALDevicesGetDefaultDevice(void) {
	return (gDACALDefaultDevice);
}

DACALCount
DACALDevicesGetCountForModel(CFStringRef aDeviceType) {
	DACALCount actualBoxCount = gDACALBoxes.boxCount;
	DACALCount outBoxCount    = 0;
	DACALCount index;

	if (aDeviceType == NULL)
		return (actualBoxCount);

	for (index = 0; index < actualBoxCount; index++)
		if (DACAL_BOX_MODEL(index)) if (CFStringCompare(DACAL_BOX_MODEL(index), aDeviceType, 0) == 0)
			outBoxCount++;

	return (outBoxCount);
}

DACALSlotNum
DACALDevicesGetSlotCount(CFStringRef aDeviceType) {
	DACALSlotNum badSlotCount   = 0;
	DACALSlotNum dc101SlotCount = 150;
	DACALSlotNum dc300SlotCount = 150;
	DACALSlotNum dc016SlotCount = 100;

	if (aDeviceType == NULL)
		return (badSlotCount);
	if (CFGetTypeID(aDeviceType) != CFStringGetTypeID())
		return (badSlotCount);

	if (CFStringCompare(aDeviceType, dacalDC300, 0))
		return (dc300SlotCount);
	if (CFStringCompare(aDeviceType, dacalDC016RW, 0))
		return (dc016SlotCount);
	if (CFStringCompare(aDeviceType, dacalDC101, 0))
		return (dc101SlotCount);

	return (badSlotCount);
}

DACALCount
DACALDevicesGetCount(void) {
	return (gDACALBoxes.boxCount);
}

DACALDeviceRef
DACALDevicesCopyDeviceRefForIndex(DACALDeviceRef deviceID, DACALResult *outError) {
	DACALDeviceRef outDevice = kDACALNullDevice;
	DACALResult    anyErr;

	outDevice     = (DACALDeviceRef)DACALCommandCopyUUID((DACALDeviceRef)deviceID, &anyErr);
	if (anyErr)
		outDevice = kDACALNullDevice;

	if (outError)
		*outError = anyErr;
	return (outDevice);
}

DACALDeviceRef
DACALDeviceRetain(DACALDeviceRef inDevice) {
	DACALDeviceRef outDevice = inDevice;

	if (inDevice > kDACALIllegalDevice) {
		CFUUIDRef   possibleID   = (CFUUIDRef)inDevice;
		CFStringRef possibleName = (CFStringRef)inDevice;

		if (CFGetTypeID(possibleID) == CFUUIDGetTypeID())                                    // UUID?
			outDevice = (DACALDeviceRef)CFRetain((CFTypeRef)inDevice);

		if (CFGetTypeID(possibleName) == CFStringGetTypeID())                                // Name?
			outDevice = (DACALDeviceRef)CFRetain((CFTypeRef)inDevice);
	}

	return (outDevice);
}

void
DACALDeviceRelease(DACALDeviceRef inDevice) {
	if (inDevice > kDACALIllegalDevice) {
		CFUUIDRef   possibleID   = (CFUUIDRef)inDevice;
		CFStringRef possibleName = (CFStringRef)inDevice;

		if (CFGetTypeID(possibleID) == CFUUIDGetTypeID())                                    // UUID?
			CFRelease((CFTypeRef)inDevice);

		if (CFGetTypeID(possibleName) == CFStringGetTypeID())                                // Name?
			CFRelease((CFTypeRef)inDevice);
	}

}

DACALResult
DACALDeviceInfoSetKey(DACALDeviceRef inDevice, CFStringRef inKeyName, CFTypeRef inKeyValue) {
	return CarouselWriteInfoFileKey(inDevice, inKeyName, inKeyValue);
}

DACALResult
DACALDeviceInfoAddDictionary(DACALDeviceRef inDevice, CFDictionaryRef keyValueDictionary) {
	return CarouselWriteInfoFileWithDictionary(inDevice, keyValueDictionary);
}

CFTypeRef
DACALDeviceInfoCopyKey(DACALDeviceRef deviceID, CFStringRef inKeyName, DACALResult *outResult) {
	return CarouselReadInfoFileKey(deviceID, inKeyName, outResult);
}

CFDictionaryRef
DACALDeviceInfoCopyKeys(DACALDeviceRef deviceID, CFArrayRef inKeyNames, DACALResult *outResult) {
	return CarouselReadInfoFileKeys(deviceID, inKeyNames, outResult);
}

CFArrayRef
DACALDevicesCopyAllNames(void) {
	DACALCount boxIndex = 0;
	DACALCount boxCount = DACALDevicesGetCount();
    CFStringRef boxName;

	if (boxCount == 0)
		return (CFArrayCreate(gDACALDefaultCFAllocator, NULL, 0, &kCFTypeArrayCallBacks));

	CFMutableArrayRef boxArray = CFArrayCreateMutable(gDACALDefaultCFAllocator, boxCount, &kCFTypeArrayCallBacks);

	for (boxIndex = 0; boxIndex < boxCount; boxIndex++) {
		boxName = CFStringCreateCopy(gDACALDefaultCFAllocator, DACAL_BOX_NAME(boxIndex));
        CFArrayAppendValue(boxArray, boxName);
    }

    CFRelease(boxName);
	return (CFArrayRef)(boxArray);
}

DACALResult
DACALDeviceClose(DACALDeviceRef deviceID) {
	io_service_t theDevice;
	DACALIOUSBDeviceInterface **theInterface;

	DACALResult err;
	DACALCount  indexID        = dacalDeviceRefToDeviceIndex(deviceID);
	DACALCount count;
	DACALCount thisRef = 0;

	if (indexID == kDACALIllegalDevice)
		return( kIOReturnNoDevice );
	deviceID = indexID + 1;

	theDevice    = gDACALBoxes.box[indexID].boxDevice;
	theInterface = gDACALBoxes.box[indexID].boxRef;

	err = (*theInterface)->USBDeviceClose(theInterface);
	if (err) {
		if (err != kIOReturnNoDevice ) {
			PMLOGALERT(@"Unable to close device: %08x\n", err);
			return (err);
		}
	}
	(void)(*theInterface)->Release(theInterface);

	IOObjectRelease(theDevice);

	DACALClientNotifyAll((DACALDeviceRef)DACAL_BOX_UUID(indexID), kDACALCarouselNoticeDeviceClose, (CFDictionaryRef)NULL);

	if (DACAL_BOX_NAME(indexID))
		CFRelease(DACAL_BOX_NAME(indexID));
	if (DACAL_BOX_MODEL(indexID))
		CFRelease(DACAL_BOX_MODEL(indexID));
	if (DACAL_BOX_UUID(indexID))
		CFRelease(DACAL_BOX_UUID(indexID));
	if (DACAL_BOX_NOTIFICATION(indexID))
		IOObjectRelease(DACAL_BOX_NOTIFICATION(indexID));

	//gDACALBoxes.boxCount--;
	thisRef = gDACALBoxes.boxCount--;
	DACAL_BOX_DEVICE(indexID) = 0;
	DACAL_BOX_REF(indexID) = NULL;
	DACAL_BOX_BUSY(indexID) = FALSE;
	DACAL_BOX_NAME(indexID) = NULL;
	DACAL_BOX_MODEL(indexID) = NULL;
	DACAL_BOX_UUID(indexID) = NULL;
	DACAL_BOX_NOTIFICATION(indexID) = (io_object_t)NULL;

	if (gDACALDefaultDevice == deviceID)
		gDACALDefaultDevice = 1;                // If we just closed the default device, reset it to box 1.

	if (thisRef > deviceID)
		for (count = indexID; count <= deviceID; count++) {
			gDACALBoxes.box[count].boxDevice       = gDACALBoxes.box[count + 1].boxDevice;
			gDACALBoxes.box[count].boxRef          = gDACALBoxes.box[count + 1].boxRef;
			gDACALBoxes.box[count].isBusy          = gDACALBoxes.box[count + 1].isBusy;
			gDACALBoxes.box[count].boxName         = gDACALBoxes.box[count + 1].boxName;
			gDACALBoxes.box[count].boxModel        = gDACALBoxes.box[count + 1].boxModel;
			gDACALBoxes.box[count].boxUUID         = gDACALBoxes.box[count + 1].boxUUID;
			gDACALBoxes.box[count].boxNotification = gDACALBoxes.box[count + 1].boxNotification;
		}

	return (err);
}

void
DACALDeviceNotification(void *refCon, io_service_t service, natural_t messageType, void *messageArgument) {
	DACALDeviceRef theDevice = (DACALDeviceRef)refCon;

	PMLOGINFO(@"Device:%i Message:%i",(int)theDevice, messageType);

	switch (messageType) {
		case kIOMessageServiceIsTerminated:
	        DACALDeviceClose(theDevice);
	        break;
		default:
	        break;
	}

}

DACALIOUSBDeviceInterface **
getUSBDevice(io_object_t usbDevice) {
	IOReturn err;
	IOCFPlugInInterface       **plugInInterface = NULL;
	DACALIOUSBDeviceInterface **dev             = NULL;
	SInt32  score;
	HRESULT res;

	// There is no documentation for IOCreatePlugInInterfaceForService or QueryInterface, you have to use sample code.

	err = IOCreatePlugInInterfaceForService(
			usbDevice,
			kIOUSBDeviceUserClientTypeID,
			kIOCFPlugInInterfaceID,
			&plugInInterface,
			&score
	                                       );
	if ((kIOReturnSuccess != err) || (plugInInterface == nil)) {
		PMLOGALERT(@"Unable to create plug in interface for USB device: %d", err);
		return (nil);
	}

	res = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID245), (LPVOID)&dev);
	IODestroyPlugInInterface(plugInInterface);            // done with this

	if (res || !dev) {
        PMLOGEMERG(@"Unable to create USB device with QueryInterface error: %i\n", stderr);
		return (nil);
	}

	if (gDebugLevel > 1) {
		UInt16 VID, PID, REL;
		err = (*dev)->GetDeviceVendor(dev, &VID);
		err = (*dev)->GetDeviceProduct(dev, &PID);
		err = (*dev)->GetDeviceReleaseNumber(dev, &REL);
		PMLOGINFO(@"Found device VID 0x%04X (%d), PID 0x%04X (%d), release %d\n", VID, VID, PID, PID, REL);
	}

	return (dev);
}

UInt8
openUSBDevice(DACALIOUSBDeviceInterface **dev) {
	UInt8                           numConfig;
	IOReturn                        err;
	IOUSBConfigurationDescriptorPtr desc;

	err = (*dev)->GetNumberOfConfigurations(dev, &numConfig);
	if (err != kIOReturnSuccess) {
		PMLOGEMERG(@"Could not number of configurations from device - err: %d", err);
		return (UInt8)(-1);
	}
	if (numConfig != 1) {
		PMLOGEMERG(@"This does not look like the right device, it has %d configurations (we want 1)\n", numConfig);
		return (UInt8)(-1);
	}

	err = (*dev)->GetConfigurationDescriptorPtr(dev, 0, &desc);
	if (err != kIOReturnSuccess) {
		PMLOGEMERG(@"Could not get configuration descriptor from device - err: %d", err);
		return (UInt8)(-1);
	}

	PMLOG(PMLogLevelDebug2, @"Configuration value is %d\n", desc->bConfigurationValue);

	// We should really try to do classic arbitration here

	err = (*dev)->USBDeviceOpen(dev);
	if (err == kIOReturnExclusiveAccess) {
		PMLOGEMERG(@"Exclusive error opening device, we may come back to this later\n");
		return (UInt8)(-2);
	}
	if (err != kIOReturnSuccess) {
		PMLOGEMERG(@"Could not open device - err: %d", err);
		return (UInt8)(-1);
	}


	return (desc->bConfigurationValue);
}

UInt8
openUSBInterface(DACALIOUSBInterfaceInterface **intf) {
	IOReturn ret;

	UInt8  n;
	int    i;
	UInt8  direction;
	UInt8  number;
	UInt8  transferType;
	UInt16 maxPacketSize;
	UInt8  interval;
	static char *types[]        = {
			"Control",
			"Isochronous",
			"Bulk",
			"Interrupt"
	};
	static char *directionStr[] = {
			"Out",
			"In",
			"Control"
	};

	ret = (*intf)->USBInterfaceOpen(intf);
	if (ret != kIOReturnSuccess) {
		PMLOGEMERG(@"Could not set configuration on device");
		return (UInt8)(-1);
	}

	ret = (*intf)->GetNumEndpoints(intf, &n);
	if (ret != kIOReturnSuccess) {
		PMLOGEMERG(@"Could not get number of endpoints in interface");
		return (0);
	}

	PMLOG(PMLogLevelDebug2, @"%d endpoints found\n", n);

	for (i = 1; i <= n; i++) {
		ret = (*intf)->GetPipeProperties(intf, i, &direction, &number, &transferType, &maxPacketSize, &interval);
		if (ret != kIOReturnSuccess) {
			PMLOGEMERG(@"Endpoint %d -", n);
			PMLOGEMERG(@"Could not get endpoint properties");
			return (0);
		}
		PMLOG(PMLogLevelDebug2, @"Endpoint %d: %s %s %d, max packet %d, interval %d\n", i, types[transferType], directionStr[direction], number, maxPacketSize, interval);
	}

	return (0);
}

DACALIOUSBInterfaceInterface **
getUSBInterfaceInterface(io_service_t usbInterface) {
	IOReturn err;
	IOCFPlugInInterface          **plugInInterface = NULL;
	DACALIOUSBInterfaceInterface **intf            = NULL;
	SInt32  score;
	HRESULT res;

	// There is no documentation for IOCreatePlugInInterfaceForService or QueryInterface, you have to use sample code.

	err = IOCreatePlugInInterfaceForService(
			usbInterface,
			kIOUSBInterfaceUserClientTypeID,
			kIOCFPlugInInterfaceID,
			&plugInInterface,
			&score
	                                       );
	(void)IOObjectRelease(usbInterface);                // done with the usbInterface object now that I have the plugin
	if ((kIOReturnSuccess != err) || (plugInInterface == nil)) {
		PMLOGEMERG(@"Unable to create plug in interface for USB interface");
		return (nil);
	}

	res = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID300), (LPVOID)&intf);
	IODestroyPlugInInterface(plugInInterface);            // done with this

	if (res || !intf) {
		PMLOGEMERG(@"Unable to create interface with QueryInterface %X\n", (unsigned int)res);
		return (nil);
	}
	return (intf);
}

Boolean
isThisTheInterfaceYoureLookingFor(DACALIOUSBInterfaceInterface **intf) {
	//	Check to see if this is the interface you're interested in
	//  This code is only expecting one interface, so returns true
	//  the first time.
	//  You code could check the nature and type of endpoints etc

	static Boolean foundOnce = false;
	if (foundOnce) {
		PMLOGNOTICE(@"Subsequent interface found, we're only intersted in 1 of them\n");
		return (false);
	}
	foundOnce = true;
	return (true);
}

void
useUSBInterface(DACALIOUSBInterfaceInterface **intf) {
	IOReturn ret;
	UInt8    intfNumber;
	ret = (*intf)->GetInterfaceNumber(intf, &intfNumber);
	PMLOGNOTICE(@"InterfaceNumber: %d", intfNumber);
}

int
iterateinterfaces(io_iterator_t interfaceIterator) {
	io_service_t usbInterface;
	int          err   = 0;
	int          count = 0;
	IOReturn     ret;
	DACALIOUSBInterfaceInterface **intf = NULL;

	usbInterface = IOIteratorNext(interfaceIterator);
	if (usbInterface == IO_OBJECT_NULL) {
		PMLOGEMERG(@"Unable to find an Interface\n");
		return (-1);
	}

	while (usbInterface != IO_OBJECT_NULL) {
		intf         = getUSBInterfaceInterface(usbInterface);

		if (intf != nil) {
			// Don't release the interface here. That's one too many releases and causes set alt interface to fail
			count += 1;
			if (isThisTheInterfaceYoureLookingFor(intf)) {
				err = openUSBInterface(intf);
				if (err == 0) {
					useUSBInterface(intf);
					ret = (*intf)->USBInterfaceClose(intf);
				}

				ret = (*intf)->Release(intf);
				// Not worth bothering with errors here
				return (err);
			}
		}
		usbInterface = IOIteratorNext(interfaceIterator);
	}

	PMLOGEMERG(@"No interesting interfaces found\n");
	IOObjectRelease(usbInterface);
	return (-1);
}

void
useUSBDevice(DACALIOUSBDeviceInterface **dev, UInt8 configuration) {
	io_iterator_t             interfaceIterator;
	IOUSBFindInterfaceRequest req;
	IOReturn                  err;
	dacalString               ourResult;

	err = (*dev)->SetConfiguration(dev, configuration);
	if (err != kIOReturnSuccess) {
		PMLOGEMERG(@"Could not set configuration on device - err: &d", err);
		return;
	}

	req.bInterfaceClass    = kIOUSBFindInterfaceDontCare;
	req.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
	req.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
	req.bAlternateSetting  = kIOUSBFindInterfaceDontCare;

	err = (*dev)->CreateInterfaceIterator(dev, &req, &interfaceIterator);
	if (err != kIOReturnSuccess) {
		PMLOGEMERG(@"Could not create interface iterator - err: %d", err);
		return;
	}

/*	undocManufacturer = 1,
	undocSoftware = 2,
	undocUnknown3,
	undocUnknown4,
	undocUnknown5,
	undocUnknown6,
	undocUnknown7,
	undocUnknown8,
	cmdGetModel,	// 9
	cmdGetUUID,		// 10
	cmdReset,		// 11
	cmdMoveToSlot,	// 12
	cmdReserved1,	// 13
	cmdCloseDoor,	// 14
	cmdLEDOn,		// 15
	cmdLEDOff,		// 16
	cmdGetStatus,	// 17
	cmdGetSlot,		// 18
	cmdMoveToDVD,	// 19
	cmdEjectDVD,	// 20
	
    err = iterateinterfaces(interfaceIterator);
	err = dacalDoRequest(dev, undocManufacturer, &ourResult);
	err = dacalDoRequest(dev, undocSoftware, &ourResult);
	err = dacalDoRequest(dev, 3, &ourResult);
	err = dacalDoRequest(dev, 4, &ourResult);
	err = dacalDoRequest(dev, 5, &ourResult);
	err = dacalDoRequest(dev, 6, &ourResult);
	err = dacalDoRequest(dev, 7, &ourResult);
	err = dacalDoRequest(dev, 8, &ourResult);
	err = dacalDoRequest(dev, cmdGetModel, &ourResult);
	err = dacalDoRequest(dev, cmdGetUUID, &ourResult);
	err = dacalDoRequest(dev, cmdReset, &ourResult);
	err = dacalDoRequest(dev, cmdMoveToSlot, &ourResult);
	err = dacalDoRequest(dev, 50, &ourResult);
	err = dacalDoRequest(dev, cmdReserved1, &ourResult);
	err = dacalDoRequest(dev, cmdCloseDoor, &ourResult);
	err = dacalDoRequest(dev, cmdLEDOn, &ourResult);
	err = dacalDoRequest(dev, cmdLEDOff, &ourResult);
	err = dacalDoRequest(dev, cmdGetStatus, &ourResult);
	err = dacalDoRequest(dev, cmdGetSlot, &ourResult);
	err = dacalDoRequest(dev, cmdMoveToDVD, &ourResult);
	err = dacalDoRequest(dev, cmdEjectDVD, &ourResult);
 */

	IOObjectRelease(interfaceIterator);
}

DACALDeviceRef
DACALDeviceCreateWithService(io_service_t ioDeviceObj, DACALResult *outErr) {
	DACALResult err;
	vm_offset_t thisRef                       = 0;
	IOCFPlugInInterface          **ioPlugin;
	DACALIOUSBDeviceInterface    **deviceIntf = NULL;
	DACALIOUSBInterfaceInterface **intfIntf   = NULL;

	SInt32             score;
	CFUUIDRef          newID;
	CFStringRef        newModel;
//	CFStringRef					newName;
//	CFStringRef					userName;
	DACALDeviceRefNode newNode;
//	DACALDeviceRef				originalDefault = DACALDevicesGetDefaultDevice();
	UInt8              intfNumEndpoints;
	UInt8 config = 0;

	deviceIntf = getUSBDevice(ioDeviceObj);
    if (deviceIntf) {
        config     = openUSBDevice(deviceIntf);
        if (config > 0)
            useUSBDevice(deviceIntf, config);
        else {
			PMLOGEMERG(@"ERROR: Zero configuration\n");
            goto BAIL;
        }
        err = (*deviceIntf)->USBDeviceClose(deviceIntf);
        err = (*deviceIntf)->Release(deviceIntf);
        
        err = IOCreatePlugInInterfaceForService(ioDeviceObj, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &ioPlugin, &score);
        if (err || !ioPlugin) {
            IOObjectRelease(ioDeviceObj);
            PMLOGEMERG(@"unable to create plugin. ret = %08x, iodev = %p\n", err, ioPlugin);
            if (outErr != NULL)
                *outErr = err;
            return (thisRef);
        }
        err = (*ioPlugin)->QueryInterface(ioPlugin, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID), (LPVOID)&deviceIntf);
        IODestroyPlugInInterface(ioPlugin);        // done with this
        ioPlugin = NULL;
        
        if (err || !deviceIntf) {
            PMLOGEMERG(@"unable to create a device interface. ret = %08x, dev = %p\n", err, ioPlugin);
            if (outErr != NULL)
                *outErr = err;
            return (thisRef);
        }
        
        err = (*deviceIntf)->USBDeviceOpen(deviceIntf);
        if (err) {
            PMLOGEMERG(@"Unable to open device: %08x\n", err);
            (void)(*deviceIntf)->Release(deviceIntf);
            if (outErr != NULL)
                *outErr = err;
            return (thisRef);
        }
        
        UInt16 devVendor;
        UInt16 devProduct;
        UInt8  intfNumber;
        
        (*deviceIntf)->GetDeviceVendor(deviceIntf, &devVendor);
        (*deviceIntf)->GetDeviceProduct(deviceIntf, &devProduct);
        
        PMLOGINFO(@"Found device vendor:%x product:%x\n", devVendor, devProduct);
        
        thisRef = gDACALBoxes.boxCount++;
        newNode = thisRef + 1;
        
        DACAL_BOX_DEVICE(thisRef) = ioDeviceObj;
        DACAL_BOX_REF(thisRef) = deviceIntf;
        DACAL_BOX_BUSY(thisRef) = FALSE;
        DACAL_BOX_UUID(thisRef) = NULL;
        DACAL_BOX_MODEL(thisRef) = NULL;
        DACAL_BOX_LASTSLOT(thisRef) = 0;
        DACAL_BOX_LASTSLOTTIME(thisRef) = -1;
        //	DACAL_BOX_NODE(thisRef)			= index+1;
        UInt8  direction, number, transferType, interval;
        UInt16 maxPacketSize;
        //	err = (*deviceIntf)->GetNumEndpoints(deviceIntf, &intfNumEndpoints);
        //	err = (*deviceIntf)->GetPipeProperties(deviceIntf, 1, &direction, &number, &transferType, &maxPacketSize, &interval);
        
        newModel = DACALCommandCopyModel(newNode, NULL);
        newID    = DACALCommandCopyUUID(newNode, NULL);
        if (newID == NULL) {
            sleep(1);
            
            newID = DACALCommandCopyUUID(newNode, NULL);
            
            if (newID == NULL) {
                err = kDACALError;
                PMLOGEMERG(@"Could Not Identify Device %p\n", (void *)ioDeviceObj);
                if (outErr != NULL)
                    *outErr = err;
                return (thisRef);
            }
        }
        
        if (newModel == NULL) {
            sleep(1);
            
            newModel = DACALCommandCopyModel(newNode, NULL);
            
            if (newModel == NULL) {
                err = kDACALError;
                PMLOGALERT(@"Could Not Identify Model %p\n", (void *)ioDeviceObj);
                if (outErr != NULL)
                    *outErr = err;
                return (thisRef);
            }
        }
        
        CFComparisonResult modelDC300Check = CFStringCompare(newModel, CFSTR("DC-300"), 0);
        CFComparisonResult modelDC101Check = CFStringCompare(newModel, CFSTR("DC-101"), 0);
        CFComparisonResult modelDC016Check = CFStringCompare(newModel, CFSTR("DC-016RW"), 0);
        if (modelDC300Check == 0 | modelDC101Check == 0 | modelDC016Check == 0) {
            err = CarouselEstablishInfoFile(newID);
            CFRelease(newID);
            CFRelease(newModel);
            if (err) {
                PMLOGEMERG(@"unable to create a device file. ret = %i, dev = %p\n", err, (void *)ioDeviceObj);
                if (outErr != NULL)
                    *outErr = err;
                return (thisRef);
            }
        }
        else {
            PMLOGEMERG(@"unknown device: %@ ,unable to create a device file. ret = %i, dev = %p\n", newModel, err, (void *)ioDeviceObj);
            CFRelease(newID);
            CFRelease(newModel);
            if (outErr != NULL)
                *outErr = err;
            return (thisRef);
        }
        
        err = IOServiceAddInterestNotification(gDACALNotifyPort, ioDeviceObj, kIOGeneralInterest, DACALDeviceNotification, (void *)newID, &(DACAL_BOX_NOTIFICATION(thisRef)));
        
        DACALClientNotifyAll((DACALDeviceRef)newID, kDACALCarouselNoticeDeviceOpen, (CFDictionaryRef)NULL);
        
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
    }

	if (outErr != NULL)
		*outErr = err;
    BAIL:
	return (thisRef);
}

void
DACALDevicesAdded(void *refCon, io_iterator_t iterator) {
	io_service_t aCarousel;

	while ((aCarousel = IOIteratorNext(iterator)))
		DACALDeviceCreateWithService(aCarousel, NULL);
}

DACALResult
DACALDevicesFinalize(void) {
	DACALResult closeErr, outErr = 0;
	DACALCount  index, count     = gDACALBoxes.boxCount;

	if (count == 0)
		return (outErr);

	for (index = count; index > 0; index--) {
		closeErr   = DACALDeviceClose((DACALDeviceRef)DACAL_BOX_UUID(index - 1));
		if (outErr == 0)
			outErr = closeErr;
	}

	return (outErr);
}

DACALResult
DACALDevicesInitialize(void) {
	DACALResult            err;
	CFMutableDictionaryRef matchingDictionary = 0;
	CFNumberRef            numberRef;

	mach_port_t masterPort = 0;                // requires <mach/mach.h>

//    io_iterator_t			devIter = 0;
//    io_service_t			ioDeviceObj;

	// Find USB Interface
	err = IOMasterPort(MACH_PORT_NULL, &masterPort);
	if (err) {
		PMLOGEMERG(@"could not create master port, err = %08x\n", err);
		return err;
	}
	// Looking for USBD device
	matchingDictionary = IOServiceMatching(kIOUSBDeviceClassName);    // requires <IOKit/usb/IOUSBLib.h>
	// Specifiy vendor, product and revision
	if (!matchingDictionary) {
		PMLOGALERT(@"could not create matching dictionary\n");
		return kIOReturnNoDevice;
	}

	// Setup vendorID
	numberRef = CFNumberCreate(gDACALDefaultCFAllocator, kCFNumberSInt32Type, &kDACALVendorID);
	if (!numberRef) {
		CFRelease(matchingDictionary);
		CFRelease(numberRef);
		PMLOGEMERG(@"could not create CFNumberRef for vendor\n");
		return kIOReturnNoMemory;
	}
	CFDictionaryAddValue(matchingDictionary, CFSTR(kUSBVendorID), numberRef);
	CFRelease(numberRef);
	numberRef = 0;

	// Setup productID
	numberRef = CFNumberCreate(gDACALDefaultCFAllocator, kCFNumberSInt32Type, &kDACALProductID);
	if (numberRef == NULL) {
		CFRelease(matchingDictionary);
		CFRelease(numberRef);
		PMLOGEMERG(@"could not create CFNumberRef for product\n");
		return kIOReturnNoMemory;
	}
	CFDictionaryAddValue(matchingDictionary, CFSTR(kUSBProductID), numberRef);
	CFRelease(numberRef);
	numberRef = 0;

	// Setup bRelease
	//	numberRef = CFNumberCreate(gDACALDefaultCFAllocator, kCFNumberSInt32Type, &kDACALReleaseID);
	//	if (!numberRef) {
	//		if( pmCFUtilityVerbose )
	//				printf("could not create CFNumberRef for product\n");
	//		return kIOReturnNoMemory;
	//	}
	//	CFDictionaryAddValue(matchingDictionary, CFSTR(kUSBDeviceReleaseNumber), numberRef);
	//	CFRelease(numberRef);
	//	numberRef = 0;

	// err = IOServiceGetMatchingServices(masterPort, matchingDictionary, &devIter);
	// matchingDictionary = 0;			// this was consumed by the above call

	gDACALNotifyPort    = IONotificationPortCreate(masterPort);
	gDACALRunLoopSource = IONotificationPortGetRunLoopSource(gDACALNotifyPort);

	CFRunLoopAddSource(CFRunLoopGetCurrent(), gDACALRunLoopSource, kCFRunLoopDefaultMode);

	//while ( (ioDeviceObj = IOIteratorNext(devIter)) )
	//	DACALDeviceCreateWithService( ioDeviceObj, NULL );

	err = IOServiceAddMatchingNotification(gDACALNotifyPort, kIOFirstMatchNotification, matchingDictionary, DACALDevicesAdded, NULL, &gDACALAddedIter);
	if (err)
        PMLOGEMERG(@"IOServiceAddMatchingNotification returned err: %x", err);

	DACALDevicesAdded(NULL, gDACALAddedIter);

	//IOObjectRelease(devIter);
	//devIter = 0;

	mach_port_deallocate(mach_task_self(), masterPort);            // Don't do this in the future so we can get hot plugs.
	masterPort = 0;

	return kIOReturnSuccess;
}

DACALClientRef
DACALClientGetIndexForID(CFStringRef aClient) {
	DACALClientRef index, count = (DACALClientRef)gDACALClients.clientCount;
	for (index = 1; index <= count; index++)
		if (CFEqual(DACAL_CLIENT_IDENTIFIER(index), aClient))
			return index;

	return 0;
}

void
DACALClientNotify(
		CFStringRef noticeClient, DACALDeviceRef noticeDevice, CFStringRef noticeMessage,
		CFDictionaryRef noticeData
                 ) {
	DACALClientRef clientIndex = DACALClientGetIndexForID(noticeClient);
	DACALClientNotificationCallback *userCallback = DACAL_CLIENT_CALLBACK(clientIndex);

	PMLOGDEBUG(@"DACALClientNotify: Device: %i Message: %@", (int)noticeDevice, noticeMessage );

	if (userCallback != NULL)
		userCallback(DACAL_CLIENT_USERDATA(clientIndex), noticeDevice, noticeMessage, noticeData);
}

void
DACALClientNotifyAll(DACALDeviceRef noticeDevice, CFStringRef noticeMessage, CFDictionaryRef noticeData) {
	DACALClientRef index, count = (DACALClientRef)gDACALClients.clientCount;
	for (index = 1; index <= count; index++)
		DACALClientNotify(DACAL_CLIENT_IDENTIFIER(index), noticeDevice, noticeMessage, noticeData);
}

OSErr
DACALCreateLibraryFolder(FSRef *libraryFolder) {
	OSErr ffErr;

	DACALDevicesSetCFAllocator(kCFAllocatorDefault);            // initialize with default allocator

	{
		// this is a workaround because AddFolderDescriptor
		// creates a folder with silly permissions

			ffErr = FSFindFolder(kUserDomain, kDomainLibraryFolderType, FALSE, libraryFolder);
			if (ffErr)
				fprintf(stderr, "No Local Library?");
        
            FSRef appSupportFolder;
            ffErr = FSFindFolder(kUserDomain, kApplicationSupportFolderType, FALSE, &appSupportFolder);
            if (ffErr)
                fprintf(stderr, "No Local Application Support?");

			CFURLRef      appSupportURL = CFURLCreateFromFSRef(kCFAllocatorDefault, &appSupportFolder);
			CFURLRef      appSuportPadURL = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, appSupportURL, PAD_FOLDERNAME_CFSTRING, TRUE);
            CFURLRef      libraryURL = CFURLCreateFromFSRef(kCFAllocatorDefault, libraryFolder);
            CFURLRef      libraryPadURL = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, libraryURL, PAD_FOLDERNAME_CFSTRING, TRUE);
			FSRef         appSupportPadFS, libraryPadFS;
        
			FSCatalogInfo permCatInfo;
			FSPermissionInfo *permInfo = (FSPermissionInfo *)&permCatInfo.permissions;

            Boolean foundAppSupportPAD    = CFURLGetFSRef(appSuportPadURL, &appSupportPadFS);
            Boolean foundLibraryPAD    = CFURLGetFSRef(libraryPadURL, &libraryPadFS);
        
			CFIndex theUniCount = CFStringGetLength(PAD_FOLDERNAME_CFSTRING);
			UniChar theUniName[1024];

			if (foundAppSupportPAD == FALSE) {
                if (foundLibraryPAD == TRUE) {
                    // Copy libraryPAD to appSupportPAD
                    CFStringRef libraryPADPath = CFURLCopyFileSystemPath(libraryPadURL, kCFURLPOSIXPathStyle);
                    CFStringRef appSupportPADPath = CFURLCopyFileSystemPath(appSupportURL, kCFURLPOSIXPathStyle);
                    CFTimeInterval  statusInterval = 1.0;
                    CFStringRef contextString = NULL;
                    Boolean async = false;

                    OptionBits	options = kFSFileOperationDefaultOptions;
                    
                    long int sourcePathLen = CFStringGetLength(libraryPADPath);
                    char *sourcePath = malloc(2048);
                    CFStringGetCString(libraryPADPath, sourcePath, 2048, kCFStringEncodingUTF8);

                    long int destPathLen = CFStringGetLength(appSupportPADPath);
                    char *destPath = malloc(2048);
                    CFStringGetCString(appSupportPADPath, destPath, 2048, kCFStringEncodingUTF8);

                    long int destNameLen = CFStringGetLength(PAD_FOLDERNAME_CFSTRING);
                    char *destName = malloc(2048);
                    CFStringGetCString(PAD_FOLDERNAME_CFSTRING, destName, 2048, kCFStringEncodingUTF8);

	                OSStatus ok = OperateByPath(false, sourcePath, destPath, NULL, statusInterval, options, async, contextString);
                } else { // Create new appSupportPAD
                    permInfo->mode = 0755;                        // drwxr-xr-x
                    CFStringGetCharacters(PAD_FOLDERNAME_CFSTRING, CFRangeMake(0, theUniCount), theUniName);

                    ffErr = FSCreateDirectoryUnicode(&appSupportFolder, (UniCharCount)theUniCount, (const UniChar *)theUniName, kFSCatInfoPermissions, &permCatInfo, &appSupportPadFS, NULL, NULL);
                    if (ffErr)
                        fprintf(stderr, "FSCreateDirectoryUnicode: %i\n", ffErr);
                }
            }
            
            libraryFolder = &appSupportFolder;

        // setup a system folder descriptor to make finding the Carousel folder easy
		ffErr = AddFolderDescriptor(
                            kDACALCarouselsFolderType, kFolderInLocalOrRemoteUserFolder,
                            kRelativeFolder, kApplicationSupportFolderType, 0, 0,
                            (ConstStrFileNameParam)PAD_FOLDERNAME_PSTRING, TRUE
                            );
        
		ffErr = FSFindFolder(kUserDomain, kDACALCarouselsFolderType, TRUE, libraryFolder);

        if (appSupportURL != NULL)
            CFRelease(appSupportURL);
        if (appSuportPadURL != NULL)
            CFRelease(appSuportPadURL);
        if (libraryURL != NULL)
            CFRelease(libraryURL);
        if (libraryPadURL != NULL)
            CFRelease(libraryPadURL);
		}
	return ffErr;
}

DACALResult
DACALClientCreate(CFStringRef clientID, void *useDataRef, void *useCallback) {
	DACALClientRef ourClientRef = gDACALNextClientID++;
	DACALResult    outError     = kDACALError;

	if (ourClientRef > DACAL_MAXCLIENT_COUNT) {
		ourClientRef = 0;
		goto BAIL;
	}

	if (clientID)
		CFRetain(clientID);

	DACAL_CLIENT_IDENTIFIER(ourClientRef) = clientID;
	DACAL_CLIENT_CALLBACK(ourClientRef) = useCallback;
	DACAL_CLIENT_USERDATA(ourClientRef) = useDataRef;
	DACAL_CLIENT_ALLOCATOR(ourClientRef) = kCFAllocatorDefault;

	gDACALClients.clientCount = ourClientRef;
	outError = kDACALOK;

	if (ourClientRef == 1) {
		FSRef topFolder;
		OSErr ffErr;

		gDACALBoxes.boxCount = 0;                            // start fresh

		ffErr = DACALCreateLibraryFolder(&topFolder);

	}


	BAIL:
			return (outError);
}

void
DACALClientRelease(CFStringRef clientID) {
	DACALClientRef clientIndex = DACALClientGetIndexForID(clientID);
	DACALClientRef clientCount = gDACALClients.clientCount;
	DACALClientRef index;

	if (clientIndex) {
		if (DACAL_CLIENT_IDENTIFIER(clientIndex))
			CFRelease(DACAL_CLIENT_IDENTIFIER(clientIndex));
		if (DACAL_CLIENT_ALLOCATOR(clientIndex))
			CFRelease(DACAL_CLIENT_ALLOCATOR(clientIndex));

		DACAL_CLIENT_IDENTIFIER(clientIndex) = NULL;
		DACAL_CLIENT_ALLOCATOR(clientIndex) = NULL;
		DACAL_CLIENT_USERDATA(clientIndex) = NULL;
		DACAL_CLIENT_CALLBACK(clientIndex) = NULL;

		if (clientIndex < clientCount) {
			for (index = clientIndex; index < clientCount; index++) {
				DACAL_CLIENT_IDENTIFIER(index) = DACAL_CLIENT_IDENTIFIER(index + 1);
				DACAL_CLIENT_ALLOCATOR(index) = DACAL_CLIENT_ALLOCATOR(index + 1);
				DACAL_CLIENT_USERDATA(index) = DACAL_CLIENT_USERDATA(index + 1);
				DACAL_CLIENT_CALLBACK(index) = DACAL_CLIENT_CALLBACK(index + 1);
			}
		}

		clientCount--;
		gDACALClients.clientCount = clientCount;
	}

	if (clientCount == 0)
		DACALDevicesFinalize();
}

