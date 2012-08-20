//
// Created by davec on 8/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Cocoa/Cocoa.h>
#import <DACAL/dacallib.h>
#import "JSServiceManager.h"

@class DACALSlotElement;
@class DACALSlot;
@class DACALDevice;

@interface DACALDeviceService : JSServiceAbstract
{
	NSMutableArray*			deviceList;
}

-(NSMutableArray*)deviceList;
-(NSInteger)deviceCount;

-(void)addDACALDevice:(DACALDevice*)newDevice;

-(DACALDevice*)DACALDeviceForDeviceRef:(DACALDeviceRef)aBoxRef;
-(DACALSlot*)DACALDeviceSlotForDeviceRef:(DACALDeviceRef)aBoxRef andSlotNum:(DACALSlotNum)aSlotNum;
-(DACALSlot*)DACALDeviceSlotForSlotIdentifier:(NSString*)findID;
-(DACALSlotElement*)DACALDeviceSlotElementForURL:(NSURL*)itemURL;

-(BOOL)countUsedSlots:(NSInteger*)outUsedSlotCount;
-(NSNumber*)totalVolumeSize;

-(void)notificationDeviceAttached:(DACALDeviceRef)inBoxRef;
-(void)notificationDeviceDetached:(DACALDeviceRef)inBoxRef;

@end		//	DACALDeviceService
