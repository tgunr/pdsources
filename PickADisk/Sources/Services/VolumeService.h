//
//  VolumeService.h
//  DACALTester
//
//  Created by Dave Carlton on 01/29/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSServiceManager.h"

@class Volume;

@interface VolumeService : JSServiceAbstract {

	CFArrayRef       kextBundles;
	NSMutableArray * knownVolumes;
	
	NSMutableArray * pendingMounts;
	NSMutableArray * pendingUnmounts;
}

-(CFArrayRef)kextBundles;
-(void)lazyInitKextBundles;

-(NSMutableArray *)pendingMounts;
-(void)setPendingMounts: (NSMutableArray *) newMounts;
-(void)addPendingMount: (NSString *) knownDACDiskID;
-(void)removePendingMount: (NSString *) foundDACDiskID;
-(BOOL)isPendingMount: (NSString *) aDACDiscID;

-(NSMutableArray *)pendingUnmounts;
-(void)setPendingUnmounts: (NSMutableArray *) newUnmounts;
-(void)addPendingUnmount: (NSString *) knownDACDiskID;
-(void)removePendingUnmount: (NSString *) foundDACDiskID;
-(BOOL)isPendingUnmount: (NSString *) aDACDiscID;

-(NSMutableArray *)knownVolumes;
-(Volume *)knownVolumeWithURL: (NSURL *) theURL;
-(Volume *)knownVolumeWithPath: (NSString *) thePath;

-(void)newMediaDetected: (NSArray *) newMounts;
-(void)scanMountedRemovableMedia;
-(void)existingMediaRemoved: (NSString *) oldMediaPath;

-(void)newMediaDetectedNotification: (id) aNotification;

+(id)sharedVolumeService;

@end
