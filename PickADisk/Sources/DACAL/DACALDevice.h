//
// Created by davec on 8/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Cocoa/Cocoa.h>
#import <DACAL/dacallib.h>

@class SimpleTreeNode;
@class DACALSlot;
@class DACVolume;


@interface DACALDevice : NSObject {

	DACALDeviceRef		deviceRef;
	SimpleTreeNode*		deviceNode;
	FSRef				deviceFSRef;

	NSArray*			deviceSlots;
	NSInteger			slotsUsed;

}

-(DACALDeviceRef)deviceRef;
-(void)setDeviceRef:(DACALDeviceRef)newDevice;
-(BOOL)isDeviceRef:(DACALDeviceRef)aDevice;

-(SimpleTreeNode*)deviceNode;
-(void)setDeviceNode:(SimpleTreeNode*)newNode;

//- (NSUndoManager*)undoManager;

-(FSRef*)deviceFSRef;
-(NSArray*)deviceSlots;

-(DACALSlot*)slotWithNumber:(DACALSlotNum)aSlot;
-(DACALSlot*)slotWithIdentifier:(NSString*)slotID;
-(void)loadSlotIndex;
-(void)indexedNewVolume:(DACVolume*)newVolume forSlot:(DACALSlotNum)newSlot ofType:(NSString*)newTypem forTarget:(id)finishedTarget;
-(void)indexUnassignedForSlot:(DACALSlot*)oldSlot;
-(void)swapSlotNumber:(DACALSlotNum)fromSlotNum toDevice:(DACALDevice*)toBox toSlotNumber:(DACALSlotNum)toSlotNum;

-(id)initDeviceWithDeviceRef:(DACALDeviceRef)newDeviceRef;
+(id)deviceWithDeviceRef:(DACALDeviceRef)newDeviceRef;

-(NSString*)title;
-(NSURL*)fileURL;

-(void)attachingDevice;
-(void)attachedDevice:(DACALDevice*)newBox;
-(void)detachingDevice;

-(NSInteger)slotsUsed;
-(NSNumber*)totalVolumeSize;

-(DACALResult)commandCloseDoor;

@end		//	DACALDevice

