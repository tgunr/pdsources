/*
 *  dacallib.h
 *  PMTB
 *
 *  Created by Dave Carlton on 05/20/08.
 *  Copyright 2008 Polymicro Systems. All rights reserved.
 *
 */

#ifndef __dacallib__
#define __dacallib__

#include <stdio.h>
#include <mach/mach.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/hid/IOHIDLib.h>
#include <IOKit/hid/IOHIDKeys.h>
#include <IOKit/usb/IOUSBLib.h>

#include <CoreFoundation/CoreFoundation.h>

extern const SInt32		kDACALVendorID;
extern const SInt32		kDACALProductID;
extern const SInt32		kDACALReleaseID;

typedef UInt8			DACALCommand;
typedef	UInt16			DACALSlotNum;
typedef	vm_offset_t		DACALDeviceRef;
typedef	UInt16			DACALCount;
typedef kern_return_t	DACALResult;

extern CFStringRef		DACALDC300CFName;
extern CFStringRef		DACALDC016RWCFName;

extern Boolean			gDACALVerbose;

extern const DACALDeviceRef	kDACALDefaultDevice;
extern const DACALDeviceRef	kDACALIllegalDevice;
extern const DACALDeviceRef	kDACALDevicesMaxCount;

extern const DACALResult	kDACALOK;
extern const DACALResult	kDACALBusy;
extern const DACALResult	kDACALError;

// Public Functions

extern CFStringRef		DACALCommandCopyName( DACALDeviceRef deviceID, DACALResult* outError );
extern DACALResult		DACALCommandSetName( DACALDeviceRef deviceID, CFStringRef deviceName );
extern DACALSlotNum		DACALCommandGetSlotCount( DACALDeviceRef deviceID );

extern CFStringRef		DACALCommandCopyStatus( DACALDeviceRef deviceID, DACALResult* outError );
extern CFUUIDRef		DACALCommandCopyUUID( DACALDeviceRef deviceID, DACALResult* outError );
extern CFStringRef		DACALCommandCopyModel( DACALDeviceRef deviceID, DACALResult* outError );
extern DACALResult		DACALCommandReset( DACALDeviceRef deviceID );
extern DACALResult		DACALCommandCloseDoor( DACALDeviceRef deviceID );
extern DACALResult		DACALCommandSetLED( DACALDeviceRef deviceID, Boolean isVisible );
extern DACALResult		DACALCommandMoveToSlot( DACALDeviceRef deviceID, DACALSlotNum newSlot );
extern DACALSlotNum		DACALCommandDVDGetSlot( DACALDeviceRef deviceID, DACALResult* outError );
extern DACALResult		DACALCommandDVDMoveTo( DACALDeviceRef deviceID, DACALSlotNum newSlot );
extern DACALResult		DACALCommandDVDEject( DACALDeviceRef deviceID );

extern DACALResult		DACALDevicesInitialize( void );
extern DACALResult		DACALDevicesFinalize( void );
extern DACALCount		DACALDevicesGetCount( void );
extern DACALCount		DACALDevicesGetCountForModel( CFStringRef aDeviceType );
extern DACALSlotNum		DACALDevicesGetSlotCount( CFStringRef aDeviceType );
extern DACALDeviceRef	DACALDevicesGetDefaultDevice( void );
extern DACALResult		DACALDevicesSetDefaultDevice( DACALDeviceRef deviceID );
extern CFAllocatorRef	DACALDevicesGetCFAllocator( void );
extern DACALResult		DACALDevicesSetCFAllocator( CFAllocatorRef defaultAlloc );

#endif // __dacallib__
