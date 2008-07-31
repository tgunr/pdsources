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

@interface DACALTreeDataSource : TreeControllerDataSource {

	IBOutlet	NSTextField		*promptText;
	IBOutlet	id				secondaryController;
	
}

+ (id)shared;

- (SimpleTreeNode*)findTreeNodeForDevice:(DACALDeviceRef)theBoxRef;
- (void)slotAddedToDevice:(DACALDeviceRef)theBoxRef forSlot:(DACALSlotNum)newSlot;

@end

@interface DACALViewDataSource : TreeControllerDataSource {

	IBOutlet	NSTextField		*promptText;
}

- (void)updatePrompt;

@end
