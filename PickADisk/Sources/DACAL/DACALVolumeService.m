//
//  DACALVolume.m
//  PickADisk
//
//  Created by Dave Carlton on 2/8/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import "DACALVolumeService.h"
#import "DACALVolume.h"
#import "DACALSlot.h"
#import "AppController.h"
#import "dacalconstants.h"
#import "NSArray_Extensions.h"
#import "TreeController.h"
#import "PADIndexToolbarController.h"

@implementation DACALVolumeService

-(id)initializeService {
	return [super initializeService];
}

-(NSArray *)knownVolumesWithIdentifier: (NSString *) theID
{
	NSEnumerator   * knownEnum = [knownVolumes objectEnumerator];
	DACALVolume    * workVolume = nil;
	NSMutableArray * matchArray = [[NSMutableArray alloc] initWithCapacity: 0];
	NSArray        * outArray = nil;
	
	while (workVolume = [knownEnum nextObject])
		if ([workVolume isIdentifiedAs: theID])
			[matchArray addObject: workVolume];
	
	outArray = [NSArray arrayWithArray: matchArray];
	[matchArray release];
	
	return outArray;
}

-(void)newMediaDetected: (NSArray *) newMounts
{
	NSArray  * newVolumes = [DACALVolume detectedMounts: [newMounts arrayOfURLsFromPaths]];
	NSWindow * mainWindow = [[[[AppController shared] dataView] outlineView] window];

	NSArray       * knownMounts = [self knownSlotVolumes: newVolumes];
	NSArray       * indexMounts = [self knownIndexableVolumes: newVolumes];
	AppController * AppControl = [AppController shared];
	NSInteger       unrecogAction = [[NSUserDefaults standardUserDefaults] integerForKey: kDACDiscKeyUnrecognized];

	PMLOG(2, @"Mounted Volumes: %@", newVolumes);

	[knownVolumes addUniqueObjectsFromArray: newVolumes];

	if ( (unrecogAction == kDACDVUnknownIDDisplayAddWindow) )
		if ( ([indexMounts count] > 0) && (mainWindow != nil) && ([mainWindow attachedSheet] == nil) )
			[[AppControl toolbarController] clickAssign: self];

	//	Notify the Add Volumes Window
	if ([indexMounts count] > 0)
		[[AppControl addVolumeController] 
		 performSelectorOnMainThread: @selector(detectedVolumes:)
						  withObject: indexMounts
					   waitUntilDone: YES];

	if ([knownMounts count] > 0)
		[self knownSlotsDetected: knownMounts];
} /* newMediaDetected */

-(void)existingMediaRemoved: (NSString *) oldMediaPath
{
	DACALVolume * foundMedia = [self knownVolumeWithPath: oldMediaPath];

	if (foundMedia) {
		PMLOG(2, @"Removed Volume: %@", oldMediaPath);

		//	Notify the Add Volumes Window
		if ([foundMedia isIndexable] == YES)
			[[[AppController shared] addVolumeController] performSelectorOnMainThread: @selector(ejectedVolumes:)
			 withObject: [NSArray arrayWithObject: foundMedia]
			 waitUntilDone: YES];
		[self knownSlotRemoved: foundMedia];

		DACALDeviceRef deviceRef = 0;
		deviceRef = [foundMedia padKnownDevice];
		if (deviceRef) {
			// This should probably be moved into a DACALDevice method
			// If this slot beloags to a Powerdrive we need to send a eject command while the volume is unmounted
			if ( DACALIsDC016(deviceRef) )
				DACALCommandDVDEject(deviceRef);
		}
	}

	//	Actually remove from our list
	[knownVolumes removeObject: foundMedia];
	[foundMedia release];
} /* existingMediaRemoved */

-(NSArray *)knownIndexableVolumes: (NSArray *) testVolumeList
{
	if (testVolumeList == nil)
		testVolumeList = [self knownVolumes];

	NSEnumerator   * listEnum = [testVolumeList objectEnumerator];
	NSMutableArray * buildArray = [NSMutableArray arrayWithCapacity: 0];
	DACALVolume    * workVolume = nil;

	while (workVolume = [listEnum nextObject])
		if ([workVolume isIndexable] == YES)
			[buildArray addObject: workVolume];

	return [NSArray arrayWithArray: buildArray];
}

-(DACALVolume *)knownVolumeWithPath: (NSString *) thePath
{
	NSURL     * theURL = [[NSURL alloc] initFileURLWithPath: thePath];
	DACALVolume * theVolume = [self knownVolumeWithURL: theURL];
	
	[theURL release];
	
	return theVolume;
}

-(NSArray *)knownSlotVolumes: (NSArray *) testVolumeList
{
	if (testVolumeList == nil)
		testVolumeList = [self knownVolumes];

	NSEnumerator   * listEnum = [testVolumeList objectEnumerator];
	NSMutableArray * buildArray = [NSMutableArray arrayWithCapacity: 0];
	DACALVolume    * workVolume = nil;

	while (workVolume = [listEnum nextObject])
		if ([workVolume padKnownSlot] != nil)
			[buildArray addObject: workVolume];

	return [NSArray arrayWithArray: buildArray];
}

-(void)knownSlotsDetected: (NSArray *) knownSlotsList
{
	NSEnumerator * slotEnum = [knownSlotsList objectEnumerator];
	DACALVolume    * workVolume = nil;
	BOOL           slotsOK = NO;
	NSInteger      recognizedAction = [[NSUserDefaults standardUserDefaults] integerForKey: kDACDiscKeyRecognized];

	if (recognizedAction != kDACDVKnownIDAutoCheckIn)
		return;

	while (workVolume = [slotEnum nextObject])
		if ([[workVolume padKnownSlot] slotVolume] == nil)
			slotsOK = [[workVolume padKnownSlot] slotMountedAsVolume: workVolume];

	//[AppController playUISoundForBOOL:slotsOK];
}

-(void)knownSlotRemoved: (DACALVolume *) knownSlotVolume
{
	DACALSlot * slotVolume = [knownSlotVolume padKnownSlot];
	BOOL        slotsOK = NO;

	if (slotVolume)
		slotsOK = [slotVolume slotUnmounted];

	//[AppController playUISoundForBOOL:slotsOK];
}

-(void)carouselDeviceAttached: (DACALDevice *) aDevice
{
	//[self scanMountedRemovableMedia];
}

-(void)carouselDeviceSlotAttached: (DACALSlot *) aSlot
{
	NSArray      * matchVolumes = nil;
	NSEnumerator * matchEnum = nil;
	DACALVolume    * workVolume = nil;

	if (aSlot && [aSlot slotIdentifier]) {
		if ([knownVolumes count]) {
			DACALVolume * volume = [knownVolumes objectAtIndex: 0];
			if (volume)
				[volume setPadKnownDevice: [[aSlot slotDevice] deviceRef]];
		}
		matchVolumes = [self knownVolumesWithIdentifier: [aSlot slotIdentifier]];
		matchEnum = [matchVolumes objectEnumerator];

		while (workVolume = [matchEnum nextObject])
			if (![workVolume padKnownVolume])
				[workVolume setPadKnownSlot: aSlot];

		if ([matchVolumes count] > 0) {
			if ([[[matchVolumes objectAtIndex: 0] padKnownSlot] isEqual: aSlot]) {
				[[VolumeService sharedVolumeService] addPendingMount: [aSlot slotIdentifier]];
				[aSlot slotMountedAsVolume: [matchVolumes objectAtIndex: 0]];
			}
		}
	}
} /* carouselDeviceSlotAttached */

-(void)carouselDeviceDetached: (DACALDevice *) aDevice
{

}

@end