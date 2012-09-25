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

+ (SimpleTreeNode *)treeOperationFromLocation:(NSURL *)loc forUI:(BOOL)uiQueue;
+ (id)treeOperationFromLocation:(NSURL *)loc;
- (id)initWithData:(id)data;
- (id)initFromLocation:(NSURL*)loc;
- (id)initOperationFromLocation:(NSURL*)loc;

// Convenience method to return a leaf node with its itemURL set.
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

