//
//  TreeController.h
//  DragNDropOutlineView
//
//  Created by Jack Small on 7/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AppController.h"
#import "SimpleTreeNode.h"

#import "ImageAndTextCell.h"
#import "NSArray_Extensions.h"
#import "NSOutlineView_Extensions.h"

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

- (id)toolbarControl;
- (void)setToolbarControl:(id)tbar;

- (SimpleTreeNode*)createInitialTree:(id)tree;
- (void)outlineViewAction:(id)tree;
- (void)menuNeedsUpdate:(NSMenu*)menu;
- (void)menuNeedsUpdate:(NSMenu*)menu fromTree:(id)tree;
- (void)nodeNameChanged:(SimpleTreeNode*)theNode toName:(NSString*)theName;
- (NSInteger)shouldEditTableColumn:(NSTableColumn *)tc item:(id)item;

@end

