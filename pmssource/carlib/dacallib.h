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
#import <PMSUtility/pmsCFUtility.h>
#import <PMSUtility/pms.h>


typedef IOUSBDeviceInterface300    DACALIOUSBDeviceInterface;
typedef IOUSBInterfaceInterface300 DACALIOUSBInterfaceInterface;

#define DACAL_MAXDEVICE_COUNT   64 * 4                            // 64 boxes + 64 hubs = 128 devices/per port for possible 4 ports.  Total 256 devices.
#define DACAL_MAXCLIENT_COUNT   1                               // Only 1 will work for now.

//#define	DACAL_SHORT_SLEEP		usleep(900);
#define DACAL_SHORT_SLEEP       sleep(1);
#define DACAL_RESET_SLEEP       sleep(5);

#define DACAL_BOX_BUSY(x)           gDACALBoxes.box[x].isBusy
#define DACAL_BOX_NAME(x)           gDACALBoxes.box[x].boxName
#define DACAL_BOX_MODEL(x)          gDACALBoxes.box[x].boxModel
#define DACAL_BOX_UUID(x)           gDACALBoxes.box[x].boxUUID
#define DACAL_BOX_REF(x)            gDACALBoxes.box[x].boxRef
#define DACAL_BOX_DEVICE(x)         gDACALBoxes.box[x].boxDevice
#define DACAL_BOX_LASTSLOT(x)       gDACALBoxes.box[x].boxLastSlot
#define DACAL_BOX_LASTSLOTTIME(x)   gDACALBoxes.box[x].boxLastSlotTime
#define DACAL_BOX_PATH(x)           gDACALBoxes.box[x].boxPath
#define DACAL_BOX_NODE(x)           gDACALBoxes.box[x].boxNode
#define DACAL_BOX_NOTIFICATION(x)   gDACALBoxes.box[x].boxNotification

#define DACAL_CLIENT_IDENTIFIER(x)  gDACALClients.client[x - 1].clientIdentifier
#define DACAL_CLIENT_ALLOCATOR(x)   gDACALClients.client[x - 1].clientAllocator
#define DACAL_CLIENT_CALLBACK(x)    gDACALClients.client[x - 1].clientCallback
#define DACAL_CLIENT_USERDATA(x)    gDACALClients.client[x - 1].clientDataRef

//#define PMBUFSIZE(x) (((sizeof(x)/8)+1)*8)
#define PMBUFSIZE(x) ( sizeof(x) )

extern const SInt32 kDACALVendorID;
extern const SInt32 kDACALDC300ProductID;
extern const SInt32 kDACALDC016ProductID;
extern const SInt32 kDACALProductID;
extern const SInt32 kDACALReleaseID;

typedef UInt8          DACALCommand;
typedef UInt16         DACALSlotNum;
typedef vm_offset_t    DACALDeviceRef;
typedef UInt16         DACALCount;
typedef kern_return_t  DACALResult;
typedef u_long         DACALOptionBits;
typedef DACALDeviceRef DACALDeviceRefNode;

extern const DACALDeviceRef kDACALDefaultDevice;
extern const DACALDeviceRef kDACALIllegalDevice;
extern const DACALDeviceRef kDACALDevicesMaxCount;
extern const DACALDeviceRef kDACALNullDevice;

typedef enum {
	undocManufacturer = 1,
	undocSoftware     = 2,
	undocUnknown3,
	undocUnknown4,
	undocUnknown5,
	undocUnknown6,
	undocUnknown7,
	undocUnknown8,
	cmdGetModel,    // 9
	cmdGetUUID,     // 10
	cmdReset,       // 11
	cmdMoveToSlot,  // 12
	cmdReserved1,   // 13
	cmdCloseDoor,   // 14
	cmdLEDOn,       // 15
	cmdLEDOff,      // 16
	cmdGetStatus,   // 17
	cmdGetSlot,     // 18
	cmdMoveToDVD,   // 19
	cmdEjectDVD     // 20
}                           dacalCmd;

typedef struct {
	Boolean            isBusy;
	DACALDeviceRefNode boxNode;
	CFStringRef        boxName;
	CFStringRef        boxModel;
	CFUUIDRef          boxUUID;
	CFURLRef           boxPath;
	DACALIOUSBDeviceInterface **boxRef;
	io_service_t boxDevice;
	io_object_t  boxNotification;
	DACALSlotNum boxLastSlot;
	time_t       boxLastSlotTime;
}                           DACALBox, *DACALBoxRef;

typedef struct {
	DACALCount boxCount;
	DACALBox   box[DACAL_MAXDEVICE_COUNT];                            // Change the constant above if necesary
}                                     DACALArray;

typedef struct {
	UInt8   stringSize;
	UInt8   stringCode;
	UniChar uniString[128];
}                                     dacalString, *dacalStringRef;

typedef struct {
	CFStringRef    clientIdentifier;
	CFAllocatorRef clientAllocator;
	void *clientCallback;
	void *clientDataRef;
} DACALClientData, *DACALClientDataRef;

typedef struct {
	unsigned int    clientCount;
	DACALClientData client[DACAL_MAXCLIENT_COUNT];
}                  DACALClientsArray;

typedef vm_offset_t DACALClientRef;

//static	mach_port_t				masterPort = 0;				// requires <mach/mach.h>
//extern io_iterator_t         gDACALAddedIter;
//extern CFAllocatorRef        gDACALDefaultCFAllocator;
//extern IONotificationPortRef gDACALNotifyPort;
//extern CFRunLoopSourceRef    gDACALRunLoopSource;
extern DACALDeviceRef gDACALDefaultDevice1;
//extern DACALArray            gDACALBoxes;
//extern DACALClientsArray     gDACALClients;
//extern DACALClientRef        gDACALNextClientID;

extern const DACALResult kDACALOK;
extern const DACALResult kDACALBusy;
extern const DACALResult kDACALError;
extern const DACALResult kDACALInvalidParameter;

extern CFStringRef DACALDC101CFName;
extern CFStringRef DACALDC300CFName;
extern CFStringRef DACALDC016CFName;

extern CFStringRef kDACALPreferencesID;
extern CFStringRef kDACALCarouselDocumentExtension;
extern CFStringRef kDACALCarouselDocumentDotExtension;
extern CFStringRef kDACALCarouselDocumentInfoFile;

extern CFStringRef kDACALCarouselDocumentDisplayNameFormat;
extern CFStringRef kDACALCarouselDocumentInfoKeyName;
extern CFStringRef kDACALCarouselDocumentInfoKeyUUID;

extern CFStringRef kDACALCarouselDocumentXAttrCarousel;
extern CFStringRef kDACALCarouselDocumentXAttrSlot;
extern CFStringRef kDACALCarouselDocumentXAttrSlotID;
extern CFStringRef kDACALCarouselDocumentXAttrSlotKind;
extern CFStringRef kDACALCarouselDocumentXAttrSlotAddDate;
extern CFStringRef kDACALCarouselDocumentXAttrSlotIsOut;
extern CFStringRef kDACALCarouselDocumentXAttrSlotCheckout;
extern CFStringRef kDACALCarouselDocumentXAttrSlotCheckIn;
extern CFStringRef kDACALCarouselDocumentXAttrVolumeName;
extern CFStringRef kDACALCarouselDocumentXAttrVolumeSize;

extern CFStringRef kDACALCarouselDocumentXAttrUserTitle;
extern CFStringRef kDACALCarouselDocumentXAttrUserComments;
extern CFStringRef kDACALCarouselDocumentXAttrUserTags;
extern CFStringRef kDACALCarouselDocumentXAttrUserStars;
extern CFStringRef kDACALCarouselDocumentXAttrUserLinks;
extern CFStringRef kDACALCarouselDocumentXAttrUserArtwork;
extern CFStringRef kDACALCarouselDocumentXAttrUserRating;
extern CFStringRef kDACALCarouselDocumentXAttrBookmarks;

extern CFStringRef kDACALCarouselNoticeDeviceOpen;
extern CFStringRef kDACALCarouselNoticeDeviceClose;

extern CFStringRef kPADClientIdentifier;

extern const DACALDeviceRef kDACALDefaultDevice;
extern const DACALDeviceRef kDACALIllegalDevice;
extern const DACALDeviceRef kDACALDevicesMaxCount;
extern const DACALDeviceRef kDACALNullDevice;

extern const DACALResult kDACALOK;
extern const DACALResult kDACALBusy;
extern const DACALResult kDACALError;
extern const DACALResult kDACALInvalidParameter;

const enum {
	kDACALOptionMoveDefault  = 0x00,     // regular MoveToSlot:  close, move, open
	kDACALOptionMoveOnce     = 0x01,     // only moves if slot wasn't the last one opened.
	kDACALOptionMoveOpenSlot = 0x02,     // skips initial close and opens slot.
	kDACALOptionMoveToggle   = 0x03,     // if slot is last slot then close & clear slot
}                        DACALMoveOption;

const enum {                                // This constant can be used with FSFindFolder()
	kDACALCarouselsFolderType = 'Crsl',   // to locate the Carousels folder.
	kDACALCreatorType         = 'PADr'
} DACALEnumType;

// Callbacks

typedef void *DACALClientNotificationCallback(void *clientData, DACALDeviceRef noticeDevice, CFStringRef noticeMessage, CFDictionaryRef noticeData);

// Public Functions
extern void               PMLOGSetVerbose(Boolean value);

extern CFStringRef        DACALCommandCopyName(DACALDeviceRef deviceID, DACALResult *outError);

extern DACALResult        DACALCommandSetName(DACALDeviceRef deviceID, CFStringRef deviceName);

extern CFStringRef        DACALSlotCopyType(DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult *outError);

extern DACALResult        DACALSlotSetType(DACALDeviceRef deviceID, DACALSlotNum slotNum, CFStringRef slotType);

extern DACALDeviceRefNode DACALCommandCopyNode(DACALDeviceRef deviceID, DACALResult *outError);

//extern DACALResult		DACALCommandSetNode( DACALDeviceRef deviceID, DACALDeviceRefNode deviceNode );
extern DACALSlotNum      DACALCommandGetSlotCount(DACALDeviceRef deviceID);

extern CFURLRef          DACALCommandCopyPath(DACALDeviceRef deviceID, DACALResult *outError);

extern CFMutableArrayRef DACALCommandCopyAllSlotPaths(DACALDeviceRef deviceID, DACALResult *outError);

extern CFStringRef  DACALCommandCopyStatus(DACALDeviceRef deviceID, DACALResult *outError);

extern DACALResult  DACALGetStatus(DACALDeviceRef deviceID);

extern CFUUIDRef    DACALCommandCopyUUID(DACALDeviceRef deviceID, DACALResult *outError);

extern CFStringRef  DACALCommandCopyModel(DACALDeviceRef deviceID, DACALResult *outError);

extern Boolean      DACALIsDC016(DACALDeviceRef deviceID);

extern DACALResult  DACALCommandReset(DACALDeviceRef deviceID);

extern DACALResult  DACALCommandCloseDoor(DACALDeviceRef deviceID);

extern DACALResult  DACALCommandSetLED(DACALDeviceRef deviceID, Boolean isVisible);

extern DACALResult  DACALCommandMoveToSlot(DACALDeviceRef deviceID, DACALSlotNum newSlot);

extern DACALResult  DACALCommandMoveToSlotWithOptions(DACALDeviceRef deviceID, DACALSlotNum newSlot, DACALOptionBits moveOptions);

extern DACALSlotNum DACALCommandDVDGetSlot(DACALDeviceRef deviceID, DACALResult *outError);

extern DACALResult  DACALCommandDVDMoveTo(DACALDeviceRef deviceID, DACALSlotNum newSlot);

extern DACALResult  DACALCommandDVDEject(DACALDeviceRef deviceID);

extern DACALResult  DACALSlotCreateIndex(DACALDeviceRef deviceID, DACALSlotNum slotNum, CFStringRef slotTitle, DACALCount indexLevel, CFURLRef sourcePath);

extern DACALResult  DACALSlotDeleteIndex(DACALDeviceRef deviceID, DACALSlotNum slotNum);

extern DACALResult  DACALSlotMove(DACALDeviceRef fromDeviceID, DACALSlotNum fromSlotNum, DACALDeviceRef toDeviceID, DACALSlotNum toSlotNum);

extern CFStringRef  DACALSlotCopyTitle(DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult *outError);

extern DACALResult  DACALSlotSetTitle(DACALDeviceRef deviceID, DACALSlotNum slotNum, CFStringRef slotTitle);

extern CFURLRef     DACALSlotCopyPath(DACALDeviceRef deviceID, DACALSlotNum slotNum, DACALResult *outError);

extern DACALSlotNum DACALSlotNextFreeNumber(DACALDeviceRef deviceID, DACALSlotNum lowestSlot, DACALSlotNum highestSlot, DACALResult *outError);

extern void DACALDevicesAdded(void *refCon, io_iterator_t iterator);

extern void DACALDevicesAddedWithService(void *refCon, io_iterator_t iterator);

//extern DACALResult		DACALDevicesInitialize( void (* DACALDevicesAddedFPtr)(void * refCon, io_iterator_t iterator) );
extern DACALResult    DACALDevicesInitialize(void);

extern DACALResult    DACALDevicesFinalize(void);

extern DACALCount     DACALDevicesGetCount(void);

extern DACALDeviceRef DACALDevicesCopyDeviceRefForIndex(DACALCount deviceID, DACALResult *outError);

extern CFArrayRef     DACALDevicesCopyAllNames(void);

extern DACALCount     DACALDevicesGetCountForModel(CFStringRef aDeviceType);

extern DACALSlotNum   DACALDevicesGetSlotCount(CFStringRef aDeviceType);

extern DACALDeviceRef DACALDevicesGetDefaultDevice(void);

extern DACALResult    DACALDevicesSetDefaultDevice(DACALDeviceRef deviceID);

extern CFAllocatorRef DACALDevicesGetCFAllocator(void);

extern DACALResult    DACALDevicesSetCFAllocator(CFAllocatorRef defaultAlloc);

extern DACALDeviceRef  DACALDeviceRetain(DACALDeviceRef inDevice);

extern void            DACALDeviceRelease(DACALDeviceRef inDevice);

extern DACALResult     DACALDeviceInfoSetKey(DACALDeviceRef inDevice, CFStringRef inKeyName, CFTypeRef inKeyValue);

extern DACALResult     DACALDeviceInfoAddDictionary(DACALDeviceRef inDevice, CFDictionaryRef keyValueDictionary);

extern CFTypeRef       DACALDeviceInfoCopyKey(DACALDeviceRef deviceID, CFStringRef inKeyName, DACALResult *outResult);

extern CFDictionaryRef DACALDeviceInfoCopyKeys(DACALDeviceRef deviceID, CFArrayRef inKeyNames, DACALResult *outResult);

extern OSErr            DACALCreateLibraryFolder(FSRef *topFolder);

extern DACALResult      DACALClientCreate(CFStringRef clientID, void *useDataRef, void *useCallback);

extern void             DACALClientRelease(CFStringRef clientID);

extern void             DACALClientNotifyAll(DACALDeviceRef noticeDevice, CFStringRef noticeMessage, CFDictionaryRef noticeData);

#endif // __dacallib__