//
//  DACALDeviceNode.h
//  DACALTester
//
//  Created by Dave Carlton on 01/11/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import "DACALDevice.h"
#import "dacallib.h"

@class SimpleTreeNode;
@class DACALSlotElement;
@class DACALSlot;
@class DACALVolume;

@interface DACALDeviceNode : DACALDevice {
	SimpleTreeNode * deviceNode;
	NSArray        * deviceSlots;
	NSInteger        slotsUsed;
}

@property (assign) SimpleTreeNode * deviceNode;
@property (assign) NSArray        * deviceSlots;
@property (assign) NSInteger        slotsUsed;

-(DACALSlot *)slotWithNumber: (DACALSlotNum) aSlot;
-(DACALSlot *)slotWithIdentifier: (NSString *) slotID;
-(void)indexUnassignedForSlot: (DACALSlot *) oldSlot;

-(id)initDeviceWithDeviceRef: (DACALDeviceRef) newDeviceRef;
-(void)loadSlotIndex;
-(void)indexedNewVolume: (DACALVolume *) newVolume forSlot: (DACALSlotNum) newSlot ofType: (NSString *) newTypem forTarget: (id) finishedTarget;
-(void)swapSlotNumber: (DACALSlotNum) fromSlotNum toDevice: (DACALDeviceNode *) toBox toSlotNumber: (DACALSlotNum) toSlotNum;
-(void)attachingDevice;
-(void)attachedDevice: (DACALDeviceNode *) newBox;
-(void)detachingDevice;
-(NSNumber *)totalVolumeSize;
-(NSArray *)deviceSlots;
-(NSInteger)slotsUsed;

@end

extern void DACALNotification(void * inData, DACALDeviceRef inBox, CFStringRef inMessage, CFDictionaryRef inParam);
extern DACALDeviceNode *     DACALDeviceNodeForDeviceRef(DACALDeviceRef aBoxRef);
extern DACALSlot *           DACALDeviceSlotForSlotNumber(DACALDeviceRef aBoxRef, DACALSlotNum aSlotNum);
extern DACALSlot *           DACALDeviceSlotForSlotIdentifier(CFStringRef findID);
extern DACALSlotElement *    DACALDeviceSlotElementForURL(CFURLRef itemURL);