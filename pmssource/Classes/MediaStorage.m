//
//  MediaStorage.m
//  DACALTester
//
//  Created by Dave Carlton on 02/16/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import "MediaStorage.h"
#import "MediaDevice.h"

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <paths.h>
#include <sys/param.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/IOBSD.h>
#include <IOKit/storage/IOMediaBSDClient.h>
#include <IOKit/storage/IOMedia.h>
#include <IOKit/storage/IOCDMedia.h>
#include <IOKit/storage/IOCDTypes.h>
#include <CoreFoundation/CoreFoundation.h>

#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOKitKeys.h>
#import <IOKit/storage/IOStorageDeviceCharacteristics.h>
#import <IOKit/scsi/SCSITaskLib.h>
#import <IOKit/scsi/IOSCSIMultimediaCommandsDevice.h>

static void AppearedNotificationHandler(void * refCon, io_iterator_t iterator);

static void DisappearedNotificationHandler(void * refCon, io_iterator_t iterator);

@implementation MediaStorage

@synthesize theDeviceList;
@synthesize deviceNotifyPort;
@synthesize deviceAppearedIterator;
@synthesize deviceDisappearedIterator;

-(id)init
{
	[super init];

	// Create the mutable array which represents our list of
	// devices
	[self setTheDeviceList: [NSMutableArray arrayWithCapacity: 0]];

	// Register ourself for callbacks when the devices we want
	// to know about come online/leave
	[self registerDeviceCallbackHandler];

//	kern_return_t	kernResult; // on PowerPC this is an int (4 bytes)
//	/*
//	 *	error number layout as follows (see mach/error.h):
//	 *
//	 *	hi		               lo
//	 *	| system(6) | subsystem(12) | code(14) |
//	 */
//
//    io_iterator_t	mediaIterator;
//    char			bsdPath[ MAXPATHLEN ];
//
//    kernResult = [self FindEjectableCDMedia: &mediaIterator];
//
//    kernResult = [self GetBSDPath: mediaIterator: bsdPath: sizeof(bsdPath)];
//
//    // Now open the device we found, read a sector, and close the device
//    if (bsdPath[0] != '\0') {
//        int fileDescriptor;
//
//        fileDescriptor = [self OpenDrive: bsdPath];
//
//        if ( [self ReadSector: fileDescriptor]) {
//            printf("Sector read successfully.\n");
//        }
//        else {
//            printf("Could not read sector.\n");
//        }
//
//        [self CloseDrive: fileDescriptor];
//        printf("Device closed.\n");
//    }
//    else {
//        printf("No ejectable CD media found.\n");
//    }
//
//    // Release the iterator.
//    if (mediaIterator) {
//        IOObjectRelease(mediaIterator);
//		mediaIterator = IO_OBJECT_NULL; // prevent us from inadvertently using the stale iterator later on
//    }
	return self;
} // init

//
//	registerDeviceCallbackHandler - Registers this object to get called back
//									when certain devices come online.
//

-(void) registerDeviceCallbackHandler
{
	IOReturn               kernErr;
	CFRunLoopSourceRef     runLoopSource;
	CFMutableDictionaryRef matchingDict;
	CFMutableDictionaryRef subDict;
	CFRunLoopRef           runLoop;

	// Create the dictionaries
	matchingDict = CFDictionaryCreateMutable(kCFAllocatorDefault,
		0,
		&kCFTypeDictionaryKeyCallBacks,
		&kCFTypeDictionaryValueCallBacks);

	subDict = CFDictionaryCreateMutable(kCFAllocatorDefault,
		0,
		&kCFTypeDictionaryKeyCallBacks,
		&kCFTypeDictionaryValueCallBacks);

	//
	//	Note: We are setting up a matching dictionary which looks like the following:
	//
	//	<dict>
	//		<key>IOPropertyMatch</key>
	//		<dict>
	//			<key>SCSITaskDeviceCategory</key>
	//			<string>SCSITaskAuthoringDevice</string>
	//		</dict>
	// </dict>
	//

	// Create the port on which we will receive notifications. We'll wrap it in a runLoopSource
	// which we then feed into the runLoop for async event notifications.
	deviceNotifyPort = IONotificationPortCreate(kIOMasterPortDefault);
	if (deviceNotifyPort == NULL) {
		return;
	}

	// Get a runLoopSource for our mach port.
	runLoopSource = IONotificationPortGetRunLoopSource(deviceNotifyPort);

	// Create a dictionary with the SCSITaskDeviceCategory key = SCSITaskAuthoringDevice
	CFDictionarySetValue( subDict,
		CFSTR(kIOPropertySCSITaskDeviceCategory),
		CFSTR(kIOPropertySCSITaskAuthoringDevice) );

	// This shows you how to fine-tune the matching.

#if FILTER_DVD_DRIVES_ONLY

	// Insert the device-type key = DVD
	// Insert the device-type key = DVD
	CFDictionarySetValue( subDict,
		CFSTR("device-type"),
		CFSTR("DVD") );

#endif /* FILTER_DVD_DRIVES_ONLY */

	// Add the dictionary to the main dictionary with the key IOPropertyMatch to
	// narrow the search to the above dictionary.
	CFDictionarySetValue(matchingDict,
		CFSTR(kIOPropertyMatchKey),
		subDict);

	// Retain a reference since we arm both the appearance and disappearance notifications
	// and the call to IOServiceAddMatchingNotification() consumes a reference each time.
	matchingDict = (CFMutableDictionaryRef)CFRetain(matchingDict);

	kernErr = IOServiceAddMatchingNotification(deviceNotifyPort,
		kIOFirstMatchNotification,
		matchingDict,
		AppearedNotificationHandler,
		(void *)self,
		&deviceAppearedIterator);

	// Since we got back an iterator already from this routine, we call the handler to immediately
	// dispatch any devices there already
	AppearedNotificationHandler( (void *)self, deviceAppearedIterator );

	kernErr = IOServiceAddMatchingNotification(deviceNotifyPort,
		kIOTerminatedNotification,
		matchingDict,
		DisappearedNotificationHandler,
		(void *)self,
		&deviceDisappearedIterator);

	// Since we got back an iterator already from this routine, we call the handler to immediately
	// dispatch any devices removed already
	DisappearedNotificationHandler( (void *)self, deviceDisappearedIterator );

	// Get our runLoop
	runLoop = [[NSRunLoop currentRunLoop] getCFRunLoop];

	// Add our runLoopSource to our runLoop
	CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopDefaultMode);

	// Release the dictionary
	CFRelease(subDict);
} // registerDeviceCallbackHandler

// Returns an iterator across all CD media (class IOCDMedia). Caller is responsible for releasing
// the iterator when iteration is complete.
-(kern_return_t) FindEjectableCDMedia: (io_iterator_t *) iterator
{
	kern_return_t          kernResult;
	CFMutableDictionaryRef classesToMatch;

	/*! @function IOServiceMatching
	   @abstract Create a matching dictionary that specifies an IOService class match.
	   @discussion A very common matching criteria for IOService is based on its class. IOServiceMatching will create a matching dictionary that specifies any IOService of a class, or its subclasses. The class is specified by C-string name.
	   @param name The class name, as a const C-string. Class matching is successful on IOService's of this class or any subclass.
	   @result The matching dictionary created, is returned on success, or zero on failure. The dictionary is commonly passed to IOServiceGetMatchingServices or IOServiceAddNotification which will consume a reference, otherwise it should be released with CFRelease by the caller. */

	// CD media are instances of class kIOCDMediaClass
	classesToMatch = IOServiceMatching(kIOCDMediaClass);
	if (classesToMatch == NULL) {
		printf("IOServiceMatching returned a NULL dictionary.\n");
	} else   {
		/*!
		   @function CFDictionarySetValue
		   Sets the value of the key in the dictionary.
		   @param theDict The dictionary to which the value is to be set. If this
		   parameter is not a valid mutable CFDictionary, the behavior is
		   undefined. If the dictionary is a fixed-capacity dictionary and
		   it is full before this operation, and the key does not exist in
		   the dictionary, the behavior is undefined.
		   @param key The key of the value to set into the dictionary. If a key
		   which matches this key is already present in the dictionary, only
		   the value is changed ("add if absent, replace if present"). If
		   no key matches the given key, the key-value pair is added to the
		   dictionary. If added, the key is retained by the dictionary,
		   using the retain callback provided
		   when the dictionary was created. If the key is not of the sort
		   expected by the key retain callback, the behavior is undefined.
		   @param value The value to add to or replace into the dictionary. The value
		   is retained by the dictionary using the retain callback provided
		   when the dictionary was created, and the previous value if any is
		   released. If the value is not of the sort expected by the
		   retain or release callbacks, the behavior is undefined.
		 */

		CFDictionarySetValue(classesToMatch, CFSTR(kIOMediaEjectableKey), kCFBooleanTrue);
		// Each IOMedia object has a property with key kIOMediaEjectableKey which is true if the
		// media is indeed ejectable. So add this property to the CFDictionary we're matching on.
	}

	/*! @function IOServiceGetMatchingServices
	   @abstract Look up registered IOService objects that match a matching dictionary.
	   @discussion This is the preferred method of finding IOService objects currently registered by IOKit. IOServiceAddNotification can also supply this information and install a notification of new IOServices. The matching information used in the matching dictionary may vary depending on the class of service being looked up.
	   @param masterPort The master port obtained from IOMasterPort().
	   @param matching A CF dictionary containing matching information, of which one reference is consumed by this function. IOKitLib can contruct matching dictionaries for common criteria with helper functions such as IOServiceMatching, IOOpenFirmwarePathMatching.
	   @param existing An iterator handle is returned on success, and should be released by the caller when the iteration is finished.
	   @result A kern_return_t error code. */

	kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch, iterator);
	if (KERN_SUCCESS != kernResult) {
		printf("IOServiceGetMatchingServices returned 0x%08x\n", kernResult);
	}

	return kernResult;
} // FindEjectableCDMedia

// Returns an iterator across all CD media (class IOCDMedia). Caller is responsible for releasing
// the iterator when iteration is complete.
-(kern_return_t) FindMedia: (io_iterator_t *) iterator: (CFMutableDictionaryRef) classesToMatch
{
	kern_return_t kernResult;

	kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch, iterator);
	if (KERN_SUCCESS != kernResult) {
		PMLOG(1, @"IOServiceGetMatchingServices returned 0x%08x\n", kernResult);
	}

	return kernResult;
}

// Returns an iterator across all CD media (class IOCDMedia). Caller is responsible for releasing
// the iterator when iteration is complete.
-(kern_return_t) FindMedia: (io_iterator_t *) iterator: (char *) class : (char *) type
{
	kern_return_t          kernResult;
	CFMutableDictionaryRef classesToMatch;

	/*! @function IOServiceMatching
	   @abstract Create a matching dictionary that specifies an IOService class match.
	   @discussion A very common matching criteria for IOService is based on its class. IOServiceMatching will create a matching dictionary that specifies any IOService of a class, or its subclasses. The class is specified by C-string name.
	   @param name The class name, as a const C-string. Class matching is successful on IOService's of this class or any subclass.
	   @result The matching dictionary created, is returned on success, or zero on failure. The dictionary is commonly passed to IOServiceGetMatchingServices or IOServiceAddNotification which will consume a reference, otherwise it should be released with CFRelease by the caller. */

	// CD media are instances of class kIOCDMediaClass
	classesToMatch = IOServiceMatching(class );
	if (classesToMatch == NULL) {
		PMLOG(1, @"IOServiceMatching returned a NULL dictionary.\n");
	} else   {
		/*!
		   @function CFDictionarySetValue
		   Sets the value of the key in the dictionary.
		   @param theDict The dictionary to which the value is to be set. If this
		   parameter is not a valid mutable CFDictionary, the behavior is
		   undefined. If the dictionary is a fixed-capacity dictionary and
		   it is full before this operation, and the key does not exist in
		   the dictionary, the behavior is undefined.
		   @param key The key of the value to set into the dictionary. If a key
		   which matches this key is already present in the dictionary, only
		   the value is changed ("add if absent, replace if present"). If
		   no key matches the given key, the key-value pair is added to the
		   dictionary. If added, the key is retained by the dictionary,
		   using the retain callback provided
		   when the dictionary was created. If the key is not of the sort
		   expected by the key retain callback, the behavior is undefined.
		   @param value The value to add to or replace into the dictionary. The value
		   is retained by the dictionary using the retain callback provided
		   when the dictionary was created, and the previous value if any is
		   released. If the value is not of the sort expected by the
		   retain or release callbacks, the behavior is undefined.
		 */

		CFDictionarySetValue(classesToMatch, type, kCFBooleanTrue);
		// Each IOMedia object has a property with key kIOMediaEjectableKey which is true if the
		// media is indeed ejectable. So add this property to the CFDictionary we're matching on.
	}

	/*! @function IOServiceGetMatchingServices
	   @abstract Look up registered IOService objects that match a matching dictionary.
	   @discussion This is the preferred method of finding IOService objects currently registered by IOKit. IOServiceAddNotification can also supply this information and install a notification of new IOServices. The matching information used in the matching dictionary may vary depending on the class of service being looked up.
	   @param masterPort The master port obtained from IOMasterPort().
	   @param matching A CF dictionary containing matching information, of which one reference is consumed by this function. IOKitLib can contruct matching dictionaries for common criteria with helper functions such as IOServiceMatching, IOOpenFirmwarePathMatching.
	   @param existing An iterator handle is returned on success, and should be released by the caller when the iteration is finished.
	   @result A kern_return_t error code. */

	kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch, iterator);
	if (KERN_SUCCESS != kernResult) {
		PMLOG(1, @"IOServiceGetMatchingServices returned 0x%08x\n", kernResult);
	}

	return kernResult;
} // FindMedia

// Given an iterator across a set of CD media, return the BSD path to the
// next one. If no CD media was found the path name is set to an empty string.
-(kern_return_t) GetBSDPath: (io_iterator_t) mediaIterator: (char *) bsdPath: (CFIndex) maxPathSize
{
	io_object_t   nextMedia;
	kern_return_t kernResult = KERN_FAILURE;

	*bsdPath = '\0';

	/*! @function IOIteratorNext
	   @abstract Returns the next object in an iteration.
	   @discussion This function returns the next object in an iteration, or zero if no more remain or the iterator is invalid.
	   @param iterator An IOKit iterator handle.
	   @result If the iterator handle is valid, the next element in the iteration is returned, otherwise zero is returned. */

	nextMedia = IOIteratorNext(mediaIterator);
	if (nextMedia) {
		CFTypeRef bsdPathAsCFString;

		/*! @function IORegistryEntryCreateCFProperty
		   @abstract Create a CF representation of a registry entry's property.
		   @discussion This function creates an instantaneous snapshot of a registry entry property, creating a CF container analogue in the caller's task. Not every object available in the kernel is represented as a CF container; currently OSDictionary, OSArray, OSSet, OSSymbol, OSString, OSData, OSNumber, OSBoolean are created as their CF counterparts.
		   @param entry The registry entry handle whose property to copy.
		   @param key A CFString specifying the property name.
		   @param allocator The CF allocator to use when creating the CF container.
		   @param options No options are currently defined.
		   @result A CF container is created and returned the caller on success. The caller should release with CFRelease. */

		bsdPathAsCFString = IORegistryEntryCreateCFProperty(nextMedia,
			CFSTR(kIOBSDNameKey),
			kCFAllocatorDefault,
			0);
		if (bsdPathAsCFString) {
			size_t devPathLength;

			strcpy(bsdPath, _PATH_DEV);

			// Add "r" before the BSD node name from the I/O Registry to specify the raw disk
			// node. The raw disk nodes receive I/O requests directly and do not go through
			// the buffer cache.

			strcat(bsdPath, "r");

			devPathLength = strlen(bsdPath);

			if ( CFStringGetCString(bsdPathAsCFString,
					bsdPath + devPathLength,
					maxPathSize - devPathLength,
					kCFStringEncodingUTF8) ) {
				printf("BSD path: %s\n", bsdPath);
				kernResult = KERN_SUCCESS;
			}

			CFRelease(bsdPathAsCFString);
		}

		/*! @function IOObjectRelease
		   @abstract Releases an object handle previously returned by IOKitLib.
		   @discussion All objects returned by IOKitLib should be released with this function when access to them is no longer needed. Using the object after it has been released may or may not return an error, depending on how many references the task has to the same object in the kernel.
		   @param object The IOKit object to release.
		   @result A kern_return_t error code. */

		IOObjectRelease(nextMedia);
	}

	return kernResult;
} // GetBSDPath

// Given the path to a CD drive, open the drive.
// Return the file descriptor associated with the device.
-(int) OpenDrive: (const char *) bsdPath
{
	int fileDescriptor;

	// This open() call will fail with a permissions error if the sample has been changed to
	// look for non-removable media. This is because device nodes for fixed-media devices are
	// owned by root instead of the current console user.
	//
	// The recommended way to handle the permissions issue is described in "Performing Privileged Operations With
	// Authorization Services":
	// <http://developer.apple.com/documentation/Security/Conceptual/authorization_concepts/index.html>

	fileDescriptor = open(bsdPath, O_RDONLY);

	if (fileDescriptor == -1) {
		printf("Error opening device %s: ", bsdPath);
		perror(NULL);
	}

	return fileDescriptor;
} // OpenDrive

// Given the file descriptor for a whole-media CD device, read a sector from the drive.
// Return true if successful, otherwise false.
-(Boolean) ReadSector: (int) fileDescriptor
{
	char    * buffer;
	ssize_t   numBytes;
	u_int32_t blockSize;

	// This ioctl call retrieves the preferred block size for the media. It is functionally
	// equivalent to getting the value of the whole media object's "Preferred Block Size"
	// property from the IORegistry.
	if ( ioctl(fileDescriptor, DKIOCGETBLOCKSIZE, &blockSize) ) {
		perror("Error getting preferred block size");

		// Set a reasonable default if we can't get the actual preferred block size. A real
		// app would probably want to bail at this point.
		blockSize = kCDSectorSizeCDDA;
	}

	printf("Media has block size of %d bytes.\n", blockSize);

	// Allocate a buffer of the preferred block size. In a real application, performance
	// can be improved by reading as many blocks at once as you can.
	buffer = malloc(blockSize);

	// Do the read. Note that we use read() here, not fread(), since this is a raw device
	// node.
	numBytes = read(fileDescriptor, buffer, blockSize);

	// Free our buffer. Of course, a real app would do something useful with the data first.
	free(buffer);

	return numBytes == blockSize ? true : false;
} // ReadSector

// Given the file descriptor for a device, close that device.
-(void) CloseDrive: (int) fileDescriptor
{
	close(fileDescriptor);
}

@end


//
//	AppearedNotificationHandler
//

static void
AppearedNotificationHandler(void * refCon, io_iterator_t iterator)
{
	io_service_t   theService  = IO_OBJECT_NULL;
	MediaStorage * mediaStorage  = (MediaStorage *)refCon;

	theService = IOIteratorNext(iterator);
	while (theService != IO_OBJECT_NULL) {
		CFMutableDictionaryRef theDict          = 0;
		MediaDevice          * newMediaDevice   = nil;
		IOReturn               theErr           = 0;

		newMediaDevice = [MediaDevice newdevice];

		[mediaStorage FindEjectableCDMedia: &iterator];
		// Get the CF Properties for the io_service_t
		theErr = IORegistryEntryCreateCFProperties(theService,
			&theDict,
			kCFAllocatorDefault,
			0);

		if (theErr == kIOReturnSuccess) {
			// Check for the GUID key
			if ( CFDictionaryContainsKey( theDict, CFSTR(kIOPropertySCSITaskUserClientInstanceGUID) ) ) {
				NSData * theData = nil;

				theData = (NSData *)CFDictionaryGetValue( theDict, CFSTR(kIOPropertySCSITaskUserClientInstanceGUID) );
				[newMediaDevice setGUID: theData];
			}

			// Check for the Protocol Characteristics key
			if ( CFDictionaryContainsKey( theDict, CFSTR(kIOPropertyProtocolCharacteristicsKey) ) ) {
				CFStringRef     physicalInterconnectString  = NULL;
				CFDictionaryRef protocolDict                = NULL;

				protocolDict = (CFDictionaryRef)CFDictionaryGetValue( theDict,
					CFSTR(kIOPropertyProtocolCharacteristicsKey) );

				physicalInterconnectString = (CFStringRef)CFDictionaryGetValue( protocolDict,
					CFSTR(kIOPropertyPhysicalInterconnectTypeKey) );

#if FILTER_ATAPI_DEVICES_ONLY

				if (CFStringCompare(physicalInterconnectString, CFSTR(kIOPropertyPhysicalInterconnectTypeATAPI), 0) != kCFCompareEqualTo) {
					// Not an ATAPI device. Clean up and bail. Do not call release on the AuthoringDevice as it was
					// given to you autoreleased.
					CFRelease(theDict);
					theDict = 0;
					(void)IOObjectRelease(theService);
					theService = IOIteratorNext(iterator);
					continue;
				}

#endif /* FILTER_ATAPI_DEVICES_ONLY */

				[newMediaDevice setPhysicalInterconnect: (NSString *)physicalInterconnectString];
			}

			// Check for the Device Characteristics key
			if ( CFDictionaryContainsKey( theDict, CFSTR(kIOPropertyDeviceCharacteristicsKey) ) ) {
				CFStringRef     string          = NULL;
				CFDictionaryRef deviceDict      = NULL;
				CFNumberRef     features        = NULL;
				UInt32          value           = 0;

#if FILTER_DVD_BURNERS_ONLY

#endif /* FILTER_DVD_BURNERS_ONLY */

				deviceDict = (CFDictionaryRef)CFDictionaryGetValue( theDict,
					CFSTR(kIOPropertyDeviceCharacteristicsKey) );

				// Get the vendor, product, and firmware info for display
				string = (CFStringRef)CFDictionaryGetValue( deviceDict, CFSTR(kIOPropertyVendorNameKey) );
				[newMediaDevice setVendorName: (NSString *)string];

				string = (CFStringRef)CFDictionaryGetValue( deviceDict, CFSTR(kIOPropertyProductNameKey) );
				[newMediaDevice setProductName: (NSString *)string];

				string = (CFStringRef)CFDictionaryGetValue( deviceDict, CFSTR(kIOPropertyProductRevisionLevelKey) );
				[newMediaDevice setProductRevisionLevel: (NSString *)string];

				features = (CFNumberRef)CFDictionaryGetValue( deviceDict, CFSTR(kIOPropertySupportedCDFeatures) );
				CFNumberGetValue(features, kCFNumberLongType, &value);
				[newMediaDevice setCDFeatures: value];

				features = (CFNumberRef)CFDictionaryGetValue( deviceDict, CFSTR(kIOPropertySupportedDVDFeatures) );
				CFNumberGetValue(features, kCFNumberLongType, &value);
				[newMediaDevice setDVDFeatures: value];

				PMLOG(2, @"newdevice : %@", newMediaDevice);
#if FILTER_DVD_BURNERS_ONLY

				if ( ( (value & kDVDFeaturesWriteOnceMask) == 0 ) &&
				    ( (value & kDVDFeaturesReWriteableMask) == 0 ) &&
				    ( (value & kDVDFeaturesPlusRMask) == 0 ) &&
				    ( (value & kDVDFeaturesPlusRWMask) == 0 ) ) {
					// Not a burner. Clean up and bail. Do not call release on the AuthoringDevice as it was
					// given to you autoreleased.
					CFRelease(theDict);
					theDict = 0;
					(void)IOObjectRelease(theService);
					theService = IOIteratorNext(iterator);
					continue;
				}

#endif /* FILTER_DVD_BURNERS_ONLY */
			}

			// We're done with this dictionary, so release it.
			CFRelease(theDict);
			theDict = 0;

			// Add the object to the data source so that it knows about this device
			[[mediaStorage theDeviceList] addObject: newMediaDevice];
		}

		// Release the object.
		(void)IOObjectRelease(theService);
		theService = IOIteratorNext(iterator);
	}
} // AppearedNotificationHandler

//
//	DisappearedNotificationHandler
//

static void
DisappearedNotificationHandler(void * refCon, io_iterator_t iterator)
{
	io_service_t   theService  = IO_OBJECT_NULL;
	MediaStorage * mediaStorage  = (MediaStorage *)refCon;

	theService = IOIteratorNext(iterator);
	while (theService != IO_OBJECT_NULL) {
		CFMutableDictionaryRef theDict     = NULL;
		MediaStorage         * newDevice   = nil;
		IOReturn               theErr      = kIOReturnSuccess;

		MediaDevice * newMediaDevice = [MediaDevice newdevice];

		// Get the CF Properties for this node
		theErr = IORegistryEntryCreateCFProperties(theService,
			&theDict,
			kCFAllocatorDefault,
			0);

		if (theErr == kIOReturnSuccess) {
			// Get the GUID key
			if ( CFDictionaryContainsKey( theDict, CFSTR(kIOPropertySCSITaskUserClientInstanceGUID) ) ) {
				NSData * theData = nil;

				theData = (NSData *)CFDictionaryGetValue( theDict, CFSTR(kIOPropertySCSITaskUserClientInstanceGUID) );
				[newMediaDevice setGUID: theData];

				// Since the GUID is used to distinguish between two objects (the object overrides isEqual),
				// we just create a new object and fill in the GUID key above, and then tell the data source
				// to remove it. If you decide to use more criteria than the GUID (like the physical interconnect)
				// be sure to add those fields to the object before calling removeObject on the theDeviceList
				[[mediaStorage theDeviceList] removeObject: newDevice];
			}
		}

		(void)IOObjectRelease(theService);
		theService = IOIteratorNext(iterator);
	}
} // DisappearedNotificationHandler