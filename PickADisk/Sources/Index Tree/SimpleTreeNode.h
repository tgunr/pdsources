// SimpleTreeNode.h

#import <Cocoa/Cocoa.h>
#import <DACAL/dacallib.h>

#import "TreeNode.h"

#define KEY_GROUPNAME	@"Group"
#define KEY_ENTRIES		@"Entries"

const enum {
	kPADTypeUnknown				= 0,
	kPADTypeGroupLibrary,
	kPADTypeGroupDevices,
	kPADTypeGroupFavorites,
	kPADTypeGroupSearches,
	kPADTypeIndexCollection,
	kPADTypeIndexDevice,
	kPADTypeIndexSavedSearch,
	kPADTypeIndexFavorites,
	kPADTypeDataSlot,
	kPADTypeDataFiles,
	kPADTypeDataMovie,
	kPADTypeDataMuisc,
	kPADTypeDataImage
} PADNodeTypes;

@class SimpleNodeData;

@interface SimpleTreeNode : TreeNode {

}

// This is a convenience method to return a tree root of a tree derived from an input dictionary. (see InitInfo.dict)
+ (id)treeFromDictionary:(NSDictionary *)dict;

// This is a convenience method to return a tree root of a tree derived from an input dictionary. (see InitInfo.dict)
+ (id)treeFromLocation:(NSURL *)loc;

+ (id)treeOperationFromLocation:(NSURL *)loc forUI:(BOOL)uiQueue;
+ (id)treeOperationFromLocation:(NSURL *)loc;
- (id)initWithData:(id)data;
- (id)initFromLocation:(NSURL*)loc;
- (id)initOperationFromLocation:(NSURL*)loc;

// Convenience method to return a leaf node with its location set.
+ (id)nodeDataWithURL:(NSURL*)loc;

// This method is called to transfer device and slot data down the tree from a data object.
// No longer used.
- (void)setDataDeviceAndSlotFromData:(id)data;

// This method is called to transfer device and slot data down the tree from a device ref and slot number.
- (void)setDataDevice:(DACALDeviceRef)inDevice slot:(DACALSlotNum)inSlot;

- (BOOL)busy;
- (void)setBusy:(BOOL)value;

- (SimpleTreeNode*)childWithName:(NSString*)theName;
- (SimpleTreeNode*)childWithDevice:(DACALDeviceRef)theBoxRef;
- (SimpleTreeNode*)childWithSlotNum:(DACALSlotNum)theSlotNum;
- (SimpleTreeNode*)childWithItemType:(NSInteger)theItemType;

- (NSString*)localPathName;
- (NSString*)localPathString;
- (NSString*)absolutePathName;
- (NSString*)absolutePathString;
- (NSString*)urlString;
- (NSString *)tooltip;
//-(NSString*)name;
//-(NSNumber*)slotNSNumber;
- (NSNumber*)numberForSlotNumber;

-(SimpleNodeData*)keyName;
-(SimpleNodeData*)keySlotNumber;
-(SimpleNodeData*)keyAddDate;
-(SimpleNodeData*)keyFlavor;
-(SimpleNodeData*)keyCheckedOut;
-(SimpleNodeData*)keyComments;
-(SimpleNodeData*)keyTags;
-(SimpleNodeData*)keyStars; 
-(void)setKeyStars:(NSInteger)starLevel;

-(SimpleTreeNode*)matchActual;

@end	// <<Simple Tree Node>>

@interface SimpleNodeData : NSObject {
@private
    NSString		*name;
    NSImage			*iconRep;
	NSURL			*location;
	NSString		*itemFlavor;
	NSDate			*itemAddDate;
	NSInteger		itemType;
	DACALDeviceRef	itemDevice;
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

// Convenience method to return a leaf node with its location set.
+ (id)nodeDataWithURL:(NSURL*)loc;

// Convenience method to return a leaf node with its location set and specific type.
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

// Set and get the location url 
- (void)setLocation:(NSURL *)loc;
- (NSURL *)location;

// A convience function to set the url data and grab the icon
- (void)setLocationForIcon:(NSURL *)loc;

- (void)setItemType:(NSInteger)type;
- (NSInteger)itemType;

- (void)setItemDevice:(DACALDeviceRef)device;
- (DACALDeviceRef)itemDevice;

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

