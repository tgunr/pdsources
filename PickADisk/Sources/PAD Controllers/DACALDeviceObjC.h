//
//  DACALDevice.h
//  PickADisk
//
//  Created by Jack Small on 9/3/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "pmsDACALUtility.h"
#import "SimpleTreeNode.h"

extern CFStringRef			kPADClientIdentifier;

//	Slot reservation dictionary keys
extern	NSString*	kDACSlotReservationTime;
extern  NSString*	kDACSlotReservationType;
extern	NSString*	kDACSlotReservationUser;
extern	NSString*	kDACSlotReservationHost;

extern	NSString*	kDACSlotReservationTypeCheckOut;
extern	NSString*	kDACSlotReservationTypeCheckIn;

@class DACALSlotElement;
@class DACALSlot;
@class DACALDevice;

extern void					DACALSetup( void );
extern void					DACALClientInitialize(void);
extern DACALDevice*			DACALDeviceForDeviceRef(DACALDeviceRef aBoxRef);
extern DACALSlot*			DACALDeviceSlotForSlotNumber(DACALDeviceRef aBoxRef, DACALSlotNum aSlotNum);
extern DACALSlotElement*	DACALDeviceSlotElementForURL( CFURLRef itemURL );

@interface DACALSlotElement : NSObject {

	DACALSlot*			elementSlot;
	SimpleTreeNode*		elementNode;
	FSRef				elementFSRef;
	NSURL*				elementURL;
}

-(DACALSlot*)elementSlot;
-(FSRef*)elementFSRef;
-(NSURL*)elementURL;
-(BOOL)isElementFSRef:(const FSRef*)otherFSRef;
-(BOOL)isElementURL:(NSURL*)otherURL;

-(SimpleTreeNode*)elementNode;
-(void)setElementNode:(SimpleTreeNode*)newNode;

-(id)initElementForSlot:(DACALSlot*)newSlot atLocation:(NSURL*)newLoc;
+(id)slotElementForSlot:(DACALSlot*)newSlot atLocation:(NSURL*)newLoc;
+(id)slotElementForNode:(SimpleTreeNode*)newNode;

-(void)reloadElement;

-(NSString*)title;
-(void)setTitle:(NSString*)newTitle;

-(NSString*)flavor;
-(void)setFlavor:(NSString*)newFlavor;

-(BOOL)isCheckedOut;
-(NSDate*)checkedOutDate;

@end		// DACALSlotElement


@interface DACALSlot : NSObject {
	
	DACALDevice*		slotDevice;
	DACALSlotNum		slotNumber;

	SimpleTreeNode*		slotNode;
	FSRef				slotFSRef;
	
	NSDate*				slotCheckedOut;
	NSMutableArray*		slotElements;
}



-(DACALDevice*)slotDevice;
-(DACALSlotNum)slotNumber;
-(SimpleTreeNode*)slotNode;
-(FSRef*)slotFSRef;
-(BOOL)setSlotFSRefFromURL:(NSURL*)slotURL;
-(BOOL)setSlotLocation:(NSURL*)slotURL;

-(NSMutableArray*)slotElements;
-(void)setSlotElements:(NSMutableArray*)newElements;
-(void)addSlotElement:(DACALSlotElement*)newElement;
-(void)removeSlotElement:(DACALSlotElement*)oldElement;

-(DACALSlotElement*)elementWithFSRef:(const FSRef*)otherFSRef;
-(DACALSlotElement*)elementWithURL:(NSURL*)otherURL;

-(id)initSlotForDevice:(DACALDevice*)newDevice inSlot:(DACALSlotNum)newSlot;
+(id)slotForDevice:(DACALDevice*)newDevice inSlot:(DACALSlotNum)newSlot;

-(void)reloadSlot;
-(void)reloadElement:(DACALSlotElement*)theElement;

-(void)swapWithSlot:(DACALSlot*)otherSlot;

-(NSString*)title;
-(NSURL*)fileURL;

-(NSString*)flavor;
-(void)setFlavor:(NSString*)newFlavor;

-(BOOL)isCheckedOut;
-(NSDate*)checkedOutDate;
-(void)setCheckedOutDate:(NSDate*)newDate;
-(NSDictionary*)currentReservation;
-(NSDictionary*)reservationHistory;
-(BOOL)checkOutForUser:(NSString*)userName onHost:(NSString*)userHost;
-(BOOL)checkInForUser:(NSString*)userName onHost:(NSString*)userHost;

@end		// DACALSlot

@interface DACALDevice : NSObject {
	
	DACALDeviceRef		deviceRef;
	SimpleTreeNode*		deviceNode;
	FSRef				deviceFSRef;

	NSArray*			deviceSlots;
	
}

-(DACALDeviceRef)deviceRef;
-(void)setDeviceRef:(DACALDeviceRef)newDevice;
-(BOOL)isDeviceRef:(DACALDeviceRef)aDevice;

-(SimpleTreeNode*)deviceNode;
-(void)setDeviceNode:(SimpleTreeNode*)newNode;

-(FSRef*)deviceFSRef;
-(NSArray*)deviceSlots;

-(DACALSlot*)slotWithNumber:(DACALSlotNum)aSlot;
-(void)loadSlotIndex;
-(void)indexedNewVolume:(NSURL*)newVolume forSlot:(DACALSlotNum)newSlot ofType:(NSString*)newType;
-(void)swapSlotNumber:(DACALSlotNum)fromSlotNum toDevice:(DACALDevice*)toBox toSlotNumber:(DACALSlotNum)toSlotNum;

-(id)initDeviceWithDeviceRef:(DACALDeviceRef)newDeviceRef;
+(id)deviceWithDeviceRef:(DACALDeviceRef)newDeviceRef;

-(NSString*)title;
-(NSURL*)fileURL;

-(void)attachingDevice;
-(void)attachedDevice:(DACALDevice*)newBox;
-(void)detachingDevice;


@end		// DACALDevice

