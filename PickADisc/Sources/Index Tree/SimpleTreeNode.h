#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "TreeNode.h"

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
	kPADTypeDataMuisc
} PADNodeTypes;

@interface SimpleTreeNode : TreeNode {

}

// This is a convenience method to return a tree root of a tree derived from an input dictionary. (see InitInfo.dict)
+ (id)treeFromDictionary:(NSDictionary *)dict;

// This is a convenience method to return a tree root of a tree derived from an input dictionary. (see InitInfo.dict)
+ (id)treeFromLocation:(NSURL *)loc;

+ (id)treeOperationFromLocation:(NSURL *)loc;
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

@end	// <<Simple Tree Node>>

@interface SimpleNodeData : NSObject {
@private
    NSString		*name;
    NSImage			*iconRep;
	NSURL			*location;
	NSInteger		itemType;
	DACALDeviceRef	itemDevice;
	DACALSlotNum	itemSlot;
    BOOL			isLeaf;
    BOOL			isExpandable;
    BOOL			isSelectable;
	BOOL			isBusy;
	SimpleTreeNode *subTree;
}

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

- (void)setSubTree:(SimpleTreeNode*)tree;
- (SimpleTreeNode*)subTree;

- (BOOL)busy;
- (void)setBusy:(BOOL)value;

@end

