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
#include <sys/xattr.h>
#include <mach/mach.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOMessage.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/hid/IOHIDLib.h>
#include <IOKit/hid/IOHIDKeys.h>
#include <IOKit/usb/IOUSBLib.h>

#include <CoreFoundation/CoreFoundation.h>
#include "../pmsutility/pmsCFUtility.h"

extern const SInt32		kDACALVendorID;
extern const SInt32		kDACALProductID;
extern const SInt32		kDACALReleaseID;

typedef UInt8			DACALCommand;
typedef	UInt16			DACALSlotNum;
typedef	vm_offset_t		DACALDeviceRef;
typedef	UInt16			DACALCount;
typedef kern_return_t	DACALResult;
typedef u_long			DACALOptionBits;
typedef	DACALDeviceRef	DACALDeviceNode;

extern CFStringRef		DACALDC101CFName;
extern CFStringRef		DACALDC300CFName;
extern CFStringRef		DACALDC016RWCFName;

extern Boolean			gDACALVerbose;

extern CFStringRef		kDACALPreferencesID;
extern CFStringRef		kDACALCarouselDocumentExtension;
extern CFStringRef		kDACALCarouselDocumentDotExtension;
extern CFStringRef		kDACALCarouselDocumentInfoFile;

extern CFStringRef		kDACALCarouselDocumentDisplayNameFormat;
extern CFStringRef		kDACALCarouselDocumentInfoKeyName;
extern CFStringRef		kDACALCarouselDocumentInfoKeyUUID;

extern CFStringRef		kDACALCarouselDocumentXAttrCarousel;
extern CFStringRef		kDACALCarouselDocumentXAttrSlot;
extern CFStringRef		kDACALCarouselDocumentXAttrSlotKind;
extern CFStringRef		kDACALCarouselDocumentXAttrSlotAddDate;
extern CFStringRef		kDACALCarouselDocumentXAttrSlotCheckout;
extern CFStringRef		kDACALCarouselDocumentXAttrVolumeName;

extern CFStringRef		kDACALCarouselNoticeDeviceOpen;
extern CFStringRef		kDACALCarouselNoticeDeviceClose;


extern const DACALDeviceRef	kDACALDefaultDevice;
extern const DACALDeviceRef	kDACALIllegalDevice;
extern const DACALDeviceRef	kDACALDevicesMaxCount;
extern const DACALDeviceRef kDACALNullDevice;

extern const DACALResult	kDACALOK;
extern const DACALResult	kDACALBusy;
extern const DACALResult	kDACALError;
extern const DACALResult	kDACALInvalidParameter;


const enum {
	kDACALOptionMoveDefault		= 0x00,		// regular MoveToSlot:  close, move, open
	kDACALOptionMoveOnce		= 0x01,		// only moves if slot wasn't the last one opened.
	kDACALOptionMoveOpenSlot	= 0x02,		// skips initial close and opens slot.
	kDACALOptionMoveToggle		= 0x03,		// if slot is last slot then close & clear slot
} DACALMoveOption;

const enum {								// This constant can be used with FSFindFolder()
	kDACALCarouselsFolderType	= 'Crsl',	// to locate the Carousels folder.
	kDACALCreatorType = 'PADr'
} DACALEnumType;

// Callbacks

typedef void *DACALClientNotificationCallback( void* clientData, DACALDeviceRef noticeDevice, CFStringRef noticeMessage, CFDictionaryRef noticeData );

// Public Functions

extern CFStringRef		DACALCommandCopyName( DACALDeviceRef deviceID, DACALResult* outError );
extern DACALResult		DACALCommandSetName( DACALDeviceRef deviceID, CFStringRef deviceName );
extern CFStringRef		DACALSlotCopyType( DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult* outError );
extern DACALResult		DACALSlotSetType( DACALDeviceRef deviceID, DACALSlotNum slotNum, CFStringRef slotType );
extern DACALDeviceNode	DACALCommandCopyNode( DACALDeviceRef deviceID, DACALResult* outError );
//extern DACALResult		DACALCommandSetNode( DACALDeviceRef deviceID, DACALDeviceNode deviceNode );
extern DACALSlotNum		DACALCommandGetSlotCount( DACALDeviceRef deviceID );
extern CFURLRef			DACALCommandCopyPath( DACALDeviceRef deviceID, DACALResult* outError );
extern CFMutableArrayRef	DACALCommandCopyAllSlotPaths( DACALDeviceRef deviceID, DACALResult* outError );

extern CFStringRef		DACALCommandCopyStatus( DACALDeviceRef deviceID, DACALResult* outError );
extern CFUUIDRef		DACALCommandCopyUUID( DACALDeviceRef deviceID, DACALResult* outError );
extern CFStringRef		DACALCommandCopyModel( DACALDeviceRef deviceID, DACALResult* outError );
extern DACALResult		DACALCommandReset( DACALDeviceRef deviceID );
extern DACALResult		DACALCommandCloseDoor( DACALDeviceRef deviceID );
extern DACALResult		DACALCommandSetLED( DACALDeviceRef deviceID, Boolean isVisible );
extern DACALResult		DACALCommandMoveToSlot( DACALDeviceRef deviceID, DACALSlotNum newSlot );
extern DACALResult		DACALCommandMoveToSlotWithOptions( DACALDeviceRef deviceID, DACALSlotNum newSlot, DACALOptionBits moveOptions );
extern DACALSlotNum		DACALCommandDVDGetSlot( DACALDeviceRef deviceID, DACALResult* outError );
extern DACALResult		DACALCommandDVDMoveTo( DACALDeviceRef deviceID, DACALSlotNum newSlot );
extern DACALResult		DACALCommandDVDEject( DACALDeviceRef deviceID );

extern DACALResult		DACALSlotCreateIndex( DACALDeviceRef deviceID, DACALSlotNum slotNum, CFStringRef slotTitle, DACALCount indexLevel, CFURLRef sourcePath );
extern DACALResult		DACALSlotDeleteIndex( DACALDeviceRef deviceID, DACALSlotNum slotNum );
extern CFStringRef		DACALSlotCopyTitle( DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult* outError );
extern DACALResult		DACALSlotSetTitle( DACALDeviceRef deviceID, DACALSlotNum slotNum, CFStringRef slotTitle );
extern CFURLRef			DACALSlotCopyPath( DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult* outError );
extern DACALSlotNum		DACALSlotNextFreeNumber( DACALDeviceRef deviceID, DACALSlotNum lowestSlot, DACALSlotNum highestSlot, DACALResult* outError );

extern DACALResult		DACALDevicesInitialize( void );
extern DACALResult		DACALDevicesFinalize( void );
extern DACALCount		DACALDevicesGetCount( void );
extern CFArrayRef		DACALDevicesCopyAllNames( void );
extern DACALCount		DACALDevicesGetCountForModel( CFStringRef aDeviceType );
extern DACALSlotNum		DACALDevicesGetSlotCount( CFStringRef aDeviceType );
extern DACALDeviceRef	DACALDevicesGetDefaultDevice( void );
extern DACALResult		DACALDevicesSetDefaultDevice( DACALDeviceRef deviceID );
extern CFAllocatorRef	DACALDevicesGetCFAllocator( void );
extern DACALResult		DACALDevicesSetCFAllocator( CFAllocatorRef defaultAlloc );

extern DACALDeviceRef	DACALDeviceRetain( DACALDeviceRef inDevice );
extern void				DACALDeviceRelease( DACALDeviceRef inDevice );

extern DACALResult		DACALClientCreate( CFAllocatorRef useAllocator, CFStringRef clientID, void* useDataRef, void* useCallback);
extern void				DACALClientRelease( CFStringRef clientID );
extern void				DACALClientNotifyAll( DACALDeviceRef noticeDevice, CFStringRef noticeMessage, CFDictionaryRef noticeData );


#endif // __dacallib__
