//
//  VolumeService.m
//  DACALTester
//
//  Created by Dave Carlton on 01/29/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import "VolumeService.h"
#import "Volume.h"
#import "dacalconstants.h"
#import "dacallib.h"
#import "NSArray_Extensions.h"
#import "NSString_Extensions.h"

@implementation VolumeService

-(void)dealloc
{
	if (knownVolumes != nil) 
		[knownVolumes release];
	if (pendingMounts != nil) 
		[pendingMounts release];
	if (pendingUnmounts != nil) 
		[pendingUnmounts release];

	knownVolumes = nil;
	pendingMounts = nil;
	pendingUnmounts = nil;

	[super dealloc];
}

-(void)initSelf
{
	kextBundles = NULL;

	// Create managed volumes list without autorelease
	knownVolumes    = [[NSMutableArray alloc] initWithCapacity: 0];
	pendingMounts   = [[NSMutableArray alloc] initWithCapacity: 0];
	pendingUnmounts = [[NSMutableArray alloc] initWithCapacity: 0];
}

-(id)initializeService
{
	[self scanMountedRemovableMedia];

	// Setup notifications for media changes
	NSNotificationCenter * noteCenter = [[NSWorkspace sharedWorkspace] notificationCenter];

	// Register for all mount notifications
	[noteCenter addObserver: self selector: @selector(newMediaDetectedNotification:)
	 name: @"NSWorkspaceDidMountNotification" object: nil];
	// Register for all unmount notifications
	[noteCenter addObserver: self selector: @selector(existingMediaRemovedNotification:)
	 name: @"NSWorkspaceWillUnmountNotification" object: nil];

	return self;
}

+(id)sharedVolumeService
{
	return [VolumeService sharedService];
}

-(CFArrayRef)kextBundles
{
	return kextBundles;
}

-(void)lazyInitKextBundles
{
	if (kextBundles != NULL) 
		return;

	// Although this might look crazy, it will ultimately give us access to the resources of any kext
	// simply by referencing the bundle ID. It is an expensive transaction, so we save it until we
	// absolutely must have it.

	CFURLRef allKextURLs = CFURLCreateWithString(kCFAllocatorDefault, CFSTR("file:///System/Library/Extensions/"), NULL);
	kextBundles = CFBundleCreateBundlesFromDirectory(kCFAllocatorDefault, allKextURLs, NULL);
	if (allKextURLs != NULL) 
		CFRelease(allKextURLs);
}

-(NSMutableArray *)pendingMounts
{
	return pendingMounts;
}

-(void)setPendingMounts: (NSMutableArray *) newMounts
{
	if (!pendingMounts || ![pendingMounts isEqual: newMounts]) {
		if (newMounts) 
			[newMounts retain];
		if (pendingMounts) 
			[pendingMounts release];
		pendingMounts = newMounts;
	}
}

-(void)addPendingMount: (NSString *) knownDACDiskID
{
	if (pendingMounts)
		if ([pendingMounts indexOfObject: knownDACDiskID] == NSNotFound)
			[pendingMounts addObject: knownDACDiskID];
}

-(void)removePendingMount: (NSString *) foundDACDiskID
{
	if (pendingMounts)
		[pendingMounts removeObject: foundDACDiskID];
}

-(BOOL)isPendingMount: (NSString *) aDACDiscID
{
	BOOL haveID = NO;

	if (pendingMounts)
		haveID = ([pendingMounts indexOfObject: aDACDiscID] != NSNotFound);

	if (haveID == YES)
		[self removePendingMount: aDACDiscID];

	return haveID;
}

-(NSMutableArray *)pendingUnmounts
{
	return pendingUnmounts;
}

-(void)setPendingUnmounts: (NSMutableArray *) newUnmounts
{
	if (!pendingUnmounts || ![pendingUnmounts isEqual: newUnmounts]) {
		if (newUnmounts) 
			[newUnmounts retain];
		if (pendingUnmounts) [pendingUnmounts release];
		pendingUnmounts = newUnmounts;
	}
}

-(void)addPendingUnmount: (NSString *) knownDACDiskID
{
	if (pendingUnmounts)
		if ([pendingUnmounts indexOfObject: knownDACDiskID] == NSNotFound)
			[pendingUnmounts addObject: knownDACDiskID];
}

-(void)removePendingUnmount: (NSString *) foundDACDiskID
{
	if (pendingUnmounts)
		[pendingUnmounts removeObject: foundDACDiskID];
}

-(BOOL)isPendingUnmount: (NSString *) aDACDiscID
{
	BOOL haveID = NO;

	if (pendingUnmounts)
		haveID = ([pendingUnmounts indexOfObject: aDACDiscID] != NSNotFound);

	if (haveID == YES)
		[self removePendingUnmount: aDACDiscID];

	return haveID;
}

-(NSMutableArray *)knownVolumes
{
	return knownVolumes;
}

-(Volume *)knownVolumeWithURL: (NSURL *) theURL
{
	NSInteger   knownCount = [knownVolumes count];
	NSInteger   knownIndex = 0;
	Volume *	testVolume = nil;

	for (knownIndex = 0; knownIndex < knownCount; knownIndex++) {
		testVolume = [knownVolumes objectAtIndex: knownIndex];
		if ([testVolume isVolumeURL: theURL] == YES)
			return testVolume;
	}

	return nil;
}

-(Volume *)knownVolumeWithPath: (NSString *) thePath
{
	NSURL     * theURL = [[NSURL alloc] initFileURLWithPath: thePath];
	Volume * theVolume = [self knownVolumeWithURL: theURL];

	[theURL release];

	return theVolume;
}


// Notification methods

-(void)newMediaDetected: (NSArray *) newMounts
{
	NSArray  * newVolumes = [Volume detectedMounts: [newMounts arrayOfURLsFromPaths]];

//	NSArray       * knownMounts = [self knownSlotVolumes: newVolumes];
//	NSArray       * indexMounts = [self knownIndexableVolumes: newVolumes];

	PMLOG(2, @"Mounted Volumes: %@", newVolumes);

	[knownVolumes addUniqueObjectsFromArray: newVolumes];

} /* newMediaDetected */

-(void)scanMountedRemovableMedia
{
	NSArray * mediaPaths = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];

	[self newMediaDetected: mediaPaths];
}

-(void)existingMediaRemoved: (NSString *) oldMediaPath
{
	Volume * foundMedia = [self knownVolumeWithPath: oldMediaPath];

	if (foundMedia) {
		PMLOG(2, @"Removed Volume: %@", oldMediaPath);
		DACALDeviceRef deviceRef = 0;
	}
	
	//	Actually remove from our list
	[knownVolumes removeObject: foundMedia];
	[foundMedia release];
} /* existingMediaRemoved */

-(void)newMediaDetectedNotification: (id) aNotification
{
	[self newMediaDetected: [NSArray arrayWithObject: [NSString stringWithString: [[aNotification userInfo] valueForKey: @"NSDevicePath"]]]];
}

-(void)existingMediaRemovedNotification: (id) aNotification
{
	[self existingMediaRemoved: [NSString stringWithString: [[aNotification userInfo] valueForKey: @"NSDevicePath"]]];
}


@end