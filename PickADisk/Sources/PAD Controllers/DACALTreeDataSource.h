//
//  DACALTreeDataSource.h
//  DragNDropOutlineView
//
//  Created by Jack Small on 7/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TreeController.h"
#import "SimpleTreeNode.h"
#import "PADIndexToolbarController.h"

// Index group names

#define		PADINDEX_GROUPTITLE_LIBRARY		@"LIBRARY"
#define		PADINDEX_GROUPTITLE_DEVICES		@"CAROUSELS"
#define		PADINDEX_GROUPTITLE_FAVORITES	@"BOOKMARKS"
#define		PADINDEX_GROUPTITLE_SEARHCES	@"SEARCH FOR"

#define		PADINDEX_FLAVORVALUE_FILES			@"Files"
#define		PADINDEX_FLAVORVALUE_MUSIC			@"Music"
#define		PADINDEX_FLAVORVALUE_MOVIE			@"Movie"

#define		PADINDEX_FLAVORTITLE_FILES			@"Files"
#define		PADINDEX_FLAVORTITLE_MUSIC			@"Music"
#define		PADINDEX_FLAVORTITLE_MOVIE			@"Movies"

@interface DACALTreeDataSource : TreeControllerDataSource {

	IBOutlet	NSTextField		*promptText;
	IBOutlet	NSImageView		*noBoxIcon;
	IBOutlet	NSTabView		*tabView;
	IBOutlet	id				secondaryController;
	
}

+ (id)shared;

- (SimpleTreeNode*)findTreeNodeForDevice:(DACALDeviceRef)theBoxRef;
- (void)slotAddedToDevice:(DACALDeviceRef)theBoxRef forSlot:(DACALSlotNum)newSlot;
- (void)toolbarSearchStart:(id)sender;
- (void)reportNoDevice:(BOOL)hasBox;
- (void)setPrompt:(NSString*)newPrompt;
- (void)updatePrompt;
- (void)doReport;
- (void)doAction;

@end

@interface DACALViewDataSource : TreeControllerDataSource {

	IBOutlet	NSTextField		*promptText;
}

- (void)updatePrompt;
- (void)doubleClickCellContent:(id)item;

@end
