//
//  PADIndexToolbarController.h
//  PickADisc
//
//  Created by Jack Small on 7/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TreeController.h"
#import "DACALTreeDataSource.h"
#import "PADAddVolumeController.h"
#import "PADSearchRequest.h"

@interface PADIndexToolbarController : NSObject {
	
	IBOutlet	NSToolbar	*indexToolbar;
	
	IBOutlet	NSButton	*resetButton;
	IBOutlet	NSButton	*playButton;
	IBOutlet	NSButton	*checkOutButton;
	IBOutlet	NSButton	*checkInButton;
	IBOutlet	NSButton	*closeDoorButton;
	IBOutlet	NSButton	*assignButton;
	IBOutlet	NSButton	*unassignButton;
	IBOutlet	NSToolbarItem *printButton;
	
	IBOutlet	NSImageView	*noBoxIcon;
	
	IBOutlet	NSSearchField	*searchField;
	IBOutlet	NSSearchField	*homeSearchField;
	
	IBOutlet	NSProgressIndicator	*busyProgress;
	
	IBOutlet	NSPathControl	*pathControl;
	
	IBOutlet	id			indexController;
	IBOutlet	id			dataController;
	IBOutlet	id			addVolumeController;
	
	NSArray					*selectedDevices;
	NSArray					*selectedSlots;
	NSArray					*selectedNodes;
	
	BOOL					hasBoxes;

}

- (IBAction)clickReset:(id)sender;
- (IBAction)clickPlay:(id)sender;
- (IBAction)clickCheckOut:(id)sender;
- (IBAction)clickCheckIn:(id)sender;
- (IBAction)clickCloseDoor:(id)sender;
- (IBAction)clickAssign:(id)sender;
- (IBAction)clickUnassign:(id)sender;
- (IBAction)clickIdentify:(id)sender;
- (IBAction)clickPrintReport:(id)sender;
- (IBAction)searchAction:(id)sender;
- (IBAction)homeSearchAction:(id)sender;
- (IBAction)provideFeedback:(id)sender;

- (void)reportNoDevice:(BOOL)hasBox;
- (BOOL)validateMenuItem:(NSMenuItem *)item;

- (void)setSelectedDevices: (NSArray*)deviceList;
- (void)setSelectedDevice: (DACALDeviceRef)theDevice;
- (void)addSelectedDevice:(DACALDeviceRef)theDevice adoptSelection:(BOOL)doAdopt;
- (NSArray*)selectedDevices;

- (void)setSelectedSlots: (NSArray*)slotList;
- (void)setSelectedSlot: (DACALSlotNum)theSlot;
- (NSArray*)selectedSlots;

- (void)setSelectedNodes: (NSArray*)nodeList;
- (void)setSelectedNode: (SimpleTreeNode*)theNode;
- (void)addSelectedNode:(SimpleTreeNode*)theNode;
- (NSArray*)selectedNodes;
- (void)resetSelection;
- (NSProgressIndicator*)busyProgress;

- (void)unassignNodes:(NSArray*)nodesToDelete;

-(NSString*)checkedOutTitle;

@end
