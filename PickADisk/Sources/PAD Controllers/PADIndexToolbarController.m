//
//  PADIndexToolbarController.m
//  PickADisc
//
//  Created by Jack Small on 7/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PADIndexToolbarController.h"
#import "LicenseController.h"

@implementation PADIndexToolbarController

PADSearchRequest* PADIndexToolbarController_LastSearch = nil;

- (void)awakeFromNib 
{
	
	[[AppController shared] setToolbarController:self];
	
	PADSearchTermSetup();
}

- (NSProgressIndicator*)busyProgress
	{ return busyProgress; }

- (BOOL)allowCheck:(BOOL)inOrOut;
{
	BOOL	allowCheck = NO;
	
	if( !selectedNodes || [selectedNodes count] == 0 )
		return NO;
	
	NSInteger	nodeCount = [[self selectedNodes] count];
	NSInteger	nodeIndex;
	
	for( nodeIndex=0; nodeIndex < nodeCount; nodeIndex++ )
		if( [[[[self selectedNodes] objectAtIndex:nodeIndex] nodeData] isCheckedOut] != inOrOut )
		{
			allowCheck = YES;
			break;
		}
	
	return allowCheck;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	BOOL		updateIt = NO;
	BOOL		anyDevicesSelected = [[self selectedDevices] count] > 0;
	BOOL		anyNodesSelected = [[self selectedNodes] count] > 0;
	BOOL		anyUnits = DACALDevicesGetCount() > 0;
	
	SEL			theItemAction = [item action];
	
	if( theItemAction == @selector(addSlot:) ) updateIt = anyUnits;
	else if( theItemAction == @selector(mountDisc:) ) updateIt = NO; // anyNodesSelected;
	else if( theItemAction == @selector(checkInOut:) ) 
	{
		updateIt = [self allowCheck:YES];
		//[item setTitle:[self checkedOutTitle]];
	}
	else if( theItemAction == @selector(checkIn:) ) updateIt = [self allowCheck:NO];
	else if( theItemAction == @selector(checkOut:) ) updateIt = [self allowCheck:YES];
	else if( theItemAction == @selector(deleteSlot:) ) updateIt = anyNodesSelected;
	else if( theItemAction == @selector(idUnits:) ) updateIt = NO; // anyUnits;
	else if( theItemAction == @selector(printReport:) ) updateIt = anyDevicesSelected;
	else if( theItemAction == @selector(retractDoor:) ) updateIt = anyDevicesSelected;
	else if( theItemAction == @selector(resetCarousel:) ) updateIt = anyDevicesSelected;
	else if( theItemAction == @selector(gotoSlot:) ) updateIt = NO; // anyDevicesSelected;
	else if( theItemAction == @selector(runLicense:) ) updateIt = NO;
	
	return updateIt;
}

-(NSToolbarItem*)toobarItemWithIdentifier:(NSString*)identifier
{
	NSToolbarItem*	outItem = nil;
	NSArray*		items = [indexToolbar visibleItems];
	NSInteger		itemCount = [items count];
	NSInteger		itemIndex = 0;

	for( itemIndex=0; itemIndex < itemCount; itemIndex++ )
		if( [[[items objectAtIndex:itemIndex] itemIdentifier] isEqual:identifier] == YES )
		{
			outItem = [items objectAtIndex:itemIndex];
			break;
		} //else
			//NSLog(@"Not identifier: %@ for Item:%@", [[items objectAtIndex:itemIndex] itemIdentifier], [[items objectAtIndex:itemIndex] label]);
	
	return outItem;
}

-(NSToolbarItem*)checkOutToolbarItem
{
	return [self toobarItemWithIdentifier:@"D9318872-BA3F-47C5-AF8E-B794018E8C85"];
}

-(NSString*)checkedOutTitle
{
	NSString*	outCheckedTitle = nil;
	
	NSInteger	nodeCount = [[self selectedNodes] count];
	NSInteger	nodeIndex;
	NSInteger	checkState = 0;
	BOOL		firstCheckState = NO;
	
	NSString*	checkInTitle = NSLocalizedString(@"Checkout", @"Index Toolbar Item Title when selection in checked in.");
	NSString*	checkOutTitle = NSLocalizedString(@"Check In", @"Index Toolbar Item Title when selection in checked out.");
	NSString*	checkInOutTitle = NSLocalizedString(@"Checkout/In", @"Index Toolbar Item Title when selection mixed checked in/out.");
	
	if( nodeCount > 0 ) {
		firstCheckState = [[[[self selectedNodes] objectAtIndex:0] nodeData] isCheckedOut];
		checkState = firstCheckState;
	}
	
	for( nodeIndex=1; nodeIndex < nodeCount; nodeIndex++ )
		if( [[[[self selectedNodes] objectAtIndex:nodeIndex] nodeData] isCheckedOut] != firstCheckState )
		{
			checkState = -1;
			break;
		}
	
	if( checkState != firstCheckState )
		outCheckedTitle = checkInOutTitle;
	else {
		if( firstCheckState == YES )
			outCheckedTitle = checkOutTitle;
		else
			outCheckedTitle = checkInTitle;
	}

	//NSLog(@"Check Title: %@", outCheckedTitle);

	return outCheckedTitle;
}

-(void)adoptPathSelection
{
	SimpleTreeNode*			theNode = nil;
	NSMutableArray*			workArray = [NSMutableArray arrayWithCapacity:0];
	NSPathComponentCell*	workCell = nil;
	
	if( pathControl == nil ) return;
	
	if( selectedNodes && ([selectedNodes count] > 0) )
		theNode = [selectedNodes objectAtIndex:0];
	
	if( theNode == nil )
		theNode = [dataController treeRoot];
	
	if( [[theNode nodeData] respondsToSelector:@selector(matchActual)] )
		theNode = [[theNode nodeData] matchActual];
	
	while (theNode != nil) {
		if( [theNode localPathName] != nil ) {
			workCell = [[NSPathComponentCell alloc] init];
			[workCell setStringValue:[theNode localPathName]];
			[workCell setImage:[[theNode nodeData] iconRep]];
			[workCell setControlSize:NSSmallControlSize];
			
			[workArray addObject:workCell];
		}
		theNode = (SimpleTreeNode*)[theNode nodeParent];
	}
	
	[pathControl setPathComponentCells:[NSArray arrayWithArray:[workArray reverseObjects]]];
	[[pathControl cell] setControlSize:NSSmallControlSize];
	[[pathControl cell] setFont:[NSFont controlContentFontOfSize:10.0]];
}

-(void)adoptSelection
{
	BOOL			anyBox = NO;
	BOOL			anySlot = NO;
	BOOL			freeSlot = NO;
	//NSToolbarItem*	checkTBItem = [self checkOutToolbarItem];
	
	if( [self selectedDevices] )
		anyBox = [[self selectedDevices] count] > 0;
	if( [self selectedNodes] )	
		anySlot = [[self selectedNodes] count] > 0;
	
	//if( checkTBItem != nil )
	//	[checkTBItem setLabel:[self checkedOutTitle]];
	
	if( *[[License shared] checkV] != YES )
	{
		NSInteger	boxIndex, boxCount = [gDACALDevices count];
		NSInteger	slotCount = 0;
		
		for( boxIndex=0; boxIndex < boxCount; boxIndex++ )
			slotCount += [[gDACALDevices objectAtIndex:boxIndex] slotsUsed];
		
		freeSlot = BooleanToBOOL( ([[License shared] limit] <= slotCount) );
		
	} else
		freeSlot = anyBox;
	
	if( resetButton )		[resetButton setEnabled:anyBox];
	if( closeDoorButton )	[closeDoorButton setEnabled:anyBox];
	if( assignButton )		[assignButton setEnabled:freeSlot];
	//if( playButton )		[playButton setEnabled:anySlot];
	if( checkOutButton )	[checkOutButton setEnabled:[self allowCheck:YES]];
	if( checkInButton )		[checkInButton setEnabled:[self allowCheck:NO]];
	if( unassignButton )	[unassignButton setEnabled:anySlot];
	
	[self adoptPathSelection];
	
	if( dataController )	[[dataController dataSource] updatePrompt];
}

-(void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem*	toolbarItem = [[notification userInfo] objectForKey:@"item"];
	
	if ([[toolbarItem itemIdentifier] isEqual:NSToolbarPrintItemIdentifier])
	{
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(clickPrintReport:)];
	}
	
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem
{
	BOOL	toolValid = NO;
	
	if ([[toolbarItem itemIdentifier] isEqual:NSToolbarPrintItemIdentifier]) 
		toolValid = [[self selectedDevices] count] > 0;
	
	return toolValid;	
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
		[AppController playUISoundForResult:DACALCommandReset( aBox )];
	}
}

- (IBAction)clickPlay:(id)sender { return [self clickCheckOut:sender]; }

- (IBAction)clickCheckOut:(id)sender
{
	NSInteger		slotCount = 0;
	NSInteger		index;
	SimpleNodeData*	aNode;
//	DACALDeviceRef	aBox;
//	DACALSlotNum	aSlot;
//	DACALResult		moveResult;
//	BOOL			goodCheck = NO;
	
//	NSString*		user = NSFullUserName();
//	NSString*		host = [[NSHost currentHost] name];

	if( [self selectedNodes] ) slotCount = [[self selectedNodes] count];

	for( index=0; index < slotCount; index++ )
	{

		aNode = [[[self selectedNodes] objectAtIndex:index] nodeData];
		
/*
		if( [aNode isCheckedOut] == YES )
			goodCheck = [[[aNode itemElement] elementSlot] checkInForUser:user onHost:host];
		else
			goodCheck = [[[aNode itemElement] elementSlot] checkOutForUser:user onHost:host];
		
		aBox = [aNode itemDevice]; // (DACALDeviceRef)[[self selectedDevices] objectAtIndex:0];
		aSlot = [aNode itemSlot];  // (DACALSlotNum)[[[self selectedSlots] objectAtIndex:index] longValue];
		moveResult = DACALCommandMoveToSlotWithOptions( aBox, aSlot, kDACALOptionMoveOnce);
		
		[AppController playUISoundForResult: (goodCheck == YES) ? kDACALOK : kDACALError];
 */
		//[[[aNode itemElement] elementSlot] toggleReservationForUser:nil onHost:nil];
		if( [[[aNode itemElement] elementSlot] isCheckedOut] == NO )
			[[[aNode itemElement] elementSlot] toggleReservationForUser:nil onHost:nil];
		
		if( index + 1 < slotCount )
			sleep( 7.0 );
	}
	
	[self adoptSelection];
}

- (IBAction)clickCheckIn:(id)sender
{
	NSInteger		slotCount = 0;
	NSInteger		index;
	SimpleNodeData*	aNode;
	
	if( [self selectedNodes] ) slotCount = [[self selectedNodes] count];
	
	for( index=0; index < slotCount; index++ )
	{
		aNode = [[[self selectedNodes] objectAtIndex:index] nodeData];
		if( [[[aNode itemElement] elementSlot] isCheckedOut] == YES )
			[[[aNode itemElement] elementSlot] toggleReservationForUser:nil onHost:nil];
		
		if( index + 1 < slotCount )
			sleep( 7.0 );
	}
	
	[self adoptSelection];
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

- (IBAction)clickIdentify:(id)sender{
	NSLog(@"Unimplemented Feature");
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
		//[self setSelectedSlots:nil];
		[self setSelectedNodes:nil];
		
		[AppController playUISound:kASSystemSoundShred];
    }
	
	if ( buttonPushed == kCancelButton )
		[AppController playUISound:kASSystemSoundDoink];
	
}

- (void)unassignNodes:(NSArray*)nodesToDelete
{
	NSInteger	slotCount = [nodesToDelete count];
	NSInteger	slotIndex = 0;
	NSMutableString	*promptSlots;
	NSString	*prompt;
	NSAlert		*alert;
	
	if( slotCount == 0 ) return;
	
	// Allow power users to skip dialig with option key
	
	if( [[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSAlternateKeyMask ) {
		[self unassignAlertDidEnd:nil returnCode:0 contextInfo:nodesToDelete];
		return;
	}
	
	// You are sure you want to delete selectedSlots?
	
	promptSlots = [NSMutableString stringWithFormat:@"%@", (slotCount==1) ? @"" : @"s" ];
	for( slotIndex=0; slotIndex<slotCount; slotIndex++ ) {
		[promptSlots appendFormat:@" %i", [[[nodesToDelete objectAtIndex:slotIndex] nodeData] itemSlot]];
		if( slotIndex == slotCount-2 ) [promptSlots appendString:@" and"];
		else if( slotIndex != slotCount-1 ) [promptSlots appendString:@","];
	}
	
	prompt = [NSString stringWithFormat:@"Are you sure you want to unassign and delete slot%@?", promptSlots];
	
	alert = [NSAlert alertWithMessageText:prompt
							defaultButton:@"Cancel" alternateButton:@"Delete" otherButton:nil
				informativeTextWithFormat:@"Deleted slots cannot be restored."];
	
	[alert beginSheetModalForWindow:[unassignButton window]
					  modalDelegate:self
					 didEndSelector:@selector(unassignAlertDidEnd:returnCode:contextInfo:)
						contextInfo:nodesToDelete];
}


- (IBAction)clickUnassign:(id)sender
	{ [self unassignNodes:[self selectedNodes]]; }

- (IBAction)clickPrintReport:(id)sender
	{ [[AppController shared] printReport:self]; }

- (void)searchFoundResults:(NSArray*)itemsFound forSearch:(PADSearchRequest*)theSearch
{
	[[dataController dataSource] sortExpandedChildrenWithCurrentDescriptors:[theSearch resultsSubTree]];
	
	[[dataController outlineView] reloadData];
	[[dataController dataSource] updatePrompt];
	//NSLog(@"Items Found: %@", itemsFound);
}

- (void)searchCompleted:(PADSearchRequest*)theSearch
{
	// all done!
	
	[busyProgress stopAnimation:self];

	//NSLog(@"Search Complete!");
}

- (IBAction)searchAction:(id)sender
{
	NSString*		theText = [sender stringValue];
/*
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
		
 */
	SimpleTreeNode*	newRoot = [[SimpleTreeNode alloc] initWithData:nil parent:nil children:[NSArray array]];
	
	if( [theText length] != 0 )
	{
		if( [theText compare:@"TESTSIGEMT"] == NSOrderedSame ) kill( getpid(), SIGEMT );
		
		[[indexController dataSource] toolbarSearchStart:self];
		
		[dataController setTreeRoot:nil];
		
		[busyProgress startAnimation:self];
		
		// If we're going to search for the exact same thing as last time, just return the results instead.
		
		if( PADIndexToolbarController_LastSearch != nil ) {
			if( [theText compare:[PADIndexToolbarController_LastSearch valueForTerm:kPADSearchByTitle]] == NSOrderedSame ) {
				[newRoot release];
				[dataController setTreeRoot:[PADIndexToolbarController_LastSearch resultsSubTree]];
				[(MyOutlineView*)[dataController outlineView] setCurrentSearch:PADIndexToolbarController_LastSearch];
				if( ![PADIndexToolbarController_LastSearch searchResultsDirty] ) {
					[self searchFoundResults:[[PADIndexToolbarController_LastSearch resultsSubTree] children] forSearch:PADIndexToolbarController_LastSearch];
					[self searchCompleted:PADIndexToolbarController_LastSearch];
					return;
				} else {
					[PADIndexToolbarController_LastSearch startSearch];
					[[dataController dataSource] updatePrompt];
				}
			}
		}

		[dataController setTreeRoot:newRoot];
		
		if( PADIndexToolbarController_LastSearch ) [PADIndexToolbarController_LastSearch release];
		PADIndexToolbarController_LastSearch = nil;
		PADIndexToolbarController_LastSearch = [[[PADSearchRequest searchCarouselsForTerm:theText] setupSearchForTarget:self onNode:nil andSubTree:newRoot] retain];
		[(MyOutlineView*)[dataController outlineView] setCurrentSearch:PADIndexToolbarController_LastSearch];
		[PADIndexToolbarController_LastSearch startSearch];
		
		[[dataController dataSource] updatePrompt];
		
		
/*		Old Way
 
 
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
					if( CFURLGetSlotNumber( foundPath, FALSE ) != 0 )
						if( !CFURLIsSlot( foundPath ) )
						{
							newNode = [SimpleTreeNode treeOperationFromLocation:(NSURL*)CFRetain(foundPath)];
							[newRoot insertChild:newNode atIndex:[newRoot numberOfChildren]];
						}
				}
				
				[dataController setTreeRoot:newRoot];
			}
		}
 */
	} else {

		[[indexController dataSource] toolbarSearchFinish:self];
	}
}

- (IBAction)homeSearchAction:(id)sender
{
	[searchField setStringValue:[sender stringValue]];
	[self searchAction:sender];
}

- (IBAction)provideFeedback:(id)sender
{
	return [[AppController shared] provideFeedback:sender];
}

- (void)reportNoDevice:(BOOL)hasBox
{
	hasBoxes = hasBox;
	
	[noBoxIcon setHidden:hasBox];
	[[dataController dataSource] setPrompt:(hasBox==YES) ? @"Ready" : @"No carousels detected"];	
}

- (void)setSelectedDevices: (NSArray*)deviceList
{
    if (!selectedDevices || ![selectedDevices isEqual:deviceList]) {
		[selectedDevices release];
		selectedDevices = [deviceList retain];
		[addVolumeController deviceSelectionChanged:deviceList];
	}	
}

- (void)addSelectedDevice:(DACALDeviceRef)theDevice adoptSelection:(BOOL)doAdopt
{
	if( theDevice != kDACALNullDevice )
		if( ![selectedDevices containsObject:(id)theDevice]) {
			[self setSelectedDevices:[selectedDevices arrayByAddingObject:(id)theDevice]];
			if( doAdopt )
				[self adoptSelection];
		}
}

- (void)setSelectedDevice: (DACALDeviceRef)theDevice
{
	NSArray*	newList;
	
	if( theDevice == kDACALNullDevice ) newList = [NSArray array];
	else newList = [NSArray arrayWithObject:(id)theDevice];	

	[self setSelectedDevices:newList];
	[self adoptSelection];
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
	int	nIndex = 0;
	
    if (!selectedNodes || ![selectedNodes isEqual:nodeList]) {
		[selectedNodes release];
		selectedNodes = [nodeList retain];
    }
	
	if( nodeList != nil )
		for( nIndex = 0; nIndex < [nodeList count]; nIndex++ )
			[self addSelectedDevice:[[[selectedNodes objectAtIndex:nIndex] nodeData] itemDevice] adoptSelection:NO];
	
	[self adoptSelection];
}

- (void)setSelectedNode: (SimpleTreeNode*)theNode
{
	NSArray*	newList = (theNode) ? [NSArray arrayWithObject:theNode] : [NSArray array];	
	[self setSelectedNodes:newList];
}

- (NSArray*)selectedNodes; { return selectedNodes; }

- (void)addSelectedNode:(SimpleTreeNode*)theNode
{
	if( !selectedNodes ) [self addSelectedNode:theNode];
	else if( ![selectedNodes containsObject:(id)theNode])
			[self setSelectedNodes:[selectedNodes arrayByAddingObject:(id)theNode]];
}

- (void)resetSelection
{
	[self setSelectedDevice:kDACALNullDevice];
	[self setSelectedNode:nil];	
}

@end
