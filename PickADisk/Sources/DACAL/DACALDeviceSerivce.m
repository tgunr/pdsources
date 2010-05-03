//
//  DACALDeviceSerivce.m
//  PickADisk
//
//  Created by Dave Carlton on 01/11/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import "DACALDeviceSerivce.h"
#import "PADLifecycleController.h"
#import "NSArray_Extensions.h"
#import "DACALDeviceNode.h"
#import "DACALDriverInstaller.h"
#import "LicenseService.h"
#import "DACALSlot.h"

@implementation DACALDeviceService

@synthesize deviceList;

-(NSInteger)deviceCount
{
	return [deviceList count];
}

-(void)dealloc
{
	[deviceList release];
	[super dealloc];
}

-(void)initSelf
{
	//	gDACALDevices = [[NSMutableArray alloc] initWithCapacity:0];
	[self setDeviceList: [[NSMutableArray alloc] initWithCapacity: 0]];
}

-(id)initializeService
{
	PADBOX_VALID_BEGIN DACALRegisterIconResource(CFSTR("DC300Black"), kDACALCarouselsFolderType);

	DACALRegisterIconResource(CFSTR("CDAudio"), 'cdda');
	DACALRegisterIconResource(CFSTR("DVD-Video"), 'dvd ');
	DACALRegisterIconResource(CFSTR("CD-silver"), 'Dcd ');

	DACALRegisterIconResource(CFSTR("Generic_Files"), 'gFil');
	DACALRegisterIconResource(CFSTR("Generic_Music"), 'gMus');
	DACALRegisterIconResource(CFSTR("Generic_Movie"), 'gMov');
	DACALRegisterIconResource(CFSTR("Generic_Image"), 'gImg');

	DACALClientCreate(kCFAllocatorDefault, kPADClientIdentifier, (void *)self, DACALNotification);

	PADBOX_VALID_END

	return self;
} /* initializeService */

-(void)openService
{
	PADBOX_VALID_BEGIN DACALDevicesInitialize(&DACALDevicesAddedWithService);

	PADBOX_VALID_END
}

-(void)addDACALDevice: (DACALDeviceNode *) newDevice
{
	[deviceList addObject: newDevice];
}

-(DACALDeviceNode *)DACALDeviceNodeForDeviceRef: (DACALDeviceRef) aBoxRef
{
	DACALDeviceNode * foundBox = nil;
	int               boxIndex, boxCount = [deviceList count];

	if (aBoxRef < kDACALIllegalDevice)
		aBoxRef = DACALDevicesCopyDeviceRefForIndex(aBoxRef, NULL);
	else
		DACALDeviceRetain(aBoxRef);

	for (boxIndex = 0; boxIndex < boxCount; boxIndex++) {
		foundBox = [deviceList objectAtIndex: boxIndex];
		if ([foundBox isDeviceRef: aBoxRef]) break;
		foundBox = nil;
	}

	DACALDeviceRelease(aBoxRef);

	return foundBox;
} /* DACALDeviceNodeForDeviceRef */

-(DACALSlot *)DACALDeviceSlotForDeviceRef: (DACALDeviceRef) aBoxRef andSlotNum: (DACALSlotNum) aSlotNum
{
	DACALDeviceNode * slotBox = [self DACALDeviceNodeForDeviceRef: aBoxRef];
	DACALSlot       * foundSlot = nil;

	if (slotBox)
		foundSlot = [slotBox slotWithNumber: aSlotNum];

	return foundSlot;
}

-(DACALSlot *)DACALDeviceSlotForSlotIdentifier: (NSString *) findID
{
	DACALSlot       * foundSlot = nil;
	DACALDeviceNode * workBox = nil;
	NSEnumerator    * boxEnum = [deviceList objectEnumerator];

	while (workBox = [boxEnum nextObject])
		if (foundSlot = [workBox slotWithIdentifier: findID])
			break;

	return foundSlot;
}

-(DACALSlotElement *)DACALDeviceSlotElementForURL: (NSURL *) itemURL
{
	DACALDeviceRef     searchDevice = CFURLCopyCarouselUUID(kCFAllocatorDefault, (CFURLRef)itemURL);
	DACALSlotNum       searchSlotNum = CFURLGetSlotNumber( (CFURLRef)itemURL, FALSE );
	DACALSlot        * searchSlot = [self DACALDeviceSlotForDeviceRef: searchDevice andSlotNum: searchSlotNum];
	DACALSlotElement * foundElement = nil;

	if (searchSlot != nil) {
		foundElement = [searchSlot elementWithURL: itemURL];
		if (foundElement == nil) {
			foundElement = [DACALSlotElement slotElementForSlot: searchSlot atLocation: itemURL];
		}
	}

	if (searchDevice) CFRelease( (CFTypeRef)searchDevice );
	return foundElement;
}

-(BOOL)countUsedSlots: (NSInteger *) outUsedSlotCount
{
	BOOL              freeSlot = NO;
	NSInteger         outCount = 0;
	NSInteger         limitCount = 50;      // [[PADLicenseService sharedLicenseService] licenseLimit];
	NSEnumerator    * deviceEnum = [deviceList objectEnumerator];
	DACALDeviceNode * workDevice = nil;

	while (workDevice = [deviceEnum nextObject])
		outCount += [workDevice slotsUsed];

	if ([[PADLicenseService sharedLicenseService] licenseValid] != YES)
		freeSlot = (limitCount >= outCount);
	else
		freeSlot = ([deviceList count] > 0);

	if (outUsedSlotCount != NULL)
		*outUsedSlotCount = outCount;

	return freeSlot;
} /* countUsedSlots */

-(NSNumber *)totalVolumeSize
{
	NSEnumerator    * slotEnum = [deviceList objectEnumerator];
	DACALDeviceNode * workDevice = nil;
	NSNumber        * workNumber = [NSNumber zero];

	while (workDevice = [slotEnum nextObject])
		workNumber = [workNumber addToNumber: [workDevice totalVolumeSize]];

	return workNumber;
}

-(void)notificationDeviceAttached: (DACALDeviceRef) inBoxRef
{
	[[DACALDeviceNode deviceWithDeviceRef: inBoxRef] attachingDevice];
	PMLOG(3, @"isDriverKextLoaded: %@", [DACDriverInstaller versionOfDriverKextLoaded]);
}

-(void)notificationDeviceDetached: (DACALDeviceRef) inBoxRef
{
	[[self DACALDeviceNodeForDeviceRef: inBoxRef] detachingDevice];
}

@end    //	DACALDeviceService