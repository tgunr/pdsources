//
//  PADAddVolumeController.m
//  PickADisc
//
//  Created by Jack Small on 7/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PADAddVolumeController.h"


@implementation PADAddVolumeController

- (void)awakeFromNib
{
	NSInteger	index;
	NSInteger	count = DACALDevicesGetCount();

	[carouselList removeAllItems];
	for( index=1; index <= count; index++ )
		[carouselList addItemWithTitle:(NSString*)DACALCommandCopyName( index, NULL )];
		
	[carouselList setIntValue:1];
	
	[self carouselChanged: self];

	//if( cdIcon ) [cdIcon setAlphaValue: 0.22];
	
}

-(IBAction) clickCancel:(id)sender 
{
	[NSApp endSheet:sheetWindow];
}

-(IBAction) clickOK:(id)sender
{
	//[NSApp endSheet:sheetWindow];
}

-(IBAction) clickType:(id)sender
{
	NSInteger	theTypeName = [slotTypeList indexOfSelectedItem];
	
	if( theTypeName == 1 )		[cdIcon setImage: DACALGetIconImageForType('cdda')];
	else if( theTypeName == 2 ) [cdIcon setImage: DACALGetIconImageForType('dvd ')];
	else						[cdIcon setImage: DACALGetIconImageForType('Dcd ')];
}

-(IBAction) clickChoose:(id)sender { }
-(IBAction) slotChanged:(id)sender 
{
	CFStringRef		existingSlotName = DACALSlotCopyTitle( [carouselList indexOfSelectedItem]+1, [slotNumber intValue], NULL );

	 if( existingSlotName ) [slotTitle setStringValue:(NSString*)existingSlotName];
	 else [slotTitle setStringValue:(NSString*)@""];
	 
	 [okButton setEnabled: (!existingSlotName) ? YES : NO];
	 [slotTitle setEnabled: (!existingSlotName) ? YES : NO];
}

-(IBAction) slotTitleChanged:(id)sender 
{
	[slotDial setIntValue:[slotNumber intValue]];
	[self slotChanged:sender];
}

-(IBAction) slotDialChanged:(id)sender 
{
	[slotNumber setIntValue:[slotDial intValue]];
	[self slotChanged:sender];
}

-(IBAction) carouselChanged:(id)sender
{
	DACALSlotNum	nextSlot = DACALSlotNextFreeNumber( [carouselList indexOfSelectedItem]+1, 0, 0, NULL );
	
	if( nextSlot ) {
		[slotNumber setIntValue: nextSlot];
		[self slotChanged: sender];
	}
}

- (void)windowWillBeginSheet:(NSNotification *)notification
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	
	[self carouselChanged:self];
	[super windowWillBeginSheet:notification];
}

@end
