//
//  DACALTreeDataSource.m
//  DragNDropOutlineView
//
//  Created by Jack Small on 7/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DACALTreeDataSource.h"
#import "pmsDACALUtility.h"

@implementation DACALTreeDataSource
static DACALTreeDataSource *DACALTreeDataSource_shared;

- (id)init
{
    if (DACALTreeDataSource_shared) 
	{
        [self autorelease];
        return DACALTreeDataSource_shared;
    }
	if (![super init]) return nil;
	
	DACALTreeDataSource_shared = self;
	return self;
}

- (SimpleTreeNode*)createInitialTree:(id)tree
{
	SimpleTreeNode*		theOutputTree = nil;
	SimpleTreeNode*		theWorkNode = nil;
//	SimpleTreeNode*		theChildNode = nil;
//	SimpleTreeNode*		theSubtreeNode = nil;
//	SimpleTreeNode*		theSubtreeChild = nil;
//	int					index, slotindex, slotcount;
//	int					count = 0;
//	NSString*			boxName;
//	NSString*			boxDirName;
//	CFStringRef			theSlotTitle;
//	CFStringRef			theSlotName;
//	CFURLRef			dataURL = NULL; 
//	CFURLRef			boxURL = NULL;
//	CFURLRef			slotURL = NULL;
//	NSArray*			slotFolders = nil;
//	DACALDeviceRef		theBoxRef = (DACALDeviceRef)NULL;
//	DACALDeviceNode		theBoxNode = 0;
//	DACALSlotNum		slotNum = 0;
//	OSType				slotIconType = kGenericCDROMIcon;
//	OSType				compareIconType = 0;

//	FSRef		userLibraryFolder;
//	OSErr		theErr;
	
	[tree setAllowGroupRowLook:YES];
	[tree setAllowBetweenDrop:YES];

	PADBOX_VALID_BEGIN
	
//	theErr = FSFindFolder( kUserDomain, kDACALCarouselsFolderType, TRUE, &userLibraryFolder );
//	if( theErr != 0 ) printf( "Could not find user library! Error:%i\n", theErr );
//	else dataURL = CFURLCreateFromFSRef(NULL, &userLibraryFolder);

	
	// Load our initial outline view data from the "InitInfo" dictionary.
	NSDictionary *initData = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"InitInfo" ofType: @"dict"]];
	if( initData != nil ) theOutputTree = [SimpleTreeNode treeFromDictionary: initData];	
	
//	#warning Index 1 should not be hard coded!
//	theWorkNode = (SimpleTreeNode*)[theOutputTree childAtIndex:1];											
	theWorkNode = (SimpleTreeNode*)[theOutputTree childWithName:PADINDEX_GROUPTITLE_DEVICES];											
	[[theWorkNode nodeData] setItemType: kPADTypeGroupDevices];

/*
	for( index=0; index < count; index++ )
	{
		theBoxNode = index+1;
		boxName = (NSString*)DACALCommandCopyName( theBoxNode, NULL );										// Create a leaf in the Carousels group for the device
		if( boxName == NULL ) boxName = [NSString stringWithFormat:@"Carousel %i", theBoxNode];				// This should not ever happen anymore.
		theChildNode = [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData leafDataWithName:boxName] parent:nil children:[NSArray array]] autorelease];

		//boxDirName = [NSString stringWithFormat:@"Carousel %i.carousel", theBoxNode];						// Create a url to the device folder
		//if( dataURL ) boxURL = CFURLCreateCopyAppendingPathComponent(NULL, dataURL, (CFStringRef) boxDirName, TRUE);
		boxURL = DACALCommandCopyPath( theBoxNode, NULL );
		if( boxURL ) [[theChildNode nodeData] setLocation: (NSURL*)boxURL];

		[[theChildNode nodeData] setIconRep:DACALGetIconImageForType( kDACALCarouselsFolderType )];			// Use the box icon		
		[[theChildNode nodeData] setItemType: kPADTypeIndexDevice];											// Set device type
		theBoxRef = (DACALDeviceRef)DACALCommandCopyUUID( theBoxNode, NULL );								// Save UUID
		[[theChildNode nodeData] setItemDevice:theBoxRef];

		//Create subtree root
		theSubtreeNode = [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData groupDataWithName:boxName] parent:nil children:[NSArray array]] autorelease];
		slotFolders = (NSArray*)DACALCommandCopyAllSlotPaths( theBoxRef, NULL );
		//		slotcount = DACALCommandGetSlotCount( theBoxRef );
		slotcount = [slotFolders count];
		for( slotindex = 1; slotindex <= slotcount; slotindex++ ) {	
			slotNum = CFURLGetSlotNumber( (CFURLRef)[slotFolders objectAtIndex:slotindex-1], FALSE );
			theSlotTitle = DACALSlotCopyTitle( theBoxRef, slotNum, NULL );
			if( theSlotTitle != NULL ) {																	// Create a url to the slot
				//theSlotName		= CFStringCreateWithFormat( NULL, NULL, CFSTR("Slot %i/%@"), slotNum, theSlotTitle );
				//slotURL = CFURLCreateCopyAppendingPathComponent( NULL, boxURL, (CFStringRef) theSlotName, TRUE );
				//slotURL = (CFURLRef)[slotFolders objectAtIndex:slotindex-1];
				slotURL = CFURLCreateCopyAppendingPathComponent( NULL, (CFURLRef)[slotFolders objectAtIndex:slotindex-1], (CFStringRef) theSlotTitle, TRUE );
				
				theSubtreeChild = [SimpleTreeNode treeOperationFromLocation:(NSURL*)slotURL];
				// [theSubtreeChild setDataDevice:theBoxRef slot:slotNum];
				compareIconType = [[theSubtreeChild nodeData] itemType];
				if		( compareIconType == kPADTypeDataMuisc ) slotIconType = 'cdda';				// CDAudioVolume
				else if	( compareIconType == kPADTypeDataMovie ) slotIconType = 'dvd ';				// public.dvd-media
				else											 slotIconType = kGenericCDROMIcon;  // public.cd-media
				[[theSubtreeChild nodeData] setIconRep:DACALGetIconImageForType(slotIconType)];
				
				[theSubtreeNode insertChild:theSubtreeChild atIndex:[theSubtreeNode numberOfChildren]];
				
				CFRelease( theSlotTitle );
				CFRelease( slotURL );
				//[theSLotName release];
			}
		}
		
		[theSubtreeNode recursiveSortChildren];						// Sort by slot!
		
		[[theChildNode nodeData] setSubTree:theSubtreeNode];

		[theWorkNode insertChild:theChildNode atIndex:index];
	}
*/	
//	#warning Index 2 should not be hard coded!	
//	[[[theOutputTree childAtIndex:2] nodeData] setItemType: kPADTypeGroupFavorites];
	[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_FAVORITES] nodeData] setItemType: kPADTypeGroupFavorites];
	
	[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] nodeData] setItemType:kPADTypeGroupLibrary];
	[[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_FILES] nodeData] setItemType:kPADTypeGroupLibrary]; //kPADTypeDataFiles];
	[[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_FILES] nodeData] setItemFlavor:PADINDEX_FLAVORVALUE_FILES];
	[[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_MUSIC] nodeData] setItemType:kPADTypeDataMuisc];
	[[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_MUSIC] nodeData] setItemFlavor:PADINDEX_FLAVORVALUE_MUSIC];
	[[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_MOVIE] nodeData] setItemType:kPADTypeDataMovie];
	[[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_MOVIE] nodeData] setItemFlavor:PADINDEX_FLAVORVALUE_MOVIE];
	
	[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_SEARHCES] nodeData] setItemType:kPADTypeGroupSearches];
	

/*
	theErr = FSFindFolder( kUserDomain, kDACALCarouselsFolderType, TRUE, &userLibraryFolder );
	if( theErr != 0 ) printf( "Could not find user library! Error:%i\n", theErr );
	else 
	{		
		CFURLRef	dataURL = CFURLCreateFromFSRef(NULL, &userLibraryFolder);
		int			index;
		CFShow( dataURL );
	
		theChildNode = [SimpleTreeNode treeFromLocation: (NSURL*)dataURL];	
		[theWorkNode insertChildren: [theChildNode children] atIndex: 0];
		
		for(index=0; index<[theWorkNode numberOfChildren]; index++)
			[[[theWorkNode childAtIndex:index] nodeData] setIsLeaf: YES];
	}
*/
	//count = DACALDevicesGetCount();
	//[self reportNoDevice:(count!=0) ? YES : NO]; 
	[self doReport];

	PADBOX_VALID_END
	
	return theOutputTree;
}

- (void)outlineViewInit
{
	[super outlineViewInit];
	[[self treeControl] setAllowOnDropOnLeaf:YES]; 
	
	[[[self treeControl] outlineView] expandItem:nil expandChildren:YES];
}

- (void)toolbarSearchStart:(id)sender
{
	[[[self treeControl] outlineView] deselectAll:self]; 
	[tabView selectTabViewItemWithIdentifier:@"Data"];
}

- (void)doReport
	{ [self reportNoDevice:(DACALDevicesGetCount()!=0) ? YES : NO]; }

- (void)doAction
	{ [self outlineViewAction:self]; }

- (void)reportNoDevice:(BOOL)hasBox
{
	[noBoxIcon setHidden:hasBox];
	[self updatePrompt];	
}

- (void)setPrompt:(NSString*)newPrompt
{
	if( newPrompt == nil ) newPrompt = @"";
	[promptText setStringValue: newPrompt];
}

- (void)updatePrompt
{
	NSString*	promptData;
	DACALSlotNum	count = DACALDevicesGetCount();
	
	if( [[[tabView selectedTabViewItem] identifier] compare:@"Home"] == NSOrderedSame )
	{
		if( count == 0) promptData = @"No carousels detected";
		else promptData = [NSString stringWithFormat:@"%i carousel%@ online", count, (count==1) ? @"" : @"s"];
	} else {
		NSArray *selectedNodes = [secondaryController selectedNodes];
		
		int			index = 0;
		int			count = [selectedNodes count];

		index = [[secondaryController outlineView] numberOfRows];
		
		if( count ) promptData = [NSString stringWithFormat:@"%i of %i selected", (int)count, (int)index];
		else		promptData = [NSString stringWithFormat:@"%i item%@", (int)index, ((index==1) ? @"" : @"s")];
	}
	   
	   [self setPrompt:promptData];
}
	   	   

- (void)outlineViewAction:(id)tree
{
	NSArray *selectedNodes = [treeControl selectedNodes];
//	NSMutableArray *selectedBoxes = [NSMutableArray arrayWithCapacity:0];
	SimpleNodeData *data;
	SimpleTreeNode *subTree;
	int		index;
//	NSURL*	theURL;
	DACALDeviceRef theDevice;
	DACALSlotNum	theSlot;
	PADIndexToolbarController* toolControl = (PADIndexToolbarController*)[self toolbarControl];
	
	if( [selectedNodes count] == 0 ) [tabView selectTabViewItemWithIdentifier:@"Home"];
	else  [tabView selectTabViewItemWithIdentifier:@"Data"];
	
	[secondaryController setTreeRoot:nil];
	//[secondaryController removeAllChildren];
	[toolControl resetSelection];
	
	for( index=0; index<[selectedNodes count]; index++ )
	{
		data = [[selectedNodes objectAtIndex:index] nodeData];
		subTree = [data subTree];
		if( subTree != nil)	[secondaryController addTreeRoot:subTree];
			//[secondaryController addDataToTree:subTree startEdit:NO];
		
		//if( [data location] != nil) 
		//{
			//if( index != 0 ) theURL = (NSURL*)CFURLCreateCopyDeletingLastPathComponent(NULL, (CFURLRef)[data location]);
			//else theURL = (NSURL*)[data location];
			//NSLog(@"The URL: %@\n", theURL );
			//theURL = (NSURL*)[data location];
			//[secondaryController addTreeRoot:  [SimpleTreeNode treeFromLocation: theURL]];
		//}
		
		theDevice = [data itemDevice];
		
		theSlot = [data itemSlot];
		if( theSlot != 0 )
			[toolControl addSelectedNode:[selectedNodes objectAtIndex:index]];
 		else if( theDevice != kDACALNullDevice )
			[toolControl addSelectedDevice:theDevice];
   }

	//if( toolControl ) [toolControl setSelectedDevices:(NSArray*)selectedBoxes];
	
	[secondaryController outlineViewAction:secondaryController];

	
//	[selectedBoxes release];	
	return;
}

- (void)nodeNameChanged:(SimpleTreeNode*)theNode toName:(NSString*)theName
{
	SimpleNodeData*		theData = [theNode nodeData];
	DACALDeviceRef		theDevice = [theData itemDevice];
	NSInteger			theType = [theData itemType];

	[theData setName:theName];
	
	if( (theType == kPADTypeIndexDevice) & (theDevice != kDACALNullDevice) )
		DACALCommandSetName( theDevice, (CFStringRef)theName );
	return;
}

- (NSInteger)shouldEditTableColumn:(NSTableColumn *)tc item:(id)item
{
	if( [[item nodeData] itemType] == kPADTypeIndexDevice ) return YES;
	if( [[[item nodeParent] nodeData] itemType] == kPADTypeGroupFavorites ) return YES;

	return NO;
}

- (void)dropNodesOntoLibraryGroup:(id <NSDraggingInfo>)info onNode:(TreeNode *)parentNode atIndex:(NSInteger)childIndex 
{
    NSPasteboard*	pboard = [info draggingPasteboard];	
	NSString*		destinationFlavor = [[parentNode nodeData] itemFlavor];
    
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:DragDropSimplePboardType, nil]] != nil) {
        TreeController *dragDataSource = [[info draggingSource] dataSource];
        NSArray *_draggedNodes = [dragDataSource draggedNodes];
        NSEnumerator *draggedNodesEnum = [_draggedNodes objectEnumerator];
        SimpleTreeNode *_draggedNode = nil;
//		SimpleTreeNode *_bioParent = nil;
//		int				itemRow = 0;
        
        while ((_draggedNode = [draggedNodesEnum nextObject])) {
			
			if( [dragDataSource dataSource] != nil )
				[[dragDataSource dataSource] performSelector:@selector(nodeTypeChanged:toType:)
												  withObject:(SimpleTreeNode*)_draggedNode
												  withObject:destinationFlavor];
			
			[[dragDataSource outlineView] reloadItem:_draggedNode];
		}
		[[dragDataSource outlineView] reloadData];
	}
}

- (void)dropNodesOntoFavoritesGroup:(id <NSDraggingInfo>)info onNode:(TreeNode *)parentNode atIndex:(NSInteger)childIndex 
{
    NSPasteboard*	pboard = [info draggingPasteboard];	
	SimpleTreeNode*	newMark = nil;
	SimpleTreeNode* newMarkTree = nil;
    
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:DragDropSimplePboardType, nil]] != nil) {
        TreeController *dragDataSource = [[info draggingSource] dataSource];
        NSArray *_draggedNodes = [dragDataSource draggedNodes];
        NSEnumerator *draggedNodesEnum = [_draggedNodes objectEnumerator];
        SimpleTreeNode *_draggedNode = nil;
		BOOL	sourceWasUs = [[self treeControl] isEqual:dragDataSource];
       
        while ((_draggedNode = [draggedNodesEnum nextObject])) 
		{
			if( !sourceWasUs ) {
				newMark = (SimpleTreeNode*)[SimpleTreeNode nodeDataWithURL:(NSURL*)[(SimpleNodeData*)[_draggedNode nodeData] location]];
				newMarkTree = (SimpleTreeNode*)[SimpleTreeNode treeOperationFromLocation:(NSURL*)[(SimpleNodeData*)[_draggedNode nodeData] location] forUI:YES];
				[[newMark nodeData] setSubTree:newMarkTree];
				[[newMark nodeData] setIsLeaf:YES];
				[parentNode insertChild:newMark atIndex:childIndex];
			} else {
				newMark = _draggedNode;
				[parentNode removeChild:newMark];
				if( childIndex > [parentNode numberOfChildren] ) childIndex--;
				[parentNode insertChild:newMark atIndex:childIndex];
			}
		}
		[[treeControl outlineView] reloadItem:parentNode reloadChildren:YES];
	}
}

- (NSDragOperation)validateDropSource:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex
{
	BOOL	fromThisView = [[[info draggingSource] dataSource] isEqual:treeControl];
	
	if( [[item nodeData] itemType] == kPADTypeGroupFavorites ) {
		if( fromThisView ) return NSDragOperationMove;
		else return NSDragOperationCopy;
	}
	else if( [[[item nodeParent] nodeData] itemType] == kPADTypeGroupLibrary ) {
		NSArray *_draggedNodes = [[[info draggingSource] dataSource] draggedNodes];
		int		nodeIndex, nodeCount = [_draggedNodes count];
		
		for(nodeIndex=0; nodeIndex<nodeCount; nodeIndex++)
			if( [[[[_draggedNodes objectAtIndex:nodeIndex] nodeData] itemFlavor] compare:[[item nodeData] itemFlavor]] != NSOrderedSame )
				return NSDragOperationLink;
	}

	if( fromThisView )
	   return [super validateDropSource:info proposedItem:item proposedChildIndex:childIndex];
	
	return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex {
	
    SimpleTreeNode *node = item;
    SimpleNodeData *data = [node nodeData];
    
    if ([data isLeaf]) {
		if( [[[node nodeParent] nodeData] itemType] == kPADTypeGroupLibrary )
		{
		    [self dropNodesOntoLibraryGroup:info onNode:node atIndex:childIndex];	
			return YES;
		}
	} 
	
	if( [[node nodeData] itemType] == kPADTypeGroupFavorites )
	{
		[self dropNodesOntoFavoritesGroup:info onNode:node atIndex:childIndex];	
		return YES;
	}
	
	return [super outlineView:ov acceptDrop:info item:item childIndex:childIndex];
}

- (SimpleTreeNode*)findTreeNodeForDevice:(DACALDeviceRef)theBoxRef
	{ return [[[[self treeControl] treeRoot] childWithItemType:kPADTypeGroupDevices] childWithDevice:theBoxRef]; }


- (void)slotAddedToDevice:(DACALDeviceRef)theBoxRef forSlot:(DACALSlotNum)newSlot
{
	NSURL*				theSlotPath = (NSURL*)DACALSlotCopyPath( theBoxRef, newSlot, NULL );
	NSString*			theSlotTitle = (NSString*)DACALSlotCopyTitle( theBoxRef, newSlot, NULL );
	NSURL*				theSlotContentPath = (NSURL*)CFURLCreateCopyAppendingPathComponent( NULL, (CFURLRef)theSlotPath, (CFStringRef)theSlotTitle, TRUE );
	SimpleTreeNode*		theSubtreeNode = nil;
//	SimpleTreeNode*		theOthertTreeNode = [[secondaryController treeControl] treeRoot];
	SimpleTreeNode*		theBoxTreeNode = [[[self findTreeNodeForDevice:theBoxRef] nodeData] subTree];
	SimpleTreeNode*		theSubtreeChild = nil;
//	OSType				slotIconType = kGenericCDROMIcon;
//	OSType				compareIconType = 0;
	
	// Find box
	
	// theSubtreeNode = [[[self findTreeNodeForDevice:theBoxRef] nodeData] subTree];
	theSubtreeNode = [secondaryController treeRoot];
	
	if( theSlotContentPath != nil )
	{
		// Transfer kind xattr to top
		CFURLSetItemFlavor( (CFURLRef)theSlotContentPath, CFURLCopyItemFlavor( (CFURLRef)theSlotPath, NULL) );
		
		theSubtreeChild = [SimpleTreeNode treeOperationFromLocation:(NSURL*)theSlotContentPath forUI:YES];
//		theSubtreeChild = [SimpleTreeNode treeFromLocation:(NSURL*)theSlotContentPath];
		
		[(SimpleNodeData*)[theSubtreeChild nodeData] setName: theSlotTitle];
		[(SimpleNodeData*)[theSubtreeChild nodeData] setItemSlot: newSlot];
		[(SimpleNodeData*)[theSubtreeChild nodeData] setItemDevice: theBoxRef];
		//[[theSubtreeChild nodeData] setLocation:theSlotContentPath];

		//compareIconType = [[theSubtreeChild nodeData] itemType];
		//if		( compareIconType == kPADTypeDataMuisc ) slotIconType = 'cdda';				// CDAudioVolume
		//else if	( compareIconType == kPADTypeDataMovie ) slotIconType = 'dvd ';				// public.dvd-media
		//else											 slotIconType = kGenericCDROMIcon;  // public.cd-media
		//[[theSubtreeChild nodeData] setIconRep:DACALGetIconImageForType(slotIconType)];
		

		

		[theBoxTreeNode insertChild:theSubtreeChild atIndex:[theBoxTreeNode numberOfChildren]];
		//[[theBoxTreeNode nodeParent] sortExpandedChildrenForView:[secondaryController outlineView]];
		
		//[theSubtreeChild setBusy:YES];		

		//[theBoxTreeNode recursiveSortChildren];
		
		//[secondaryController addDataToTree:theSubtreeChild startEdit:NO];

		//		[theSubtreeNode insertChild:theSubtreeChild atIndex:[theSubtreeNode numberOfChildren]];
		//[theOthertTreeNode insertChild:theSubtreeChild atIndex:[theOthertTreeNode numberOfChildren]];

		//CFRelease( theSlotContentPath );
		//CFRelease( theSlotTitle );
		//CFRelease( theSlotPath );
	}
	
	[self doAction];
	
	//[self outlineViewAction:[[self treeControl] outlineView]];
	//[[secondaryController treeControl] reloadData];
}

- (void)doubleClickImage:(id)item
{
	SimpleNodeData	*theData = [item nodeData];
	DACALDeviceRef	theBox = [theData itemDevice];
	DACALSlotNum	theSlot = [theData itemSlot];
	
	if( theBox && theSlot )
		DACALCommandMoveToSlotWithOptions( theBox, theSlot, kDACALOptionMoveToggle );
}


+ (id)shared;
{
    if (!DACALTreeDataSource_shared) {
        [[DACALTreeDataSource alloc] init];
    }
    return DACALTreeDataSource_shared;
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[NSApplication sharedApplication] terminate:self];
}


@end	// DACALTreeDataSource


@implementation DACALViewDataSource

- (void)awakeFromNib 
{
	if( !PADBOX_VALIDATED ) [[[treeControl outlineView] window] orderOut:self];
	
	[[AppController shared] setDataView: treeControl];

	NSTableColumn*		nameCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_NAME];
	NSTableColumn*		slotCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_SLOT];
	NSTableColumn*		aDayCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_MODDATE];
	NSTableColumn*		flavCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_TYPE];
	
	NSSortDescriptor*	nameSort = [[[NSSortDescriptor alloc] initWithKey:@"keyName" ascending:YES selector:@selector(compareDataNames:)] autorelease];
	NSSortDescriptor*	slotSort = [[[NSSortDescriptor alloc] initWithKey:@"keySlotNumber" ascending:YES selector:@selector(compareDataSlots:)] autorelease];
	NSSortDescriptor*	aDaySort = [[[NSSortDescriptor alloc] initWithKey:@"keyAddDate" ascending:YES selector:@selector(compareDataAddDates:)] autorelease];
	NSSortDescriptor*	flavSort = [[[NSSortDescriptor alloc] initWithKey:@"keyFlavor" ascending:YES selector:@selector(compareDataFlavors:)] autorelease];
	
	NSArray*			startOrder = [NSArray arrayWithObjects:slotSort, nameSort, flavSort, aDaySort, nil];
	
	[nameCol setSortDescriptorPrototype:nameSort];
	[slotCol setSortDescriptorPrototype:slotSort];
	[aDayCol setSortDescriptorPrototype:aDaySort];
	[flavCol setSortDescriptorPrototype:flavSort];
	
	[[treeControl outlineView] setSortDescriptors:startOrder];
}

- (SimpleTreeNode*)createInitialTree:(id)tree
{
	SimpleTreeNode*		theOutputTree = nil;	
	return theOutputTree;
}

- (void)updatePrompt
	{ [[DACALTreeDataSource shared] doReport]; }

- (void)outlineViewAction:(id)tree
{
	NSArray *selectedNodes = [treeControl selectedNodes];
//	NSMutableArray *selectedSlots = [NSMutableArray arrayWithCapacity:0];
	SimpleNodeData *data;
	int		index = 0;
	int		count = [selectedNodes count];

	//	NSURL*	theURL;
	DACALSlotNum theSlot;
	PADIndexToolbarController* toolControl = (PADIndexToolbarController*)[self toolbarControl];
//	NSNumber*	slotNumber;
	
	//[toolControl setSelectedNode:nil];
	
	for( index=0; index<count; index++ )
	{
		data = [[selectedNodes objectAtIndex:index] nodeData];
		theSlot = [data itemSlot];
		if( theSlot != 0 ) {
			[toolControl addSelectedNode:[selectedNodes objectAtIndex:index]];
			//slotNumber = [NSNumber numberWithInteger:(NSInteger)theSlot];
			//if( ![selectedSlots containsObject:slotNumber] )
			//	[selectedSlots addObject:slotNumber];
		}
    }
	//if( toolControl ) {
	//	[toolControl setSelectedSlots:(NSArray*)selectedSlots];
	//	[toolControl setSelectedNodes:selectedNodes];
	//}

	[self updatePrompt];

	return;
}

- (void)nodeNameChanged:(SimpleTreeNode*)theNode toName:(NSString*)theName
{
	SimpleNodeData	*theData = [theNode nodeData];
	DACALDeviceRef	theBox = [theData itemDevice];
	DACALSlotNum	theSlot = [theData itemSlot];
//	CFURLRef		theURL = [theData location];
	DACALResult		theErr;

	if( [[theData name] compare:theName] == NSOrderedSame ) return;
	
	// This should not be possible since we checked already before we allowed editing.
	// if( (theURL == NULL) || (CFURLIsSlot(theURL) != TRUE) ) return;
	
	theErr = DACALSlotSetTitle( theBox, theSlot, (CFStringRef)theName );
	if( theErr != 0 ) goto SLOTNAMEFAILED;

	[theData setName:theName];

	//if( [theNode nodeParent] ) [[theNode nodeParent] sortExpandedChildrenUsingDescriptors:[[[self treeControl] outlineView] sortDescriptors ]];
	[self sortExpandedChildrenWithCurrentDescriptors:(SimpleTreeNode*)[theNode nodeParent]];
	
	
	[AppController playUISound: kASSystemSoundSuccess];
	return;
	
SLOTNAMEFAILED:
	
	[AppController playUISound: kASSystemSoundDoink];
	return;
}

- (void)nodeSlotChanged:(SimpleTreeNode*)node toSlot:(NSString*)slotString
{
	DACALSlotNum	oldSlot = [[node nodeData] itemSlot];
	DACALSlotNum	newSlot = [slotString intValue];
	
	if( oldSlot == newSlot ) return;
	
	NSString*		theString = nil;

	theString = [NSString stringWithFormat:@"Change from slot %i to slot %i.", oldSlot, newSlot];

	NSLog( theString );
	CFStringSpeak( (CFStringRef)theString, FALSE, NULL );
}

- (void)nodeTypeChanged:(SimpleTreeNode*)theNode toType:(NSString*)theName
{
	SimpleNodeData	*theData = [theNode nodeData];
	CFURLRef		theURL = (CFURLRef)[theData location];
	
//	CFURLRef		testURL = (CFURLRef)[(SimpleNodeData*)[theNode nodeData] location];
	DACALResult		theErr;
	
//	CFShow(testURL);
//	theURL = testURL;
	
	if( [[theData itemFlavor] compare:theName] == NSOrderedSame ) return;
		
	theErr = CFURLSetXattr( theURL, kDACALCarouselDocumentXAttrSlotKind, (CFStringRef)theName );
	if( theErr != 0 ) goto SLOTTYPEFAILED;
	
	[theData setItemFlavor:theName];
	[theData setIconRep:CFURLGetIconAsNSImage( NULL, (CFURLRef)theURL, NULL)];
	
	//if( [theNode nodeParent] ) [[theNode nodeParent] sortExpandedChildrenUsingDescriptors:[[[self treeControl] outlineView] sortDescriptors ]]; 
	[self sortExpandedChildrenWithCurrentDescriptors:(SimpleTreeNode*)[theNode nodeParent]];
	
	[AppController playUISound: kASSystemSoundSuccess];
	return;
	
SLOTTYPEFAILED:
	if( theErr != 0 ) NSLog(@"Error:%i Setting to:%@ for URL:%@", (int)theErr, theName, (NSURL*)theURL);
	[AppController playUISound: kASSystemSoundDoink];
	return;
}

- (NSInteger)shouldEditTableColumn:(NSTableColumn *)tc item:(id)item
{
	SimpleNodeData	*theData = [item nodeData];
	CFURLRef		theURL = NULL;
	
	if([[tc identifier] compare:COLUMNID_SLOT] == NSOrderedSame) 
		return NO;	// Currently unimplemented
	
	if([[tc identifier] compare:COLUMNID_NAME] == NSOrderedSame) {
		theURL = (CFURLRef)[theData location];
		if( theURL == NULL ) return NO;
		if( CFURLIsTopInSlot(kCFAllocatorDefault, theURL) == TRUE ) return YES;
		return NO;
	}
	
	return NO;
}

- (void)doubleClickImage:(id)item
{
	SimpleNodeData	*theData = [item nodeData];
	DACALDeviceRef	theBox = [theData itemDevice];
	DACALSlotNum	theSlot = [theData itemSlot];

	DACALCommandMoveToSlotWithOptions( theBox, theSlot, kDACALOptionMoveToggle );
}

- (void)doubleClickCellContent:(id)item
{
	SimpleNodeData	*theData = [item nodeData];
	NSOutlineView	*theView = [[self treeControl] outlineView];
	
	if([theData isExpandable] == YES ) 
		if( [theView isItemExpanded:item] == YES ) {
			[theView collapseItem:item];
		} else {
			[theView expandItem:item];
		}
}

@end	// DACALViewDataSource

