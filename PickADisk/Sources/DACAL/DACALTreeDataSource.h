//
//  DACALTreeDataSource.h
//  DragNDropOutlineView
//
//  Created by Jack Small on 7/5/08.
//  Copyright 2008 polyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TreeController.h"
//#import "PADIndexNodeData.h"
//#import "DACALViewDataSource.h"

// Index group names

#define		PADINDEX_GROUPTITLE_LIBRARY			@"LIBRARY"
#define		PADINDEX_GROUPTITLE_DEVICES			@"CAROUSELS"
#define		PADINDEX_GROUPTITLE_FAVORITES		@"BOOKMARKS"
#define		PADINDEX_GROUPTITLE_SEARHCES		@"SEARCH FOR"

#define		PADINDEX_FLAVORVALUE_FILES			@"Files"
#define		PADINDEX_FLAVORVALUE_IMAGE			@"Image"
#define		PADINDEX_FLAVORVALUE_MUSIC			@"Music"
#define		PADINDEX_FLAVORVALUE_MOVIE			@"Movie"

#define		PADINDEX_FLAVORTITLE_FILES			@"Files"
#define		PADINDEX_FLAVORTITLE_IMAGE			@"Images"
#define		PADINDEX_FLAVORTITLE_MUSIC			@"Music"
#define		PADINDEX_FLAVORTITLE_MOVIE			@"Movies"

NSString*	DACALFlavorToFlavorValue( NSString* flavor );
NSString*	DACALFlavorToFlavorTitle( NSString* flavor );

@class DACALIndexState;
@interface DACALTreeDataSource : TreeControllerDataSource {

	IBOutlet	NSTextField		*promptText;
	IBOutlet	NSImageView		*noBoxIcon;
	IBOutlet	NSTabView		*tabView;
	IBOutlet	id				secondaryController;
	
	DACALIndexState*			savedSelection;
	DACALIndexState*			sortedSelection;
}

-(IBAction)ctmRefreshSearch:(id)sender;
-(IBAction)ctmDeleteSelection:(id)sender;

+ (id)shared;

- (SimpleTreeNode*)findTreeNodeForDevice:(DACALDeviceRef)theBoxRef;
- (void)slotAddedToDevice:(DACALDeviceRef)theBoxRef forSlot:(DACALSlotNum)newSlot;
- (void)toolbarSearchStart:(id)sender;
- (void)toolbarSearchFinish:(id)sender;
- (void)reportNoDevice:(BOOL)hasBox;
- (void)reportGoodRegistration;
- (void)setPrompt:(NSString*)newPrompt;
- (void)updatePrompt;
- (void)doReport;
- (void)doAction;

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation;

-(void)orderForUser:(SimpleTreeNode*)treeNode;
-(void)saveUserOrder;

-(id)secondaryController;

@end





