//
//  PADOperationControlDevice.h
//  PickADisk
//
//  Created by Jack Small on 8/17/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PADCarouselOperation.h"

@interface PADOperationControlDevice : PADOperationTask {
	DACALSlotNum		workSlot;
	DACALDeviceRef		otherDevice;
	DACALSlotNum		otherSlot;

	NSString*			ejectVolume;
	
	int					operType;
}

-(DACALSlotNum)workSlot;
-(void)setWorkSlot:(DACALSlotNum)newSlot;

-(DACALDeviceRef)otherDevice;
-(void)setOtherDevice:(DACALDeviceRef)newBox;

-(DACALSlotNum)otherSlot;
-(void)setOtherSlot:(DACALSlotNum)newSlot;

-(NSString*)ejectVolume;
-(void)setEjectVolume:(NSString*)volumePath;

-(id)initForBox:(DACALDeviceRef)newBox forSlot:(DACALSlotNum)newSlot ejectVolume:(NSString*)volumePath;

+(PADOperationControlDevice*)finishIndexingVolume:(NSString*)volumePath forSlot:(DACALSlotNum)newSlot onDevice:(DACALDeviceRef)newBox forTarget:(id)theTarget;

@end
