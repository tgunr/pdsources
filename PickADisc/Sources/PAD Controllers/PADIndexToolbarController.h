//
//  PADIndexToolbarController.h
//  PickADisc
//
//  Created by Jack Small on 7/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TreeController.h"

@interface PADIndexToolbarController : NSObject {
	
	IBOutlet	NSToolbar	*indexToolbar;
	
	IBOutlet	NSButton	*resetButton;
	IBOutlet	NSButton	*playButton;
	IBOutlet	NSButton	*checkOutButton;
	IBOutlet	NSButton	*closeDoorButton;
	IBOutlet	NSButton	*assignButton;
	IBOutlet	NSButton	*unassignButton;
	
	IBOutlet	id			indexController;
	IBOutlet	id			dataController;
	
	IBOutlet	NSWindow	*addVolumeSheet;
	
	NSArray					*selectedDevices;
	NSArray					*selectedSlots;

}

- (IBAction)clickReset:(id)sender;
- (IBAction)clickPlay:(id)sender;
- (IBAction)clickCheckOut:(id)sender;
- (IBAction)clickCloseDoor:(id)sender;
- (IBAction)clickAssign:(id)sender;
- (IBAction)clickUnassign:(id)sender;

- (void)setSelectedDevices: (NSArray*)deviceList;
- (void)setSelectedDevice: (DACALDeviceRef)theDevice;
- (NSArray*)selectedDevices;

- (void)setSelectedSlots: (NSArray*)slotList;
- (void)setSelectedSlot: (DACALSlotNum)theSlot;
- (NSArray*)selectedSlots;

@end
