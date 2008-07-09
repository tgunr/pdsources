//
//  PADIndexToolbarController.m
//  PickADisc
//
//  Created by Jack Small on 7/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PADIndexToolbarController.h"


@implementation PADIndexToolbarController

-(void)adoptSelection
{
	NSInteger	boxCount = 0;
	NSInteger	slotCount = 0;
	BOOL		anyBox = NO;
	BOOL		anySlot = NO;
	
	if( [self selectedDevices] ) boxCount = [[self selectedDevices] count];
	if( boxCount > 0 ) anyBox = YES;
	
	if( [self selectedSlots] ) slotCount = [[self selectedSlots] count];
	if( slotCount > 0 ) anySlot = YES;
	
	if( resetButton )		[resetButton setEnabled:anyBox];
	if( closeDoorButton )	[closeDoorButton setEnabled:anyBox];
	if( assignButton )		[assignButton setEnabled:anyBox];
	if( playButton )		[playButton setEnabled:anySlot];
	if( checkOutButton )	[checkOutButton setEnabled:anySlot];
	if( unassignButton )	[unassignButton setEnabled:anySlot];
}

- (IBAction)clickReset:(id)sender
{
	NSInteger	boxCount = 0;
	NSInteger	index;
	DACALDeviceRef	aBox;

	if( [self selectedDevices] ) boxCount = [[self selectedDevices] count];

	for( index=0; index < boxCount; index++ )
	{
		aBox = (DACALDeviceRef)[[self selectedDevices] objectAtIndex:index];
		DACALCommandReset( aBox );
	}
}

- (IBAction)clickPlay:(id)sender { return [self clickCheckOut:sender]; }

- (IBAction)clickCheckOut:(id)sender
{
	NSInteger	slotCount = 0;
	NSInteger	index;
	DACALDeviceRef	aBox;
	DACALSlotNum	aSlot;

	if( [self selectedDevices] ) slotCount = [[self selectedDevices] count];
	aBox = (DACALDeviceRef)[[self selectedDevices] objectAtIndex:0];

	for( index=0; index < slotCount; index++ )
	{
		aSlot = (DACALSlotNum)[[[self selectedSlots] objectAtIndex:index] longValue];
		DACALCommandMoveToSlotWithOptions( aBox, aSlot, kDACALOptionMoveOnce);
	}
}

- (IBAction)clickCloseDoor:(id)sender 
{
	NSInteger	boxCount = 0;
	NSInteger	index;
	DACALDeviceRef	aBox;

	if( [self selectedDevices] ) boxCount = [[self selectedDevices] count];

	for( index=0; index < boxCount; index++ )
	{
		aBox = (DACALDeviceRef)[[self selectedDevices] objectAtIndex:index];
		DACALCommandCloseDoor( aBox );
	}
}

- (void)assignSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:self];
}

- (IBAction)clickAssign:(id)sender
{
	if( addVolumeSheet )
		[NSApp	beginSheet: addVolumeSheet
				modalForWindow: [assignButton window]
				modalDelegate: self
				didEndSelector: @selector(assignSheetDidEnd:returnCode:contextInfo:)
				contextInfo: nil];
}


- (void)unassignAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSArray*	slotArray = [self selectedSlots];
	NSInteger	index;
	DACALDeviceRef	aBox;
	DACALSlotNum	aSlot;

	aBox = (DACALDeviceRef)[[self selectedDevices] objectAtIndex:0];

    if (returnCode == NO) {
		for( index=0; index < [slotArray count]; index++ ) {
			aSlot = (DACALSlotNum)[[slotArray objectAtIndex:index] longValue];
			DACALSlotDeleteIndex( aBox, aSlot );
		}

		if( dataController ) [(TreeController*)dataController deleteSelections:self];
    }
}

- (IBAction)clickUnassign:(id)sender
{
	NSInteger	slotCount = 0;
	NSInteger	slotIndex = 0;
	NSMutableString	*promptSlots;
	NSString	*prompt;
	NSAlert		*alert;

	if( [self selectedSlots] ) slotCount = [[self selectedSlots] count];
	if( !slotCount ) return;

	// You are sure you want to delete selectedSlots?

	promptSlots = [NSMutableString stringWithFormat:@"%@", (slotCount==1) ? @"" : @"s" ];
	for( slotIndex=0; slotIndex<slotCount; slotIndex++ ) {
		[promptSlots appendFormat:@" %@", [[self selectedSlots] objectAtIndex:slotIndex]];
		if( slotIndex == slotCount-2 ) [promptSlots appendString:@" and"];
		else if( slotIndex != slotCount-1 ) [promptSlots appendString:@","];
	}

	prompt = [NSString stringWithFormat:@"Are you sure you want to unassign and delete slot%@?", promptSlots];

	alert = [NSAlert alertWithMessageText:prompt
		defaultButton:@"Cancel" alternateButton:@"Unassign" otherButton:nil
		informativeTextWithFormat:@"Deleted slots cannot be restored."];

	[alert beginSheetModalForWindow:[unassignButton window] modalDelegate:self didEndSelector:@selector(unassignAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)setSelectedDevices: (NSArray*)deviceList
{
    if (!selectedDevices || ![selectedDevices isEqual:deviceList]) {
	[selectedDevices release];
	selectedDevices = [deviceList retain];
    }
	[self adoptSelection];
}

- (void)setSelectedDevice: (DACALDeviceRef)theDevice;
{
	NSArray*	newList = [[NSArray arrayWithObject:(id)theDevice] autorelease];	
	[self setSelectedDevices:newList];
}
- (NSArray*)selectedDevices { return selectedDevices; }

- (void)setSelectedSlots: (NSArray*)slotList
{
    if (!selectedSlots || ![selectedSlots isEqual:slotList]) {
	[selectedSlots release];
	selectedSlots = [slotList retain];
    }
	[self adoptSelection];
}

- (void)setSelectedSlot: (DACALSlotNum)theSlot
{
	NSArray*	newList = [[NSArray arrayWithObject:[NSNumber numberWithLong:(NSInteger)theSlot]] autorelease];	
	[self setSelectedSlots:newList];
}

- (NSArray*)selectedSlots; { return selectedSlots; }

@end
