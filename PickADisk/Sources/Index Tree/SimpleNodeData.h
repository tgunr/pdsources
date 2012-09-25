//
//  SimpleNodeData.h
//  PickADisk
//
//  Created by Dave Carlton on 9/8/12.
//  Copyright (c) 2012 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DACAL/dacallib.h>

@class DACALDevice;
@class SimpleTreeNode;

@interface SimpleNodeData : NSObject {
@private
    NSString		*name;
    NSImage			*iconRep;
	NSURL			*itemURL;
	NSString		*itemFlavor;
	NSDate			*itemAddDate;
	NSInteger		itemType;
	DACALDevice     *itemDevice;
	DACALSlotNum	itemSlot;
    BOOL			isLeaf;
    BOOL			isExpandable;
	BOOL			isExpanded;
    BOOL			isSelectable;
	BOOL			isBusy;
	SimpleTreeNode *subTree;
	id				itemElement;
}

- (id)initWithName:(NSString *)str isLeaf:(BOOL)leaf;

- (id)initWithLocation:(NSURL *)loc;
- (id)initWithLocation:(NSURL *)loc isLeaf:(BOOL)leaf;

// Convenience method to return a leaf node with its name set.
+ (id)leafDataWithName:(NSString *)name;

// Convenience method to return a branch node with its name set.
+ (id)groupDataWithName:(NSString *)name;

// Convenience method to return a leaf node with its itemURL set.
+ (id)nodeDataWithURL:(NSURL*)loc;

// Convenience method to return a leaf node with its itemURL set and specific type.
+ (id)nodeDataWithURL:(NSURL*)loc isLeaf:(BOOL)leaf;


// Set and get the name.
- (void)setName:(NSString *)name;
- (NSString *)name;

// Set and determine the type of this item (leaf or group).
- (void)setIsLeaf:(BOOL)isLeaf;
- (BOOL)isLeaf;
- (BOOL)isGroup;

// Set and get the icon displayed next to the
- (void)setIconRep:(NSImage *)iconRep;
- (NSImage *)iconRep;

- (void)setExpandable:(BOOL)value;
- (BOOL)isExpandable;

- (void)setExpanded:(BOOL)value;
- (BOOL)isExpanded;

- (BOOL)isSelectable;
- (void)setSelectable:(BOOL)value;

// Set and get the itemURL url
- (void)setLocation:(NSURL *)loc;
- (NSURL *)itemURL;

// A convience function to set the url data and grab the icon
- (void)setLocationForIcon:(NSURL *)loc;

- (void)setItemType:(NSInteger)type;
- (NSInteger)itemType;

- (void)setItemDevice:(DACALDevice *)device;
- (DACALDevice *)itemDevice;

- (void)setItemSlot:(DACALSlotNum)slot;
- (DACALSlotNum)itemSlot;
- (NSNumber*)numberForSlotNumber;

// Set and get the flavor.
- (void)setItemFlavor:(NSString *)name;
- (NSString *)itemFlavor;

// Set and get the add date.
- (void)setItemAddDate:(NSDate *)newDay;
- (NSDate *)itemAddDate;

- (void)setSubTree:(SimpleTreeNode*)tree;
- (SimpleTreeNode*)subTree;

- (void)setItemElement:(id)element;
- (id)itemElement;

- (BOOL)busy;
- (void)setBusy:(BOOL)value;

-(BOOL)isCheckedOut;
-(NSDate*)checkedOutDate;
-(NSDate*)checkedInDate;

-(NSString*)keyComments;
-(void)setKeyComments:(NSString*)newComment;

-(NSArray*)keyTags;
-(void)setKeyTags:(NSArray*)newTags;

-(NSInteger)keyStars;
-(void)setKeyStars:(NSInteger)starLevel;

- (id)reload;
- (id)reloadData:(id)newData;

- (NSComparisonResult)compareDataNames:(SimpleNodeData *)otherData;
- (NSComparisonResult)compareDataSlots:(SimpleNodeData *)otherData;
- (NSComparisonResult)compareDataAddDates:(SimpleNodeData *)other;
- (NSComparisonResult)compareDataFlavors:(SimpleNodeData *)other;
- (NSComparisonResult)compareDataScores:(SimpleNodeData *)other;
- (NSComparisonResult)compareKeyCheckedOut:(SimpleNodeData *)other;
- (NSComparisonResult)compareKeyComments:(SimpleNodeData *)other;
- (NSComparisonResult)compareKeyTags:(SimpleNodeData *)other;
- (NSComparisonResult)compareKeyStars:(SimpleNodeData *)other;

- (NSComparisonResult)compare:(id)otherData;
- (SimpleTreeNode*)matchActual;

@end

