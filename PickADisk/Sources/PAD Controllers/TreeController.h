//
//  TreeController.h
//  DragNDropOutlineView
//
//  Created by Jack Small on 7/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//#import "AppController.h"
#import "SimpleTreeNode.h"

#import "ImageAndTextCell.h"
#import "NSArray_Extensions.h"
#import "NSOutlineView_Extensions.h"

// ================================================================
// Useful Macros
// ================================================================

#define DragDropSimplePboardType 	@"MyCustomOutlineViewPboardType"
#define COLUMNID_NAME				@"NameColumn"
#define COLUMNID_SLOT				@"SlotColumn"
#define COLUMNID_MODDATE			@"DateAddColumn"
#define COLUMNID_TYPE				@"TypeColumn"
#define COLUMNID_SCORE				@"ScoreColumn"
//#define COLUMNID_NODE_KIND		@"NodeKindColumn"

@class SimpleTreeNode;
@class PADIndexToolbarController;

@interface TreeController : NSObject {

    SimpleTreeNode				*treeData;
    NSArray						*draggedNodes;
	
	BOOL						allowOnDropOnGroup;
	BOOL						allowOnDropOnLeaf;
	BOOL						allowBetweenDrop;
	BOOL						allowGroupRowLook;
	BOOL						allowButtonCellsToChangeSelection;
	BOOL						allowToggleVerticalBeginsDrag;
	BOOL						onlyAcceptDropOnRoot;
	
	IBOutlet id					dataSource;
    IBOutlet NSOutlineView		*outlineView;	
}

- (IBAction)addGroup:(id)sender;
- (IBAction)addLeaf:(id)sender;
- (IBAction)deleteSelections:(id)sender;
- (IBAction)outlineViewAction:(id)sender;
- (IBAction)sortData:(id)sender;
- (IBAction)expandableMenuItemAction:(id)sender;

- (SimpleTreeNode*)treeRoot ;
- (void)setTreeRoot:(SimpleTreeNode*)root;
- (void)addTreeRoot:(SimpleTreeNode*)newChild;
- (void)addDataToTree:(SimpleTreeNode*)newChild startEdit:(BOOL)doEdit;

- (id)dataSource;

- (NSOutlineView*)outlineView;
- (void)setOutlineView:(NSOutlineView*)view;

- (NSArray*)draggedNodes;
- (NSArray*)selectedNodes;

- (BOOL)allowOnDropOnGroup;
- (BOOL)allowOnDropOnLeaf;
- (BOOL)allowBetweenDrop;
- (BOOL)allowGroupRowLook;
- (BOOL)allowButtonCellsToChangeSelection;
- (BOOL)allowToggleVerticalBeginsDrag;
- (BOOL)onlyAcceptDropOnRoot;

- (void)setAllowOnDropOnGroup:(BOOL)allow;
- (void)setAllowOnDropOnLeaf:(BOOL)allow;
- (void)setAllowBetweenDrop:(BOOL)allow;
- (void)setAllowGroupRowLook:(BOOL)allow;
- (void)setAllowButtonCellsToChangeSelection:(BOOL)allow;
- (void)setAllowToggleVerticalBeginsDrag:(BOOL)allow;
- (void)setOnlyAcceptDropOnRoot:(BOOL)allow;

@end

@interface TreeControllerDataSource : NSObject {

	IBOutlet id			treeControl;
    // Contextual menus (aka: right click menus) for the NSOutlineView
    IBOutlet NSMenu     *outlineViewContextMenu;
    IBOutlet NSMenu     *expandableColumnMenu;
	IBOutlet PADIndexToolbarController*	toolbarControl;

}
- (id)treeControl;
- (void)setTreeControl:(id)tree;

- (NSOutlineView*)outlineView;

- (void)removeAllChildren;

- (id)toolbarControl;
- (void)setToolbarControl:(id)tbar;

- (SimpleTreeNode*)createInitialTree:(id)tree;
- (void)outlineViewInit;
- (void)outlineViewAction:(id)tree;
- (void)outlineViewDoubleAction:(id)tree;
- (void)menuNeedsUpdate:(NSMenu*)menu;
- (void)menuNeedsUpdate:(NSMenu*)menu fromTree:(id)tree;
- (void)nodeNameChanged:(SimpleTreeNode*)theNode toName:(NSString*)theName;
- (NSInteger)shouldEditTableColumn:(NSTableColumn *)tc item:(id)item;
- (void)sortExpandedChildrenWithCurrentDescriptors:(SimpleTreeNode*)theNode;

- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard;
- (NSDragOperation)validateDropSource:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex;
- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex;
- (BOOL)performDropOperation:(id <NSDraggingInfo>)info onNode:(TreeNode *)parentNode atIndex:(NSInteger)childIndex;

- (BOOL)shouldShowCellExpansionForTableColumn:(NSTableColumn *)tc item:(id)inItem;
- (NSString*)toolTipForCell:(NSCell *)cell rect:(NSRectPointer)inRect tableColumn:(NSTableColumn *)tc item:(id)inItem mouseLocation:(NSPoint)inMouseLocation;

@end

