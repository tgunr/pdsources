//
//  PADIndexToolbarController.m
//  PickADisc
//
//  Created by Jack Small on 7/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

@implementation PADIndexToolbarController

PADSearchRequest* PADIndexToolbarController_LastSearch = nil;

- (void)dealloc
{
	if( selectedDevices )	[selectedDevices release];
//	if( selectedSlots )		[selectedSlots release];
	if( selectedNodes )		[selectedNodes release];

	selectedDevices = nil;
//	selectedSlots = nil;
	selectedNodes = nil;
	
	[super dealloc];
}

- (id)init
{
	if( self = [super init] )
	{
		selectedDevices	= [[NSMutableArray alloc] initWithCapacity:0];
//		selectedSlots	= [[NSMutableArray alloc] initWithCapacity:0];
		selectedNodes	= [[NSMutableArray alloc] initWithCapacity:0];
	}
	return self;
}

- (void)awakeFromNib 
{
	
	[[AppController shared] setToolbarController:self];
	
//	PADSearchTermSetup();
}

- (NSProgressIndicator*)busyProgress
	{ return busyProgress; }

/*
- (void)setInspectorController:(PADInspectorController*)infoWin
{
	if( !inspectorController || ![inspectorController isEqual:infoWin] )
	{
		[infoWin retain];
		[inspectorController release];
		inspectorController = infoWin;
	}
}
*/

#pragma mark ###	Delegate methods	###


- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	BOOL		updateIt = NO;
	BOOL		anyDevicesSelected = [[self selectedDevices] count] > 0;
	BOOL		anyNodesSelected = [[self selectedNodes] count] > 0;
	BOOL		anyMountedSlots = [self nodesContainMountedSlotVolumes:[self selectedNodes]];
	BOOL		anyUnits = DACALDevicesGetCount() > 0;
	BOOL		anyFreeSlots = [self countUsedSlots:NULL];
	
	SEL			theItemAction = [item action];
	
	if( theItemAction == @selector(addSlot:) )				updateIt = anyUnits && anyFreeSlots;
	else if( theItemAction == @selector(mountDisc:) )		updateIt = anyNodesSelected;
	else if( theItemAction == @selector(checkInOut:) )		updateIt = [self allowCheck:YES];
	else if( theItemAction == @selector(checkIn:) )			updateIt = [self allowCheck:NO];
	else if( theItemAction == @selector(checkOut:) )		updateIt = [self allowCheck:YES];
	else if( theItemAction == @selector(deleteSlot:) )		updateIt = anyNodesSelected;
	else if( theItemAction == @selector(idUnits:) )			updateIt = NO; // anyUnits;
	else if( theItemAction == @selector(printReport:) )		updateIt = anyDevicesSelected;
	else if( theItemAction == @selector(retractDoor:) )		updateIt = anyDevicesSelected;
	else if( theItemAction == @selector(resetCarousel:) )	updateIt = anyDevicesSelected;
	else if( theItemAction == @selector(gotoSlot:) )		updateIt = anyNodesSelected; // anyDevicesSelected;
	else if( theItemAction == @selector(ejectVolumes:) )	updateIt = anyMountedSlots;
	else if( theItemAction == @selector(runLicense:) )		updateIt = YES;
	else if( theItemAction == @selector(requestLicense:) )	updateIt = YES;
	else													updateIt = [super validateMenuItem:item];
	
	return updateIt;
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
	
	if ( [toolbarItem tag] == 22 )		// Inspector Item
		toolValid = YES;	// [[self selectedDevices] count] > 0;

	NSLog(@"Validate Toolbar Item: %@", [toolbarItem label]);
	
	return toolValid;	
}


#pragma mark ###	State access methods	###

- (BOOL)allowCheck:(BOOL)inOrOut
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

//	Filters a list of SimpleTreeNodes to find if it contains a mounted slot volume
- (BOOL)nodesContainMountedSlotVolumes:(NSArray*)nodeArray
{
	BOOL			hasMounts = NO;
	NSEnumerator*	nodeEnum = [nodeArray objectEnumerator];
	SimpleTreeNode*	workNode = nil;
	
	while ( workNode = [nodeEnum nextObject] ) {
		hasMounts = [[[[workNode nodeData] itemElement] elementSlot] isSlotMounted];
		if( hasMounts ) break;
	}
	
	return hasMounts;
}

//	Utility function to return a toolbar item with a specific identifer
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

//	No longer used
-(NSToolbarItem*)checkOutToolbarItem
{
	return [self toobarItemWithIdentifier:@"D9318872-BA3F-47C5-AF8E-B794018E8C85"];
}

//	No longer used
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

//	This method sets the path item to reflect the current selection
-(void)adoptPathSelection
{
	SimpleTreeNode*			theNode = nil;
	SimpleTreeNode*			lastNode = nil;
	NSMutableArray*			workArray = [NSMutableArray arrayWithCapacity:0];
	NSPathComponentCell*	workCell = nil;
	
	if( pathControl == nil ) return;
	
	if( selectedNodes && ([selectedNodes count] > 0) )
		theNode = [selectedNodes objectAtIndex:0];
	
	if( theNode == nil )
		theNode = [dataController treeRoot];
	
	theNode = [theNode matchActual];
	
	while (theNode != nil) {
		if( [theNode localPathName] != nil ) {
			workCell = [[NSPathComponentCell alloc] init];
			[workCell setStringValue:[theNode localPathName]];
			[workCell setImage:[[theNode nodeData] iconRep]];
			[workCell setControlSize:NSSmallControlSize];
			
			[workArray addObject:workCell];
		} //else															// this shouldn't be possible but yet the theNode is occasionally == nil?!
			//NSLog(@"Nill item name? %@", theNode);
		if( [theNode nodeParent] != nil )
			lastNode = theNode;
		theNode = (SimpleTreeNode*)[theNode nodeParent];
	}
	
	// Insert a slot indicator
	if( [workArray count] > 1 )
	{
		workCell = [[NSPathComponentCell alloc] init];
		[workCell setStringValue:[[[[lastNode nodeData] itemElement] elementSlot] title]];
		[workCell setImage:[[lastNode nodeData] iconRep]];
		[workCell setControlSize:NSSmallControlSize];
		
		[workArray insertObject:workCell atIndex:[workArray count] - 1];
	}
	
	[pathControl setPathComponentCells:[NSArray arrayWithArray:[workArray reverseObjects]]];
	[[pathControl cell] setControlSize:NSSmallControlSize];
	[[pathControl cell] setFont:[NSFont controlContentFontOfSize:10.0]];
}

-(BOOL)countUsedSlots:(NSInteger*)slotCount
	{ return [[DACALDeviceService sharedService] countUsedSlots:slotCount]; }

//	This method activates the various toolbar item states depending on the current selection
//	in the tree/data view
-(void)adoptSelection
{
	BOOL			anyBox = NO;
	BOOL			anySlot = NO;
	BOOL			anyVolumes = [self nodesContainMountedSlotVolumes:[self selectedNodes]];
	BOOL			freeSlot = [self countUsedSlots:NULL];
	
	if( [self selectedDevices] )
		anyBox = [[self selectedDevices] count] > 0;
	if( [self selectedNodes] )	
		anySlot = [[self selectedNodes] count] > 0;
	
	if( resetButton )		[resetButton setEnabled:anyBox];
	if( closeDoorButton )	[closeDoorButton setEnabled:anyBox];
	if( assignButton )		[assignButton setEnabled:freeSlot];
	if( playButton )		[playButton setEnabled:anySlot];
	if( checkOutButton )	[checkOutButton setEnabled:[self allowCheck:YES]];
	if( checkInButton )		[checkInButton setEnabled:[self allowCheck:NO]];
	if( unassignButton )	[unassignButton setEnabled:anySlot];
	if( ejectButton )		[ejectButton setEnabled:anyVolumes];
	if( gotoButton )		[gotoButton setEnabled:anySlot];
	
	[self adoptPathSelection];
	[[PADInspectorController sharedInspector] adoptInspectorSelection:[self selectedNodes]];
	
	if( dataController )	[[dataController dataSource] updatePrompt];
}

- (void)reportNoDevice:(BOOL)hasBox
{
	hasBoxes = hasBox;
	
	[noBoxIcon setHidden:hasBox];
	[[dataController dataSource] setPrompt:(hasBox==YES) ? @"Ready" : @"No carousels detected"];	
}


#pragma mark ###	IBAction methods	###

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

- (IBAction)clickPlay:(id)sender
{ 
	NSEnumerator*		nodeEnum = [selectedNodes objectEnumerator];
	SimpleTreeNode*		workNode = nil;
	
	while ( workNode = [nodeEnum nextObject] )
		[[[workNode nodeData] itemElement] openMountedElement];

}

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
		//[[[aNode itemElement] elementSlot] toggleReservationForUser:nil onHost:nil doUI:YES];
		if( [[[aNode itemElement] elementSlot] isCheckedOut] == NO )
			[[[aNode itemElement] elementSlot] toggleReservationForUser:nil onHost:nil withUI:YES];
		
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
			[[[aNode itemElement] elementSlot] toggleReservationForUser:nil onHost:nil withUI:YES];
		
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

- (void)unassignAlertDidEnd:(NSAlert *)alert returnCode:(int)buttonPushed contextInfo:(void *)ci
{
	NSArray*	slotArray = nil;
	NSInteger	index;
	DACALSlot*	workSlot = nil;

	const int	kDeleteButton = 0;
	const int	kCancelButton = 1;

    if ( buttonPushed == kDeleteButton )
	{
		slotArray = [self selectedNodes];
		for( index=0; index < [slotArray count]; index++ )
		{
			workSlot = [[[[slotArray objectAtIndex:index] nodeData] itemElement] elementSlot];
			[workSlot unassignSlotIndex];
		}

		[(TreeController*)dataController deleteSelections:self];
		
		[self resetSelection];
		[self adoptSelection];
		//[self resetSelectedNodesAndAdoptSelection:YES];
		//[(TreeController*)dataController deletedSelections];
		
		[AppController playUISound:kASSystemSoundShred];
		[[dataController undoManager] removeAllActions];			// Seriously, you can not undo anything after this!
		
		[PADSearchService updateAllSearches];
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

- (IBAction)clickGotoSlot:(id)sender
	{ [DACALSlot moveDevicesToSlotsOfNodes:[self selectedNodes]]; }

- (IBAction)clickPrintReport:(id)sender
	{ [[AppController shared] printReport:self]; }

- (IBAction)clickEject:(id)sender
	{ [DACALSlot ejectSlotVolumesOfNodes:[self selectedNodes]]; }

- (IBAction)clickOpen:(id)sender
{ }

- (IBAction)clickInspector:(id)sender
{
	[[PADInspectorController sharedInspector] toggleInspectorPanel:sender];
}

- (IBAction)provideFeedback:(id)sender
{
	return [[AppController shared] provideFeedback:sender];
}


#pragma mark ###	Toolbar Search	###

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
				[[dataController outlineView] setCurrentSearch:PADIndexToolbarController_LastSearch];
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
		[[dataController outlineView] setCurrentSearch:PADIndexToolbarController_LastSearch];
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


#pragma mark ###	Selection Management	###

- (NSMutableArray*)selectedDevices { return selectedDevices; }

- (void)setSelectedDevices: (NSMutableArray*)deviceList
{
    if (!selectedDevices || ![selectedDevices isEqual:deviceList]) {
		if( deviceList ) [deviceList retain];
		if( selectedDevices ) [selectedDevices release];
		selectedDevices = deviceList;
		//[addVolumeController deviceSelectionChanged:deviceList];
	}	
}

- (void)addSelectedDevice:(DACALDeviceRef)theDevice adoptSelection:(BOOL)doAdopt
{
	if( theDevice != kDACALNullDevice )
		if( ![selectedDevices containsObject:(id)theDevice]) {
			[selectedDevices addObject:(id)theDevice];
			[addVolumeController deviceSelectionChanged:selectedDevices];
			if( doAdopt )
				[self adoptSelection];
		}
}

- (void)setSelectedDevice: (DACALDeviceRef)theDevice adoptSelection:(BOOL)doAdopt
{
	[selectedDevices removeAllObjects];
	if( theDevice != kDACALNullDevice )
		[self addSelectedDevice:theDevice adoptSelection:doAdopt];
	else if( doAdopt )
			[self adoptSelection];
}	
/*	
	NSArray*	newList;
	
	if( theDevice == kDACALNullDevice ) newList = [NSArray array];
	else newList = [NSArray arrayWithObject:(id)theDevice];	

	[self setSelectedDevices:newList];
	[self adoptSelection];
*/

/*
- (void)setSelectedSlots: (NSMutableArray*)slotList
{
    if (!selectedSlots || ![selectedSlots isEqual:slotList]) {
		if( slotList ) [slotList retain];
		if( selectedSlots ) [selectedSlots release];
		selectedSlots = slotList;
    }
	// [self adoptSelection];
}

- (void)setSelectedSlot: (DACALSlotNum)theSlot
{
	NSArray*	newList = [NSArray arrayWithObject:[NSNumber numberWithLong:(NSInteger)theSlot]];	
	[self setSelectedSlots:newList];
}

- (NSMutableArray*)selectedSlots; { return selectedSlots; }
*/

- (NSMutableArray*)selectedNodes; { return selectedNodes; }

- (void)setSelectedNodes: (NSMutableArray*)nodeList
{
    if (!selectedNodes || ![selectedNodes isEqual:nodeList]) {
		if( nodeList ) [nodeList retain];
		if( selectedNodes ) [selectedNodes release];
		selectedNodes = nodeList;
    }
}

- (void)addSelectedNode:(SimpleTreeNode*)theNode adoptSelection:(BOOL)doUI
{
	if( [selectedNodes indexOfObject:theNode] == NSNotFound )
		[selectedNodes addObject:theNode];
	
	int	nIndex = 0;
	
	[self setSelectedDevice:kDACALNullDevice adoptSelection:NO];
	for( nIndex = 0; nIndex < [selectedNodes count]; nIndex++ )
		[self addSelectedDevice:[[[selectedNodes objectAtIndex:nIndex] nodeData] itemDevice] adoptSelection:NO];
	
	if( doUI )
		[self adoptSelection];
}

- (void)setSelectedNode: (SimpleTreeNode*)theNode adoptSelection:(BOOL)doUI
{
	[selectedNodes removeAllObjects];
	
	if( theNode )
		[self addSelectedNode:theNode adoptSelection:doUI];
	else if( doUI )
		[self adoptSelection];
}	
//	NSArray*	newList = (theNode) ? [NSArray arrayWithObject:theNode] : [NSArray array];	
//	[self setSelectedNodes:newList];

/*
- (void)addSelectedNode:(SimpleTreeNode*)theNode
{
		if( !selectedNodes ) [self addSelectedNode:theNode];
	else if( ![selectedNodes containsObject:(id)theNode])
			[self setSelectedNodes:[selectedNodes arrayByAddingObject:(id)theNode]];
}
*/

- (void)resetSelectedNodesAndAdoptSelection:(BOOL)doUI
{
	[self setSelectedNode:nil adoptSelection:doUI];
}

- (void)resetSelection
{
	[selectedDevices removeAllObjects];
	[self resetSelectedNodesAndAdoptSelection:NO];
//	[self setSelectedDevice:kDACALNullDevice];
//	[self setSelectedNode:nil];	
}

@end
