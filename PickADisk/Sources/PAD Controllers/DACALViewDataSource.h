//
//  DACALViewDataSource.h
//  PickADisk
//
//  Created by Jack Small on 8/30/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TreeController.h"
#import "PADIndexNodeData.h"
#import "PADIndexToolbarController.h"

#import "DACALTreeDataSource.h"

@interface DACALViewDataSource : TreeControllerDataSource {
	
	IBOutlet	NSTextField		*promptText;
}

- (IBAction)ctmMountOpen:(id)sender;
- (IBAction)ctmCheckIn:(id)sender;
- (IBAction)ctmCheckOut:(id)sender;
- (IBAction)ctmDeleteSlot:(id)sender;

- (void)updatePrompt;
- (void)doubleClickCellContent:(id)item inCell:(NSCell*)cell;

- (void)nodeSlotChanged:(SimpleTreeNode*)node toSlot:(NSString*)slotString;
- (void)nodeTypeChanged:(SimpleTreeNode*)theNode toType:(NSString*)theName;

@end
