//
//  PADIndexToolbarController.m
//  PickADisc
//
//  Created by Jack Small on 7/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PADIndexToolbarController.h"


@implementation PADIndexToolbarController

- (void)awakeFromNib 
{
	
	[[AppController shared] setToolbarController:self];
}

-(void)adoptSelection
{
	NSInteger	boxCount = 0;
//	NSInteger	slotCount = 0;
	BOOL		anyBox = NO;
	BOOL		anySlot = NO;
	
	if( [self selectedDevices] ) boxCount = [[self selectedDevices] count];
	if( boxCount > 0 ) anyBox = YES;
	
//	if( [self selectedSlots] ) slotCount = [[self selectedSlots] count];
//	if( slotCount > 0 ) anySlot = YES;
	
	if( [self selectedNodes] ) {
		anyBox = YES;
		anySlot = YES;
	}
	
	if( resetButton )		[resetButton setEnabled:anyBox];
	if( closeDoorButton )	[closeDoorButton setEnabled:anyBox];
	if( assignButton )		[assignButton setEnabled:anyBox];
	if( playButton )		[playButton setEnabled:anySlot];
	if( checkOutButton )	[checkOutButton setEnabled:anySlot];
	if( unassignButton )	[unassignButton setEnabled:anySlot];
	
	if( dataController )	[[dataController dataSource] updatePrompt];
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
	NSInteger		slotCount = 0;
	NSInteger		index;
	SimpleNodeData*	aNode;
	DACALDeviceRef	aBox;
	DACALSlotNum	aSlot;

	if( [self selectedNodes] ) slotCount = [[self selectedNodes] count];

	for( index=0; index < slotCount; index++ )
	{
		aNode = [[[self selectedNodes] objectAtIndex:index] nodeData];
		aBox = [aNode itemDevice]; // (DACALDeviceRef)[[self selectedDevices] objectAtIndex:0];
		aSlot = [aNode itemSlot];  // (DACALSlotNum)[[[self selectedSlots] objectAtIndex:index] longValue];
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

// this is not used
- (void)assignSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
	[sheet orderOut:self];
}

- (IBAction)clickAssign:(id)sender { 
	//if( addVolumeController ) [addVolumeController startSheet:[assignButton window]];
	PADAddVolumeController* pvc = [[AppController shared] addVolumeController];
	[pvc startSheet:[assignButton window]];
}

- (void)unassignAlertDidEnd:(NSAlert *)alert returnCode:(int)rc contextInfo:(void *)ci
{
	NSArray*	slotArray = [self selectedNodes];
	NSInteger	buttonPushed = rc;
	NSInteger	index;
	DACALDeviceRef	aBox;
	DACALSlotNum	aSlot;

	const int	kDeleteButton = 0;
	const int	kCancelButton = 1;

    if ( buttonPushed == kDeleteButton )
	{
		for( index=0; index < [slotArray count]; index++ )
		{
			aBox = (DACALDeviceRef)[[[slotArray objectAtIndex:index] nodeData] itemDevice];
			aSlot = (DACALSlotNum)[[[slotArray objectAtIndex:index] nodeData] itemSlot];
			DACALSlotDeleteIndex( aBox, aSlot );
		}

		if( dataController ) [(TreeController*)dataController deleteSelections:self];
		[self setSelectedSlots:nil];
		[self setSelectedNodes:nil];
		
		[AppController playUISound:kASSystemSoundShred];
    }
	
	if ( buttonPushed == kCancelButton )
		[AppController playUISound:kASSystemSoundDoink];
	
}

- (IBAction)clickUnassign:(id)sender
{
	NSInteger	slotCount = 0;
	NSInteger	slotIndex = 0;
	NSMutableString	*promptSlots;
	NSString	*prompt;
	NSAlert		*alert;

	if( [self selectedNodes] ) slotCount = [[self selectedNodes] count];
	if( !slotCount ) return;

	// Allow power users to skip dialig with option key

	if( [[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSAlternateKeyMask ) {
		[self unassignAlertDidEnd:nil returnCode:NO contextInfo:nil];
		return;
	}

	// You are sure you want to delete selectedSlots?

	promptSlots = [NSMutableString stringWithFormat:@"%@", (slotCount==1) ? @"" : @"s" ];
	for( slotIndex=0; slotIndex<slotCount; slotIndex++ ) {
		[promptSlots appendFormat:@" %i", [[[[self selectedNodes] objectAtIndex:slotIndex] nodeData] itemSlot]];
		if( slotIndex == slotCount-2 ) [promptSlots appendString:@" and"];
		else if( slotIndex != slotCount-1 ) [promptSlots appendString:@","];
	}

	prompt = [NSString stringWithFormat:@"Are you sure you want to unassign and delete slot%@?", promptSlots];

	alert = [NSAlert alertWithMessageText:prompt
		defaultButton:@"Cancel" alternateButton:@"Unassign" otherButton:nil
		informativeTextWithFormat:@"Deleted slots cannot be restored."];

	[alert beginSheetModalForWindow:[unassignButton window] modalDelegate:self didEndSelector:@selector(unassignAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)searchAction:(id)sender
{
	NSString*		theText = [sender stringValue];
	OSErr			theErr;

	FSRef			userLibraryFolder;
	NSURL*			theCPath = nil;
	NSString*		theCPathStr = nil;
	NSURL*			findURL = nil;
	NSString*		findArgs = nil;
	CFStringRef		outItems = NULL;
	CFStringRef		outDelim = CFStringCreateWithCString( NULL, "\n", kCFStringEncodingUTF8 );
	CFArrayRef		outList = NULL;
	CFURLRef		foundPath = NULL;
	SimpleTreeNode*	newRoot = [[SimpleTreeNode alloc] initWithData:nil parent:nil children:[NSArray array]];
	SimpleTreeNode*	newNode = NULL;
	int				resultIndex;
		
	[[indexController outlineView] deselectAll:self]; 
	[dataController setTreeRoot:nil];
	
	if( [theText length] != 0 ) {
		
		theErr = FSFindFolder( kUserDomain, kDACALCarouselsFolderType, TRUE, &userLibraryFolder );
		if( theErr != 0 ) printf( "Could not find user library! Error:%i\n", theErr );
		else {
			theCPath = (NSURL*)CFURLCreateFromFSRef(NULL, &userLibraryFolder);
			theCPathStr = (NSString*)CFURLCopyPath( (CFURLRef)theCPath );
			theCPathStr = [theCPathStr substringToIndex:[theCPathStr length]-1];
			
			findArgs = [NSString stringWithFormat:@"\"%@\" -iname \"*%@*\"", theCPathStr, theText];
			findURL = [NSURL URLWithString:@"/usr/bin/find"];

			outItems = CFStringCreateFromCommandPipe( NULL, (CFURLRef)findURL, (CFStringRef)findArgs, NULL );
			if( outItems != NULL ) {
				
				outList = CFStringCreateArrayBySeparatingStrings( NULL, outItems, outDelim );
				
				for( resultIndex = 0; resultIndex < CFArrayGetCount( outList ); resultIndex++ )
				{
					CFStringRef	tempPathName = (CFStringRef)CFArrayGetValueAtIndex( outList, resultIndex);
					foundPath = CFURLCreateWithFileSystemPath( NULL, tempPathName, kCFURLPOSIXPathStyle, FALSE );
					newNode = [SimpleTreeNode treeFromLocation:(NSURL*)CFRetain(foundPath)];
					
					[newRoot insertChild:newNode atIndex:[newRoot numberOfChildren]];
				}
				
				[dataController setTreeRoot:newRoot];
			}
		}
	}
	
	[[dataController dataSource] updatePrompt];
}


- (void)setSelectedDevices: (NSArray*)deviceList
{
    if (!selectedDevices || ![selectedDevices isEqual:deviceList]) {
	[selectedDevices release];
	selectedDevices = [deviceList retain];
    }
	[addVolumeController deviceSelectionChanged:deviceList];
	[self adoptSelection];
}

- (void)addSelectedDevice:(DACALDeviceRef)theDevice
{
	if( ![selectedDevices containsObject:(id)theDevice])
		[self setSelectedDevices:[selectedDevices arrayByAddingObject:(id)theDevice]];
}

- (void)setSelectedDevice: (DACALDeviceRef)theDevice
{
	NSArray*	newList = [NSArray arrayWithObject:(id)theDevice];	
	[self setSelectedDevices:newList];
}
- (NSArray*)selectedDevices { return selectedDevices; }

- (void)setSelectedSlots: (NSArray*)slotList
{
    if (!selectedSlots || ![selectedSlots isEqual:slotList]) {
	[selectedSlots release];
	selectedSlots = [slotList retain];
    }
	// [self adoptSelection];
}

- (void)setSelectedSlot: (DACALSlotNum)theSlot
{
	NSArray*	newList = [NSArray arrayWithObject:[NSNumber numberWithLong:(NSInteger)theSlot]];	
	[self setSelectedSlots:newList];
}

- (NSArray*)selectedSlots; { return selectedSlots; }

- (void)setSelectedNodes: (NSArray*)nodeList
{
	int	nIndex;
	
    if (!selectedNodes || ![selectedNodes isEqual:nodeList]) {
		[selectedNodes release];
		selectedNodes = [nodeList retain];
    }
	
	if( nodeList != nil )
		for( nIndex = 0; nIndex < [nodeList count]; nIndex++ )
			[self addSelectedDevice:[[[selectedNodes objectAtIndex:nIndex] nodeData] itemDevice]];
	
	[self adoptSelection];
}

- (void)setSelectedNode: (SimpleTreeNode*)theNode
{
	NSArray*	newList = [NSArray arrayWithObject:theNode];	
	[self setSelectedNodes:newList];
}

- (NSArray*)selectedNodes; { return selectedNodes; }

@end
