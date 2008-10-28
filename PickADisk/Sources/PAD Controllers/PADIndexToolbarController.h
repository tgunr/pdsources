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
	
	IBOutlet	NSToolbar*				indexToolbar;
	
	IBOutlet	NSButton*				resetButton;
	IBOutlet	NSButton*				playButton;
	IBOutlet	NSButton*				checkOutButton;
	IBOutlet	NSButton*				checkInButton;
	IBOutlet	NSButton*				closeDoorButton;
	IBOutlet	NSButton*				assignButton;
	IBOutlet	NSButton*				unassignButton;
	IBOutlet	NSButton*				ejectButton;
	IBOutlet	NSButton*				gotoButton;
	IBOutlet	NSToolbarItem*			printButton;
	
	IBOutlet	NSImageView*			noBoxIcon;
	
	IBOutlet	NSSearchField*			searchField;
	IBOutlet	NSSearchField*			homeSearchField;
	
	IBOutlet	NSProgressIndicator*	busyProgress;
	
	IBOutlet	NSPathControl*			pathControl;
	
	IBOutlet	id						indexController;
	IBOutlet	id						dataController;
	IBOutlet	id						addVolumeController;
	
				NSMutableArray*			selectedDevices;
//				NSMutableArray*			selectedSlots;
				NSMutableArray*			selectedNodes;
	
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
- (IBAction)clickGotoSlot:(id)sender;
- (IBAction)clickEject:(id)sender;
- (IBAction)clickOpen:(id)sender;
- (IBAction)searchAction:(id)sender;
- (IBAction)homeSearchAction:(id)sender;
- (IBAction)provideFeedback:(id)sender;

- (void)unassignNodes:(NSArray*)nodesToDelete;

- (BOOL)allowCheck:(BOOL)inOrOut;
- (BOOL)nodesContainMountedSlotVolumes:(NSArray*)nodeArray;

- (NSString*)checkedOutTitle;
- (void)reportNoDevice:(BOOL)hasBox;
- (BOOL)validateMenuItem:(NSMenuItem *)item;

- (NSProgressIndicator*)busyProgress;

- (NSMutableArray*)selectedDevices;
- (void)setSelectedDevices: (NSMutableArray*)deviceList;
- (void)setSelectedDevice: (DACALDeviceRef)theDevice adoptSelection:(BOOL)doAdopt;
- (void)addSelectedDevice:(DACALDeviceRef)theDevice adoptSelection:(BOOL)doAdopt;

//- (void)setSelectedSlots: (NSMutableArray*)slotList;
//- (void)setSelectedSlot: (DACALSlotNum)theSlot;
//- (NSMutableArray*)selectedSlots;

- (NSMutableArray*)selectedNodes;
- (void)setSelectedNodes: (NSMutableArray*)nodeList;
- (void)setSelectedNode: (SimpleTreeNode*)theNode adoptSelection:(BOOL)doAdopt;
- (void)addSelectedNode:(SimpleTreeNode*)theNode adoptSelection:(BOOL)doAdopt;
- (void)resetSelectedNodesAndAdoptSelection:(BOOL)doAdopt;

- (void)resetSelection;

@end
