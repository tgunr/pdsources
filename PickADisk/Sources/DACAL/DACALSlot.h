//
//  DACALSlot.h
//  DACALTester
//
//  Created by Dave Carlton on 01/11/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SimpleTreeNode.h"

@class DACALSlotElementBookmark;
@class DACALSlot;
@class DACALDeviceNode;
@class SimpleTreeNode;
@class DACALSlotElementBookmark;

@interface DACALSlotElement : NSObject {
	DACALSlot      * elementSlot;
	SimpleTreeNode * elementNode;
	FSRef            elementFSRef;
	NSURL          * elementURL;
	NSMutableArray * elementBookmarks;
	NSString       * comments;
	NSArray        * tags;
	NSInteger        stars;
}

-(DACALSlot *)elementSlot;
-(DACALDeviceNode *)elementDevice;
-(FSRef *)elementFSRef;
-(NSURL *)elementURL;
-(BOOL)isElementFSRef : (const FSRef *)otherFSRef;
-(BOOL)isElementURL   : (NSURL *)otherURL;

-(SimpleTreeNode *)elementNode;
-(void)setElementNode : (SimpleTreeNode *)newNode;

//- (NSUndoManager*)undoManager;

-(id)initElementForSlot : (DACALSlot *)newSlot atLocation : (NSURL *)newLoc;
+(id)slotElementForSlot : (DACALSlot *)newSlot atLocation : (NSURL *)newLoc;
+(id)slotElementForNode : (SimpleTreeNode *)newNode;

-(void)updateElementChanges : (BOOL)doAction;
-(void)reloadElement;

-(NSString *)title;
-(void)setTitle : (NSString *)newTitle;

-(NSString *)flavor;
-(void)setFlavor : (NSString *)newFlavor;

-(BOOL)isCheckedOut;
-(NSDate *)checkedOutDate;
-(NSDate *)checkedInDate;

-(NSString *)comments;
-(void)setComments : (NSString *)newComment;

-(NSArray *)tags;
-(void)setTags : (NSArray *)newTags;

-(NSInteger)stars;
-(void)setStars : (NSInteger)starLevel;

-(BOOL)openMountedElement;

-(NSMutableArray *)bookmarks;
-(BOOL)removeBookmarkForLocation                      : (NSString *)markLocation;
-(DACALSlotElementBookmark *)bookmarkForLocation      : (NSString *)markLocation;
-(DACALSlotElementBookmark *)createBookmarkAtLocation : (NSString *)markLocation attachNow : (BOOL)doAttach;

-(BOOL)changeElementIconRep : (NSImage *)newIcon;

@end        //	DACALSlotElement

@interface DACALSlotElementBookmark : NSObject
{
	DACALSlotElement * markElement;
	NSString         * markLocation;
	SimpleTreeNode   * markNode;
}

-(DACALSlotElement *)markElement;
-(NSString *)markLocation;
-(SimpleTreeNode *)markNode;

-(BOOL)isBookmarkLocation : (NSString *)theLocation;
-(BOOL)removeBookmark;
-(void)removeMarkNode;

-(id)initBookmarkForElement : (DACALSlotElement *)theElement atLocation : (NSString *)theLocation attachNow : (BOOL)doAttach;
+(id)bookmarkForElement     : (DACALSlotElement *)theElement atLocation : (NSString *)theLocation attachNow : (BOOL)doAttach;

@end    //	DACALSlotElementBookmark

@class DACALDevice;
@class DACALDeviceNode;
@class DACALVolume;

@interface DACALSlot : NSObject {
	DACALDeviceNode * slotDevice;
	DACALSlotNum      slotNumber;

	SimpleTreeNode * slotNode;
	DACALVolume      * slotVolume;
	FSRef            slotFSRef;

	NSString * slotIdentifier;

	BOOL     slotIsCheckedOut;
	NSDate * slotCheckedOut;
	NSDate * slotCheckedIn;

	NSMutableArray * slotElements;
}

-(DACALDeviceNode *)slotDevice;
-(DACALDeviceRef)slotDeviceRef;
-(DACALSlotNum)slotNumber;
-(SimpleTreeNode *)slotNode;
-(void)setSlotNode : (SimpleTreeNode *)newNode;
-(DACALVolume *)slotVolume;
-(FSRef *)slotFSRef;
-(BOOL)validSlotFSRef;
-(BOOL)setSlotFSRefFromURL : (NSURL *)slotURL;
-(BOOL)setSlotLocation     : (NSURL *)slotURL;

//- (NSUndoManager*)undoManager;

-(NSMutableArray *)slotElements;
-(void)setSlotElements   : (NSMutableArray *)newElements;
-(void)addSlotElement    : (DACALSlotElement *)newElement;
-(void)removeSlotElement : (DACALSlotElement *)oldElement;

-(DACALSlotElement *)elementWithFSRef : (const FSRef *)otherFSRef;
-(DACALSlotElement *)elementWithURL   : (NSURL *)otherURL;

-(NSString *)slotIdentifier;
-(void)setSlotIdentifier         : (NSString *)newID;
-(DACALSlot *)slotWithIdentifier : (NSString *)slotID;

-(id)initSlotForDevice   : (DACALDevice *)newDevice inSlot : (DACALSlotNum)newSlot;
+(id)createSlotForDevice : (DACALDevice *)newDevice inSlot : (DACALSlotNum)newSlot;

-(void)reloadSlot;
-(void)reloadElement : (DACALSlotElement *)theElement;

-(void)swapWithSlot : (DACALSlot *)otherSlot;

-(NSString *)title;
-(NSString *)displayTitle;
-(NSURL *)fileURL;

-(NSString *)flavor;
-(void)setFlavor : (NSString *)newFlavor;

-(DACALResult)moveDeviceToSlotWithOptions : (DACALOptionBits)slotOptions;

+(BOOL)moveDevicesToSlotsOfNodes : (NSArray *)theTreeNodes;
+(BOOL)ejectSlotVolumesOfNodes   : (NSArray *)theTreeNodes;

-(BOOL)isCheckedOut;
-(void)setIsCheckedOut : (BOOL)isOut;

-(NSDate *)checkedOutDate;
-(void)setCheckedOutDate : (NSDate *)newDate;

-(NSDate *)checkedInDate;
-(void)setCheckedInDate : (NSDate *)newDate;

-(NSDictionary *)currentReservation;
-(NSDictionary *)reservationHistory;

-(BOOL)checkOutForUser          : (NSString *)userName onHost : (NSString *)userHost withUI : (BOOL)doUI;
-(BOOL)checkInForUser           : (NSString *)userName onHost : (NSString *)userHost withUI : (BOOL)doUI;
-(BOOL)toggleReservationForUser : (NSString *)userName onHost : (NSString *)userHost withUI : (BOOL)doUI;

-(BOOL)isSlotMounted;
-(NSString *)slotHost;
-(BOOL)slotMountedAsVolume : (DACALVolume *)mountVolume;
-(BOOL)slotUnmounted;

-(BOOL)isSlotAssigned;
-(BOOL)slotAssignedIndexFromVolume : (DACALVolume *)indexVolume asType : (NSString *)newType;
-(BOOL)unassignSlotIndex;

-(NSNumber *)volumeSize;

@end        //	DACALSlot