//
//  DACALDeviceSerivce.h
//  PickADisk
//
//  Created by Dave Carlton on 01/11/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "dacallib.h"
#import "JSTestService.h"

@class DACALDeviceNode;
@class DACALSlot;
@class DACALSlotElement;

@interface DACALDeviceService : JSServiceAbstract
{
	NSMutableArray*			deviceList;
}

@property (assign) NSMutableArray* deviceList;

-(NSInteger)deviceCount;

-(void)addDACALDevice:(DACALDeviceNode*)newDevice;

-(DACALDeviceNode*)DACALDeviceNodeForDeviceRef:(DACALDeviceRef)aBoxRef;
-(DACALSlot*)DACALDeviceSlotForDeviceRef:(DACALDeviceRef)aBoxRef andSlotNum:(DACALSlotNum)aSlotNum;
-(DACALSlot*)DACALDeviceSlotForSlotIdentifier:(NSString*)findID;
-(DACALSlotElement*)DACALDeviceSlotElementForURL:(NSURL*)itemURL;

-(BOOL)countUsedSlots:(NSInteger*)outUsedSlotCount;
-(NSNumber*)totalVolumeSize;

-(void)notificationDeviceAttached:(DACALDeviceRef)inBoxRef;
-(void)notificationDeviceDetached:(DACALDeviceRef)inBoxRef;

@end		//	DACALDeviceService
