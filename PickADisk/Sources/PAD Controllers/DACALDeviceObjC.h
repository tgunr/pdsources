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
#import "DACVolume.h"

extern CFStringRef			kPADClientIdentifier;

//	Slot reservation dictionary keys
extern	NSString*	kDACSlotReservationKeyTime;
extern  NSString*	kDACSlotReservationKeyType;
extern	NSString*	kDACSlotReservationKeyUser;
extern	NSString*	kDACSlotReservationKeyHost;
extern	NSString*	kDACSlotReservationKeyCountCheckOut;

extern	NSString*	kDACSlotReservationTypeCheckOut;
extern	NSString*	kDACSlotReservationTypeCheckIn;

extern	NSString*	kDACBookmarkLocationInSidebar;
extern	NSString*	kDACBookmarkLocationInMenubar;
extern	NSString*	kDACBookmarkLocationInBookmarks;


@class DACALSlotElement;
@class DACALSlot;
@class DACALDevice;

extern void					DACALSetup( void );
extern void					DACALClientInitialize(void);
extern DACALDevice*			DACALDeviceForDeviceRef(DACALDeviceRef aBoxRef);
extern DACALSlot*			DACALDeviceSlotForSlotNumber(DACALDeviceRef aBoxRef, DACALSlotNum aSlotNum);
extern DACALSlot*			DACALDeviceSlotForSlotIdentifier( CFStringRef findID );
extern DACALSlotElement*	DACALDeviceSlotElementForURL( CFURLRef itemURL );

extern NSMutableArray*		gDACALDevices;

@interface DACALSlotElementBookmark : NSObject
{
	DACALSlotElement*	markElement;
	NSString*			markLocation;
	SimpleTreeNode*		markNode;
}

-(DACALSlotElement*)markElement;
-(NSString*)markLocation;
-(SimpleTreeNode*)markNode;

-(BOOL)isBookmarkLocation:(NSString*)theLocation;
-(BOOL)removeBookmark;
-(void)removeMarkNode;

-(id)initBookmarkForElement:(DACALSlotElement*)theElement atLocation:(NSString*)theLocation attachNow:(BOOL)doAttach;
+(id)bookmarkForElement:(DACALSlotElement*)theElement atLocation:(NSString*)theLocation attachNow:(BOOL)doAttach;

@end	//	DACALSlotElementBookmark


@interface DACALSlotElement : NSObject {

	DACALSlot*			elementSlot;
	SimpleTreeNode*		elementNode;
	FSRef				elementFSRef;
	NSURL*				elementURL;
	
	NSMutableArray*		elementBookmarks;
	
	NSString*			comments;
	NSArray*			tags;
	NSInteger			stars;
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

-(void)updateElementChanges:(BOOL)doAction;
-(void)reloadElement;

-(NSString*)title;
-(void)setTitle:(NSString*)newTitle;

-(NSString*)flavor;
-(void)setFlavor:(NSString*)newFlavor;

-(BOOL)isCheckedOut;
-(NSDate*)checkedOutDate;
-(NSDate*)checkedInDate;

-(NSString*)comments;
-(void)setComments:(NSString*)newComment;

-(NSArray*)tags;
-(void)setTags:(NSArray*)newTags;

-(NSInteger)stars;
-(void)setStars:(NSInteger)starLevel;

-(NSMutableArray*)bookmarks;
-(BOOL)removeBookmarkForLocation:(NSString*)markLocation;
-(DACALSlotElementBookmark*)bookmarkForLocation:(NSString*)markLocation;
-(DACALSlotElementBookmark*)createBookmarkAtLocation:(NSString*)markLocation attachNow:(BOOL)doAttach;

@end		// DACALSlotElement


@interface DACALSlot : NSObject {
	
	DACALDevice*		slotDevice;
	DACALSlotNum		slotNumber;

	SimpleTreeNode*		slotNode;
	DACVolume*			slotVolume;
	FSRef				slotFSRef;
	
	NSString*			slotIdentifier;
	
	BOOL				slotIsCheckedOut;
	NSDate*				slotCheckedOut;
	NSDate*				slotCheckedIn;
	
	NSMutableArray*		slotElements;
}



-(DACALDevice*)slotDevice;
-(DACALDeviceRef)slotDeviceRef;
-(DACALSlotNum)slotNumber;
-(SimpleTreeNode*)slotNode;
-(DACVolume*)slotVolume;
-(FSRef*)slotFSRef;
-(BOOL)validSlotFSRef;
-(BOOL)setSlotFSRefFromURL:(NSURL*)slotURL;
-(BOOL)setSlotLocation:(NSURL*)slotURL;

-(NSMutableArray*)slotElements;
-(void)setSlotElements:(NSMutableArray*)newElements;
-(void)addSlotElement:(DACALSlotElement*)newElement;
-(void)removeSlotElement:(DACALSlotElement*)oldElement;

-(DACALSlotElement*)elementWithFSRef:(const FSRef*)otherFSRef;
-(DACALSlotElement*)elementWithURL:(NSURL*)otherURL;

-(NSString*)slotIdentifier;
-(void)setSlotIdentifier:(NSString*)newID;
-(DACALSlot*)slotWithIdentifier:(NSString*)slotID;

-(id)initSlotForDevice:(DACALDevice*)newDevice inSlot:(DACALSlotNum)newSlot;
+(id)slotForDevice:(DACALDevice*)newDevice inSlot:(DACALSlotNum)newSlot;

-(void)reloadSlot;
-(void)reloadElement:(DACALSlotElement*)theElement;

-(void)swapWithSlot:(DACALSlot*)otherSlot;

-(NSString*)title;
-(NSURL*)fileURL;

-(NSString*)flavor;
-(void)setFlavor:(NSString*)newFlavor;

-(DACALResult)moveDeviceToSlotWithOptions:(DACALOptionBits)slotOptions;

-(BOOL)isCheckedOut;
-(void)setIsCheckedOut:(BOOL)isOut;

-(NSDate*)checkedOutDate;
-(void)setCheckedOutDate:(NSDate*)newDate;

-(NSDate*)checkedInDate;
-(void)setCheckedInDate:(NSDate*)newDate;

-(NSDictionary*)currentReservation;
-(NSDictionary*)reservationHistory;

-(BOOL)checkOutForUser:(NSString*)userName onHost:(NSString*)userHost withUI:(BOOL)doUI;
-(BOOL)checkInForUser:(NSString*)userName onHost:(NSString*)userHost withUI:(BOOL)doUI;
-(BOOL)toggleReservationForUser:(NSString*)userName	onHost:(NSString*)userHost withUI:(BOOL)doUI;

-(BOOL)isSlotMounted;
-(NSString*)slotHost;
-(BOOL)slotMountedAsVolume:(DACVolume*)mountVolume;
-(BOOL)slotUnmounted;




@end		// DACALSlot

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

-(FSRef*)deviceFSRef;
-(NSArray*)deviceSlots;

-(DACALSlot*)slotWithNumber:(DACALSlotNum)aSlot;
-(DACALSlot*)slotWithIdentifier:(NSString*)slotID;
-(void)loadSlotIndex;
-(void)indexedNewVolume:(DACVolume*)newVolume forSlot:(DACALSlotNum)newSlot ofType:(NSString*)newType;
-(void)swapSlotNumber:(DACALSlotNum)fromSlotNum toDevice:(DACALDevice*)toBox toSlotNumber:(DACALSlotNum)toSlotNum;

-(id)initDeviceWithDeviceRef:(DACALDeviceRef)newDeviceRef;
+(id)deviceWithDeviceRef:(DACALDeviceRef)newDeviceRef;

-(NSString*)title;
-(NSURL*)fileURL;

-(void)attachingDevice;
-(void)attachedDevice:(DACALDevice*)newBox;
-(void)detachingDevice;

-(NSInteger)slotsUsed;

-(DACALResult)commandCloseDoor;

@end		// DACALDevice

