//
// Created by davec on 8/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <PMUtility/pmUtility.h>
#import "DACALDeviceService.h"
#import "DACALSlotElement.h"
#import "DACALSlot.h"
#import "DACALDevice.h"
#import "DACALDeviceObjC.h"
#import "PADLifecycleSetup.h"
#import "LicenseService.h"

@implementation DACALDeviceService

-(NSMutableArray*)deviceList
	{ return deviceList; }

-(NSInteger)deviceCount
	{ return [deviceList count]; }

-(void)dealloc
{
	[deviceList release];
	[super dealloc];
}

-(void)initSelf
{
//	gDACALDevices = [[NSMutableArray alloc] initWithCapacity:0];
	deviceList = [[NSMutableArray alloc] initWithCapacity:0];
}

-(id)initializeService
{
	PADBOX_VALID_BEGIN

	DACALRegisterIconResource( CFSTR("DC300Black"), kDACALCarouselsFolderType );
	DACALRegisterIconResource( CFSTR("CDAudio"), 'cdda' );
	DACALRegisterIconResource( CFSTR("DVD-Video"), 'dvd ' );
	DACALRegisterIconResource( CFSTR("CD-silver"), 'Dcd ' );

	DACALRegisterIconResource( CFSTR("Generic_Files"), 'gFil' );
	DACALRegisterIconResource( CFSTR("Generic_Music"), 'gMus' );
	DACALRegisterIconResource( CFSTR("Generic_Movie"), 'gMov' );
	DACALRegisterIconResource( CFSTR("Generic_Image"), 'gImg' );

	DACALClientCreate( kPADClientIdentifier, (void*)self, DACALNotification );

	PADBOX_VALID_END

	return self;
}

-(void)openService
{
	PADBOX_VALID_BEGIN

	DACALDevicesInitialize();

	PADBOX_VALID_END
}

-(void)addDACALDevice:(DACALDevice*)newDevice
	{ [deviceList addObject:newDevice]; }

-(DACALDevice*)DACALDeviceForDeviceRef:(DACALDeviceRef)aBoxRef
{
	DACALDevice*	foundBox = nil;
	int                        boxCount = [deviceList count];
	NSUInteger boxIndex;

	if( aBoxRef < kDACALIllegalDevice )
		aBoxRef = DACALDevicesCopyDeviceRefForIndex( aBoxRef, NULL );
	else
		DACALDeviceRetain( aBoxRef );

	for( boxIndex=0; boxIndex < boxCount; boxIndex++ )
	{
		foundBox = [deviceList objectAtIndex:boxIndex];
		if( [foundBox isDeviceRef:aBoxRef] )
            break;
		foundBox = nil;
	}

	DACALDeviceRelease( aBoxRef );

	return foundBox;
}

-(DACALSlot*)DACALDeviceSlotForDeviceRef:(DACALDeviceRef)aBoxRef andSlotNum:(DACALSlotNum)aSlotNum
{
	DACALDevice*	slotBox = [self DACALDeviceForDeviceRef:aBoxRef];
	DACALSlot*		foundSlot = nil;

	if( slotBox )
		foundSlot = [slotBox slotWithNumber:aSlotNum];

	return foundSlot;
}

-(DACALSlot*)DACALDeviceSlotForSlotIdentifier:(NSString*)findID
{
	DACALSlot*		foundSlot = nil;
	DACALDevice*	workBox = nil;
	NSEnumerator*	boxEnum = [deviceList objectEnumerator];

	while ((workBox = [boxEnum nextObject]))
		if( (foundSlot = [workBox slotWithIdentifier:findID]) )
			break;

	return foundSlot;
}

-(DACALSlotElement*)DACALDeviceSlotElementForURL:(NSURL*)itemURL
{
	DACALDeviceRef		searchDevice = CFURLCopyCarouselUUID( kCFAllocatorDefault, (CFURLRef)itemURL );
	DACALSlotNum		searchSlotNum = CFURLGetSlotNumber( (CFURLRef)itemURL, FALSE );
	DACALSlot*			searchSlot = [self DACALDeviceSlotForDeviceRef:searchDevice andSlotNum:searchSlotNum];
	DACALSlotElement*	foundElement = nil;

	if(searchSlot != nil )
	{
		foundElement = [searchSlot elementWithURL:itemURL];
		if( foundElement == nil ) {
			foundElement = [DACALSlotElement slotElementForSlot:searchSlot atLocation:itemURL];
		}
	}

	if( searchDevice )
        CFRelease( (CFTypeRef)searchDevice );
	return foundElement;
}

-(BOOL)countUsedSlots:(NSInteger*)outUsedSlotCount
{
	BOOL				freeSlot = NO;
	NSInteger			outCount = 0;
	NSInteger			limitCount = 50;	// [[PADLicenseService sharedLicenseService] licenseLimit];
	NSEnumerator*		deviceEnum = [deviceList objectEnumerator];
	DACALDevice*		workDevice = nil;

	while ((workDevice = [deviceEnum nextObject]))
		outCount += [workDevice slotsUsed];

	if( [[PADLicenseService sharedLicenseService] licenseValid] != YES )
		freeSlot = (limitCount >= outCount);
	else
		freeSlot = ([deviceList count] > 0);

	if( outUsedSlotCount != NULL )
		*outUsedSlotCount = outCount;

	return freeSlot;
}

-(NSNumber*)totalVolumeSize
{
	NSEnumerator*	slotEnum = [deviceList objectEnumerator];
	DACALDevice*	workDevice = nil;
	NSNumber*		workNumber = [NSNumber zero];

	while ((workDevice = [slotEnum nextObject]))
		workNumber = [workNumber addToNumber:[workDevice totalVolumeSize]];

	return workNumber;
}


-(void)notificationDeviceAttached:(DACALDeviceRef)inBoxRef
{
	[[DACALDevice deviceWithDeviceRef:inBoxRef] attachingDevice];

	//NSLog(@"isDriverKextLoaded: %@", [DACDriverInstaller versionOfDriverKextLoaded]);
}

-(void)notificationDeviceDetached:(DACALDeviceRef)inBoxRef
{
	[[self DACALDeviceForDeviceRef:inBoxRef] detachingDevice];
}


@end	//	DACALDeviceService
