//
//  PADAddVolumeController.m
//  PickADisc
//
//  Created by Jack Small on 7/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PADAddVolumeController.h"


@implementation PADAddVolumeController

- (id)init {
    if (self = [super init]) {
		isPending = NO;
	}
	
    return self; 
}

- (void)dealloc {

    [pendingVolumes release];

    [super dealloc];
}

- (void)awakeFromNib
{
	[[NSApplication sharedApplication] setAddVolumeController:self];
	
	//if( cdIcon ) [cdIcon setAlphaValue: 0.22];
	
}

-(NSInteger) pendingCount
{
	NSInteger	theCount = 0;
	
	if( pendingVolumes == NULL ) theCount = 0;
	else if( pendingVolumes == nil ) theCount = 0;

	else theCount = [pendingVolumes count];
	
	return theCount;
}	

- (void)pushPending
{
	NSInteger	theCount = [self pendingCount];
	
	if( theCount > 0 ) {
		[self setPendingURL:[pendingVolumes objectAtIndex:0]];
		[self setPendingTitle: (NSString*)CFURLCopyDisplayName( NULL, (CFURLRef)[self pendingURL], NULL)];
		isPending = YES;
	} else {
		[self setPendingURL: nil];
		[self setPendingTitle: nil];
		isPending = NO;
	}
	[self carouselChanged:self];
}

- (void)popPending
{	
	NSInteger	theCount = [self pendingCount];
		
	if( theCount > 0 ) [pendingVolumes removeObjectAtIndex:0];
	if( theCount <= 1 ) {
		if( pendingVolumes != NULL ) [pendingVolumes release];
		pendingVolumes = NULL;
	}
	[self pushPending];
}


-(IBAction) clickCancel:(id)sender 
{
	[NSApp endSheet:sheetWindow];
}

-(IBAction) clickOK:(id)sender
{
	
	NSString*		newTitle = [slotTitle stringValue];
	DACALDeviceRef	deviceID = (DACALDeviceRef)[carouselList indexOfSelectedItem]+1;
	DACALSlotNum	nextSlot = (DACALSlotNum)[slotNumber intValue];
	NSURL*			newPath = [self pendingURL];
	DACALResult		theErr;
	
	theErr = DACALSlotCreateIndex( deviceID, nextSlot, (CFStringRef)newTitle, 0, (CFURLRef)newPath );
	if( theErr == 0 ) {
		[AppController playUISound: kASSystemSoundSuccess];
//		if( isPending && ([self pendingCount] > 1) ) {
//			[self popPending];
//			return;
//		}
		[NSApp endSheet:sheetWindow];
		return;
	}
	[AppController playUISound: kASSystemSoundDoink];
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
	CFStringRef		blankSlotName = (CFStringRef)[self pendingTitle];
	
	 if( existingSlotName ) [slotTitle setStringValue:(NSString*)existingSlotName];
	 else [slotTitle setStringValue: (NSString*)blankSlotName];
	 
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
	DACALDeviceRef	deviceID = (DACALDeviceRef)[carouselList indexOfSelectedItem]+1;
	DACALSlotNum	nextSlot = DACALSlotNextFreeNumber( deviceID, 0, 0, NULL );
	
	if( nextSlot ) {
		[slotNumber setIntValue: nextSlot];
		[self slotChanged: sender];
	}
}

-(NSString*) pendingTitle
{
	if( !pendingTitle ) return @"";
	return pendingTitle;
}
-(void)setPendingTitle:(NSString*)inTitle
{
    if (!pendingTitle || ![pendingTitle isEqual:inTitle]) {
		[pendingTitle release];
		pendingTitle = [inTitle retain];
    }
}

-(NSURL*) pendingURL { return pendingURL; }
-(void)setPendingURL:(NSURL*)inPath
{
    if (!pendingURL || ![pendingURL isEqual:inPath]) {
		[pendingURL release];
		pendingURL = [inPath retain];
    }
}

- (void)windowWillBeginSheet:(NSNotification *)notification
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	[super windowWillBeginSheet:notification];
}

- (void)deviceSelectionChanged:(NSArray *)newSet
{
	DACALDeviceRef		newBox = (DACALDeviceRef)NULL;
	
	if( [newSet count] > 0 ) newBox = (DACALDeviceRef)[newSet objectAtIndex:0];
	
	if( currentDevice != (DACALDeviceRef)NULL ) CFRelease( (CFTypeRef)currentDevice );
	currentDevice = newBox;
	if( currentDevice != (DACALDeviceRef)NULL ) CFRetain( (CFTypeRef)currentDevice );
}

- (void)assignSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
	[sheet orderOut:self];
}

- (void)startSheet:(id)sender
{
	NSInteger	index;
	NSInteger	count = DACALDevicesGetCount();
	NSInteger	node = DACALCommandCopyNode( currentDevice, NULL );
	
	[carouselList removeAllItems];
	for( index=1; index <= count; index++ )
		[carouselList addItemWithTitle:(NSString*)DACALCommandCopyName( index, NULL )];
	
	if( node == 0 ) node = 1;
	[carouselList selectItemAtIndex:node-1];
	
	[self carouselChanged:self];
	
	if( sheetWindow )
		[NSApp	beginSheet: sheetWindow
		   modalForWindow: (NSWindow*)sender
			modalDelegate: self
		   didEndSelector: @selector(assignSheetDidEnd:returnCode:contextInfo:)
			  contextInfo: nil];
}

- (void)detectedMounts:(NSArray *)newMounts
{
	if( pendingVolumes == NULL ) pendingVolumes = [NSMutableArray arrayWithCapacity:[newMounts count]+10];
	[pendingVolumes addObjectsFromArray:newMounts];
	[self pushPending];
}
@end
