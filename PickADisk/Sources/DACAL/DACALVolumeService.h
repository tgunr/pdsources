//
//  DACALVolumeService.h
//  PickADisk
//
//  Created by Dave Carlton on 2/8/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VolumeService.h"

@class DACALVolume;
@class DACALDevice;
@class DACALSlot;

@interface DACALVolumeService : VolumeService {
}

-(NSArray *)knownVolumesWithIdentifier: (NSString *) theID;
-(void)newMediaDetected: (NSArray *) newMounts;
-(void)existingMediaRemoved: (NSString *) oldMediaPath;
-(NSArray *)knownIndexableVolumes: (NSArray *) testVolumeList;
-(DACALVolume *)knownVolumeWithPath: (NSString *) thePath;
-(NSArray *)knownSlotVolumes: (NSArray *) testVolumeList;
-(void)knownSlotsDetected: (NSArray *) knownSlotsList;
-(void)knownSlotRemoved: (DACALVolume *) knownSlotVolume;
-(void)carouselDeviceAttached: (DACALDevice *) aDevice;
-(void)carouselDeviceSlotAttached: (DACALSlot *) aSlot;
-(void)carouselDeviceDetached: (DACALDevice *) aDevice;

@end