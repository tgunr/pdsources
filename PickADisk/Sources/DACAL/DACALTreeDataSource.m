//
//  DACALTreeDataSource.m
//  DragNDropOutlineView
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import "DACALTreeDataSource.h"
#import "DACALViewDataSource.h"
#import <DACAL/dacalconstants.h>
#import "PADLifecycleSetup.h"
#import "PADSearchRequest.h"
#import "DACALDeviceService.h"
#import "PADIndexNodeData.h"
#import "DACALSlotElementBookmark.h"
#import "PADIndexToolbarController.h"
#import "PADOutlineView.h"
#import "DACALDevice.h"
#import "DACALIndexState.h"
#import "DACALSlotElement.h"
#import <PMUtility/PMUtility.h>
#import "TreeController.h"

NSString*	DACALFlavorToFlavorValue( NSString* flavor )
{
	NSString*	theFlavorValue = nil;
	
	if( flavor ) {
		if(	[flavor isEqual:PADINDEX_FLAVORVALUE_FILES] ||
		   [flavor isEqual:PADINDEX_FLAVORTITLE_FILES] )
			theFlavorValue = PADINDEX_FLAVORVALUE_FILES;
        else if( [flavor isEqual:PADINDEX_FLAVORVALUE_IMAGE] ||
                [flavor isEqual:PADINDEX_FLAVORTITLE_IMAGE] )
            theFlavorValue = PADINDEX_FLAVORVALUE_IMAGE;
        else if( [flavor isEqual:PADINDEX_FLAVORVALUE_MOVIE] ||
                [flavor isEqual:PADINDEX_FLAVORTITLE_MOVIE] )
            theFlavorValue = PADINDEX_FLAVORVALUE_MOVIE;
        else if( [flavor isEqual:PADINDEX_FLAVORVALUE_MUSIC] ||
                [flavor isEqual:PADINDEX_FLAVORTITLE_MUSIC] )
            theFlavorValue = PADINDEX_FLAVORVALUE_MUSIC;
        else if( [flavor isEqual:@"data"] )
            theFlavorValue = PADINDEX_FLAVORVALUE_FILES;
    }
	return theFlavorValue;
}

NSString*	DACALFlavorToFlavorTitle( NSString* flavor )
{
	NSString*	theFlavorTitle = nil;
	
	if( flavor ) {
		if(	[flavor isEqual:PADINDEX_FLAVORVALUE_FILES] ||
		   [flavor isEqual:PADINDEX_FLAVORTITLE_FILES] )
			theFlavorTitle = PADINDEX_FLAVORTITLE_FILES;
		else if( [flavor isEqual:PADINDEX_FLAVORVALUE_IMAGE] ||
				[flavor isEqual:PADINDEX_FLAVORTITLE_IMAGE] )
			theFlavorTitle = PADINDEX_FLAVORTITLE_IMAGE;
		else if( [flavor isEqual:PADINDEX_FLAVORVALUE_MOVIE] ||
				[flavor isEqual:PADINDEX_FLAVORTITLE_MOVIE] )
			theFlavorTitle = PADINDEX_FLAVORTITLE_MOVIE;
		else if( [flavor isEqual:PADINDEX_FLAVORVALUE_MUSIC] ||
				[flavor isEqual:PADINDEX_FLAVORTITLE_MUSIC] )
			theFlavorTitle = PADINDEX_FLAVORTITLE_MUSIC;
		else if( [flavor isEqual:@"data"] )
			theFlavorTitle = PADINDEX_FLAVORTITLE_FILES;
	}
	return theFlavorTitle;
}

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

-(TreeController  *)secondaryController {
    return secondaryController;
}

-(void)orderForUser:(SimpleTreeNode*)treeNode
{
	NSDictionary*		orderDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"PADMainSidebarOrder"];
	NSDictionary*		visibleDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"PADPrefsTreeIndexAvailability"];
	
	if( orderDict == nil )
		return;
	
	NSArray*			orderGroupNames = [orderDict allKeys];
	NSInteger			groupIndex, groupCount = [orderGroupNames count];
	SimpleTreeNode*		workGroupNode = nil;
	NSDictionary*		groupDict = nil;
	NSDictionary*		childDict = nil;
	NSArray*			childNames = nil;
	NSArray*			orderNames = nil;
	
	if( treeNode == nil )
		treeNode = [[self treeControl] treeRoot];
	
	for( groupIndex=0; groupIndex < groupCount; groupIndex++ )
	{
		workGroupNode = [treeNode childWithName:[orderGroupNames objectAtIndex:groupIndex]];
		if( workGroupNode == nil ) continue;
		childDict = [orderDict objectForKey:[[workGroupNode nodeData] name]];
		childNames = [childDict objectForKey:@"Names"];
		groupDict = [visibleDict objectForKey:[[workGroupNode nodeData] name]];
		
		if( visibleDict != nil )
		{
			NSMutableArray*		visibleNames = [NSMutableArray arrayWithCapacity:0];
			NSEnumerator*		addEnum = [groupDict keyEnumerator];
			NSEnumerator*		removeEnum = [groupDict keyEnumerator];
			NSString*			itemNode = nil;
			NSNumber*			itemVisible = nil;
			
			if( childNames != nil )
				[visibleNames addObjectsFromArray:childNames];
			
			while ( itemNode = [addEnum nextObject] )
			{
				itemVisible = [groupDict objectForKey:itemNode];
				if( itemVisible && ([itemVisible boolValue] == YES) )
					if( ![visibleNames containsObject:itemNode] )
						[visibleNames addObject:itemNode];
			}
			
			while( itemNode = [removeEnum nextObject] )
			{
				itemVisible = [groupDict objectForKey:itemNode];
				if( itemVisible && ([itemVisible boolValue] == NO) )
					[visibleNames removeObject:itemNode];
			}
			
			orderNames = visibleNames;
		} else
			orderNames = childNames;
		
		[workGroupNode orderChildrenByName:orderNames removeMissing:YES];
		[[workGroupNode nodeData] setExpanded:CFBooleanToBOOL( (CFBooleanRef)[childDict objectForKey:@"Expanded"] )];
		
		if( [workGroupNode numberOfChildren] == 0 ) {
			if( [[workGroupNode nodeData] itemType] == kPADTypeGroupLibrary )
				[workGroupNode removeFromParent];
			else if( [[workGroupNode nodeData] itemType] == kPADTypeGroupSearches )
				[workGroupNode removeFromParent];
			else if( [[workGroupNode nodeData] itemType] == kPADTypeGroupDevices )
			{
				NSEnumerator*	deviceEnum = [[[DACALDeviceService sharedService] deviceList] objectEnumerator];
				DACALDevice*	aDevice = nil;
				
				while ( aDevice = [deviceEnum nextObject] )
					[workGroupNode insertChild:[aDevice deviceNode] atIndex:[workGroupNode numberOfChildren]];
			}
		}
	}
	
	[treeNode orderChildrenByName:[orderDict objectForKey:@"Groups"] removeMissing:NO];
}

-(void)saveUserOrder
{
	NSMutableDictionary*	groupList = [NSMutableDictionary dictionaryWithCapacity:0];
	SimpleTreeNode*			treeNode = [[self treeControl] treeRoot];
	SimpleTreeNode*			groupNode = nil;
    //	SimpleTreeNode*			childNode = nil;
	NSInteger				groupIndex, groupCount = [treeNode numberOfChildren];
	NSInteger				childIndex, childCount;
	NSMutableDictionary*	childDict = nil;
	NSMutableArray*			childNames = nil;
	NSMutableArray*			groupNames = [NSMutableArray arrayWithCapacity:groupCount];
	
	for( groupIndex=0; groupIndex < groupCount; groupIndex++ )
	{
		groupNode = (SimpleTreeNode*)[treeNode childAtIndex:groupIndex];
		childCount = [groupNode numberOfChildren];
		childDict = [NSMutableDictionary dictionaryWithCapacity:2];
		childNames = [NSMutableArray arrayWithCapacity:childCount];
		for( childIndex=0; childIndex < childCount; childIndex++ )
			[childNames addObject:[[[groupNode childAtIndex:childIndex] nodeData] name]];
		
		[childDict setObject:[NSArray arrayWithArray:childNames] forKey:@"Names"];
		[childDict setObject:(id)BOOLToCFBoolean([[groupNode nodeData] isExpanded]) forKey:@"Expanded"];
		
		[groupNames addObject:[[groupNode nodeData] name]];
		[groupList setObject:[NSDictionary dictionaryWithDictionary:childDict] forKey:[[groupNode nodeData] name]];
	}
	
	[groupList setObject:groupNames forKey:@"Groups"];
	
	//NSLog(@"Group List: %@", groupList);
	
	[[NSUserDefaults standardUserDefaults] setObject:groupList forKey:@"PADMainSidebarOrder"];
}

- (SimpleTreeNode*)createInitialTree:(id)tree
{
	SimpleTreeNode*		theOutputTree = nil;
	SimpleTreeNode*		theWorkNode = nil;
	SimpleTreeNode*		theGroupNode = nil;
	IndexNodeData*		theWorkData = nil;
	
	[tree setAllowGroupRowLook:YES];
	[tree setAllowBetweenDrop:YES];
    
	PADBOX_VALID_BEGIN
    
	// Load our initial outline view data from the "InitInfo" dictionary.
	NSDictionary *initData = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"InitInfo" ofType: @"dict"]];
	if( initData != nil ) theOutputTree = [SimpleTreeNode treeIndexFromDictionary: initData];
	
	[[theOutputTree nodeData] setExpanded:YES];
	
	theWorkNode = (SimpleTreeNode*)[theOutputTree childWithName:PADINDEX_GROUPTITLE_DEVICES];
	[[theWorkNode nodeData] setItemType: kPADTypeGroupDevices];
    
	[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_FAVORITES] nodeData] setItemType: kPADTypeGroupFavorites];
	[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] nodeData] setItemType:kPADTypeGroupLibrary];
	
	[[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_FILES] nodeData] setItemType:kPADTypeGroupLibrary]; //kPADTypeDataFiles];
	theWorkData = (IndexNodeData*)[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_FILES] nodeData];
	[theWorkData setItemFlavor:PADINDEX_FLAVORVALUE_FILES];
	[theWorkData setItemType:kPADTypeDataFiles];
	//[(IndexNodeData*)theWorkData setItemSearch:[PADSearchRequest searchCarouselsForKind:(NSString*)PADINDEX_FLAVORVALUE_FILES resultType:kPADSearchOptionResultTypeItem]];
	
	theWorkData = (IndexNodeData*)[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_IMAGE] nodeData];
	[theWorkData setItemType:kPADTypeDataImage];
	[theWorkData setItemFlavor:PADINDEX_FLAVORVALUE_IMAGE];
    
	theWorkData = (IndexNodeData*)[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_MUSIC] nodeData];
	[theWorkData setItemType:kPADTypeDataMuisc];
	[theWorkData setItemFlavor:PADINDEX_FLAVORVALUE_MUSIC];
	//[(IndexNodeData*)theWorkData setItemSearch:[PADSearchRequest searchCarouselsForKind:(NSString*)PADINDEX_FLAVORTITLE_MUSIC resultType:kPADSearchOptionResultTypeItem]];
	
	theWorkData = (IndexNodeData*)[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_MOVIE] nodeData];
	[theWorkData setItemType:kPADTypeDataMovie];
	[theWorkData setItemFlavor:PADINDEX_FLAVORVALUE_MOVIE];
	//[(IndexNodeData*)theWorkData setItemSearch:[PADSearchRequest searchCarouselsForKind:(NSString*)PADINDEX_FLAVORTITLE_MOVIE resultType:kPADSearchOptionResultTypeItem]];
	
	theGroupNode = [theOutputTree childWithName:PADINDEX_GROUPTITLE_SEARHCES];
	[[theGroupNode nodeData] setItemType:kPADTypeGroupSearches];
	theWorkNode = [theGroupNode childWithName:@"Today"];
	theWorkData = [theWorkNode nodeData];
	[theWorkData setItemSearch:[PADSearchRequest searchCarouselsForCheckedOutBeforeDays:1 ofDate:nil resultType:kPADSearchOptionResultTypeItem]];
	
	theWorkNode = [theGroupNode childWithName:@"Yesterday"];
	theWorkData = [theWorkNode nodeData];
	[theWorkData setItemSearch:[PADSearchRequest searchCarouselsForCheckedOutBeforeDays:1 ofDate:@"Yesterday" resultType:kPADSearchOptionResultTypeItem]];
	
	theWorkNode = [theGroupNode childWithName:@"Past Week"];
	theWorkData = [theWorkNode nodeData];
	[theWorkData setItemSearch:[PADSearchRequest searchCarouselsForCheckedOutBeforeDays:7 ofDate:nil resultType:kPADSearchOptionResultTypeItem]];
	
	theWorkNode = [theGroupNode childWithName:@"Past Month"];
	theWorkData = [theWorkNode nodeData];
	[theWorkData setItemSearch:[PADSearchRequest searchCarouselsForCheckedOutBeforeDays:30 ofDate:nil resultType:kPADSearchOptionResultTypeItem]];
	
	theWorkNode = [theGroupNode childWithName:@"My Favorites"];
	theWorkData = [theWorkNode nodeData];
	[theWorkData setItemSearch:[PADSearchRequest searchCarouselsForStars:@"5" resultType:kPADSearchOptionResultTypeItem]];
	
	theWorkNode = [theGroupNode childWithName:@"All Images"];
	theWorkData = [theWorkNode nodeData];
	[theWorkData setItemSearch:[PADSearchRequest searchCarouselsForFileUTI:(NSString*)kUTTypeImage resultType:kPADSearchOptionResultTypeItem]];
    
	theWorkNode = [theGroupNode childWithName:@"All Music"];
	theWorkData = [theWorkNode nodeData];
	[theWorkData setItemSearch:[PADSearchRequest searchCarouselsForFileUTI:(NSString*)kUTTypeAudio resultType:kPADSearchOptionResultTypeItem]];
    
	theWorkNode = [theGroupNode childWithName:@"All Movies"];
	theWorkData = [theWorkNode nodeData];
	[theWorkData setItemSearch:[PADSearchRequest searchCarouselsForFileUTI:(NSString*)kUTTypeMovie resultType:kPADSearchOptionResultTypeItem]];
    
	theWorkNode = [theGroupNode childWithName:@"All Documents"];
	theWorkData = [theWorkNode nodeData];
	[theWorkData setItemSearch:[PADSearchRequest searchCarouselsForFileUTI:(NSString*)kUTTypeContent resultType:kPADSearchOptionResultTypeItem]];
    
	[self orderForUser:theOutputTree];
	
	[self doReport];
    
	PADBOX_VALID_END
	
	return theOutputTree;
}

- (void)outlineViewInit
{
	[super outlineViewInit];
	[[self treeControl] setAllowOnDropOnLeaf:YES];
	//[[self treeControl] setAllowOnDropOnGroup:YES];
	
	[[self outlineView] expandItem:nil expandChildren:YES];
	if( [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"PADMainSidebarOrder"] == nil )
		[self saveUserOrder];
}

- (void)reinitOutlineView
{
	//[[self outlineView] autoExpandItemAndChildren:nil];
	[[self outlineView] expandItem:nil expandChildren:YES];
    
}

- (void)recreateInitialTree
{
	[super recreateInitialTree];
    
	if( [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"PADMainSidebarOrder"] == nil )
	{
		SimpleTreeNode*	workGroupNode = [[[self treeControl] treeRoot] childWithItemType:kPADTypeGroupDevices];
		NSEnumerator*	deviceEnum = [[[DACALDeviceService sharedService] deviceList] objectEnumerator];
		DACALDevice*	aDevice = nil;
		
		if( workGroupNode && ([workGroupNode numberOfChildren] == 0) )
		{
			while ( aDevice = [deviceEnum nextObject] )
				[workGroupNode insertChild:[aDevice deviceNode] atIndex:[workGroupNode numberOfChildren]];
            
			[[self outlineView] reloadItem:workGroupNode reloadChildren:YES];
		}
	}
}

- (void)toolbarSearchStart:(id)sender
{
	if( !savedSelection ) {
		savedSelection = [DACALIndexState saveSetupForKey:@"DataView" saveView:[secondaryController outlineView] saveSelection:YES saveSorts:YES];
		[savedSelection addSettingsForKey:@"DataIndex" saveView:[[self treeControl] outlineView] saveSelection:YES saveSorts:NO];
	}
	
	[[[self treeControl] outlineView] deselectAll:self];
	
	[[[secondaryController outlineView] tableColumnWithIdentifier:COLUMNID_SCORE] setHidden:NO];
	[tabView selectTabViewItemWithIdentifier:@"Data"];
    
	if( sortedSelection ) {
		[sortedSelection restoreSettings];
		[sortedSelection release];
		sortedSelection = nil;
	}
}

-(void)toolbarSearchFinish:(id)sender
{
	if( !sortedSelection ) {
		sortedSelection = [DACALIndexState saveSetupForKey:@"SortData" saveView:[secondaryController outlineView] saveSelection:YES saveSorts:YES];
		[savedSelection addSettingsForKey:@"SortIndex" saveView:[[self treeControl] outlineView] saveSelection:YES saveSorts:NO];
	}
	
	[[secondaryController outlineView] deselectAll:self];
	[[[secondaryController outlineView] tableColumnWithIdentifier:COLUMNID_SCORE] setHidden:YES];
    
	
	if( savedSelection ) {
		if( sender == [self treeControl] )										// if the view control did the action
			[savedSelection removeSetting:@"Selection" forKey:@"DataIndex"];	// don't reset the selection.
		[savedSelection restoreSettings];
		[savedSelection release];
		savedSelection = nil;
	}
	
	if( sender != self ) [self outlineViewAction:self];
}

- (void)doReport
{ [self reportNoDevice:(DACALDevicesGetCount()!=0) ? YES : NO]; }

- (void)doAction
{ [self outlineViewAction:self]; }

- (void)reportNoDevice:(BOOL)hasBox
{
	[noBoxIcon setImage:[NSImage imageNamed:@"noBox.png"]];
	[noBoxIcon setHidden:hasBox];
	[self updatePrompt];
}

- (void)reportGoodRegistration
{
	NSImage*	bigPic = [NSImage imageNamed:@"success.icns"];
	
	[bigPic setSize:NSSizeFromString(@"16,16")];
	[noBoxIcon setImage:bigPic];
	[noBoxIcon setHidden:FALSE];
	[self updatePrompt];
	[promptText setStringValue: NSLocalizedString(@"Thank you for registering PickADisk!", @"Prompt text for data window when a valid license is entered")];
}

- (void)setPrompt:(NSString*)newPrompt
{
	if( newPrompt == nil ) newPrompt = @"";
	[promptText setStringValue: newPrompt];
}

- (void)updatePrompt
{
	NSString*		promptData;
	DACALSlotNum	count = DACALDevicesGetCount();
	NSString*		carouselString;
	NSString*		itemString;
	NSString*		slotString;
	DACALDevice*	sizeDevice = nil;
	NSString*		sizeString = @"";
	NSInteger		usedCount = 0;
	BOOL			canAdd = [[DACALDeviceService sharedService] countUsedSlots:&usedCount];
	
	if( count == 1 ) {
		carouselString = NSLocalizedString(@"carousel", @"Data View Prompt Singular form of carousel device");
		itemString = NSLocalizedString(@"item", @"Data View Prompt Singular form of data view element");
	} else {
		carouselString = NSLocalizedString(@"carousels", @"Data View Prompt Plural form of carousel devices");
		itemString = NSLocalizedString(@"items", @"DataView Prompt Plural form of data view elements");
	}
	
	if( usedCount == 1 )
		slotString = NSLocalizedString(@"slot", @"Data View Prompt Singular form of carousel device slot");
	else
		slotString = NSLocalizedString(@"slots", @"Data View Prompt Plural form of carousel device slots");
	
    NSString *identifier = [[tabView selectedTabViewItem] identifier];
	if( [identifier compare:@"Home"] == NSOrderedSame )
	{
		if( count == 0)
            promptData = NSLocalizedString(@"No carousels detected", @"Data View Prompt when no carousel devices are currently detected");
		else
            promptData = [NSString stringWithFormat:NSLocalizedString(@"%i %@ using %i %@ storing %@", @"Data View Prompt Format for number of carousel devices attached and number of used slots"),
                          count, carouselString, usedCount, slotString, [NSString stringFromByteCount:[[DACALDeviceService sharedService] totalVolumeSize]]];
	} else {
		NSArray *selectedNodes = [secondaryController selectedNodes];
		
		int			index = 0;
		int			count = [selectedNodes count];
		bool		isSearch = FALSE;
        
		index = [[secondaryController outlineView] numberOfRows];
		
		if( [[[self treeControl] selectedNodes] count] > 0 ) {
			sizeDevice = DACALDeviceForDeviceRef( [[[[[self treeControl] selectedNodes] objectAtIndex:0] nodeData] itemDevice]);
			if(sizeDevice)
				sizeString = [NSString stringFromByteCount:[sizeDevice totalVolumeSize]];
			
			if( [[[[[self treeControl] selectedNodes] objectAtIndex:0] nodeData] respondsToSelector:@selector(itemSearch)] )
				isSearch = TRUE;
		}
		
		if( count )			promptData = [NSString stringWithFormat:NSLocalizedString(@"%i of %i selected", @"Data View Standard Prompt Format for number of elements selected of total count"), count, index];
		else if( isSearch )	promptData = [NSString stringWithFormat:NSLocalizedString(@"%i %@", @"Data View Prompt Format for total count of visible elements of a search"), index, itemString, sizeString];
		else				promptData = [NSString stringWithFormat:NSLocalizedString(@"%i %@ %@", @"Data View Prompt Format for total count of visible elements and device total size"), index, itemString, sizeString];
	}
	
	if( (!canAdd) && (count > 0) ) {
		promptData = NSLocalizedString(@"Please purchase PickADisk to add more slots", @"Data View Prompt when max slots in demo mode");
		[noBoxIcon setImage:[NSImage imageNamed:@"noBox.png"]];
		[noBoxIcon setHidden:NO];
	}
	
    [self setPrompt:promptData];
}

- (void)searchFoundResults:(NSArray*)itemsFound forSearch:(PADSearchRequest*)theSearch
{
	[[secondaryController treeDataSource] sortExpandedChildrenWithCurrentDescriptors:[theSearch resultsSubTree]];
	
	[[secondaryController outlineView] reloadData];
	[[secondaryController treeDataSource] updatePrompt];
	// NSLog(@"Items Found: %@", itemsFound);
}

- (void)searchCompleted:(PADSearchRequest*)theSearch
{
	// all done!
	
	[[[[AppController shared] toolbarController] busyProgress] stopAnimation:self];
	
	// NSLog(@"Search Complete!");
}


- (void)outlineViewAction:(id)tree
{
	NSArray*					selectedNodes = [treeControl selectedNodes];
	IndexNodeData*				data =nil;
	SimpleTreeNode*				subTree = nil;
	PADSearchRequest*			itemSearch = nil;
	int							index = 0;
	DACALDeviceRef				theDevice = kDACALNullDevice;
	DACALSlotNum				theSlot = 0;
	PADIndexToolbarController*	toolControl = [self toolbarControl];
    //	NSArray*					dataRowsSelected = [secondaryController selectedNodes];
	SimpleTreeNode*				originalTree = nil;
	
	if( [selectedNodes count] == 0 )
        [tabView selectTabViewItemWithIdentifier:@"Home"];
	else  {
		[tabView selectTabViewItemWithIdentifier:@"Data"];
		[self toolbarSearchFinish:tree];
	}
	
	originalTree = [secondaryController treeRoot];
	[secondaryController setTreeRoot:nil];
	[toolControl resetSelection];
	
	for( index=0; index<[selectedNodes count]; index++ )
	{
		data = [[selectedNodes objectAtIndex:index] nodeData];
		subTree = [data subTree];
		if( [data respondsToSelector:@selector(itemSearch)] )
		{
			itemSearch = [data itemSearch];
			[[self outlineView] setCurrentSearch:itemSearch];
			//[(PADOutlineView*)[[[self secondaryController] treeDataSource] outlineView] setCurrentSearch:itemSearch];
			if( itemSearch != nil )
			{
				if( subTree == nil ) {
				}
				
				if( [itemSearch searchTarget] != self )
				{
					subTree = [[SimpleTreeNode alloc] initWithData:nil parent:nil children:[NSArray array]];
					[data setSubTree:subTree];
					[[[[AppController shared] toolbarController] busyProgress] startAnimation:self];
					[itemSearch setupSearchForTarget:self onNode:[selectedNodes objectAtIndex:index] andSubTree:subTree];
					[itemSearch startSearch];
				} else {
					if( ![itemSearch searchBusy] && [itemSearch searchResultsDirty] )
						[itemSearch startSearch];
				}
			}
		}
        
		if( subTree != nil )
			[secondaryController addTreeRoot:subTree];
		
		theDevice = [data itemDevice];
		theSlot = [data itemSlot];
		if( theSlot != 0 )
			[toolControl addSelectedNode:[selectedNodes objectAtIndex:index] adoptSelection:YES];
 		else if( theDevice != kDACALNullDevice )
			[toolControl addSelectedDevice:theDevice adoptSelection:YES];
		//else
		//	[toolControl resetSelectedNodesAndAdoptSelection:YES];
    }
	
	//if( originalTree && [originalTree isEqual:subTree] )
	//	[[secondaryController outlineView] selectItems:dataRowsSelected byExtendingSelection:NO];
	
	[secondaryController outlineViewAction:secondaryController];
	
	return;
}

- (void)nodeNameChanged:(SimpleTreeNode*)theNode toName:(NSString*)theName
{
	NSUndoManager*		undo = [self undoManager];
	SimpleNodeData*		theData = [theNode nodeData];
	DACALDeviceRef		theDevice = [theData itemDevice];
	NSInteger			theType = [theData itemType];
	NSString*			nowName = [NSString stringWithString:[theData name]];
    
	[[undo prepareWithInvocationTarget:self] nodeNameChanged:theNode toName:nowName];
	[undo setActionName:NSLocalizedString(@"Change Name", @"Undo Action when sidebar name column is changed")];
    
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
 	NSUndoManager*		undo = [self undoManager];
	NSPasteboard*		pboard = [info draggingPasteboard];
	NSString*			destinationFlavor = [[parentNode nodeData] itemFlavor];
    
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:DragDropSimplePboardType, nil]] != nil) {
        TreeController *dragDataSource = [[info draggingSource] dataSource];
        NSArray *_draggedNodes = [dragDataSource draggedNodes];
        NSEnumerator *draggedNodesEnum = [_draggedNodes objectEnumerator];
        SimpleTreeNode *_draggedNode = nil;
        //		SimpleTreeNode *_bioParent = nil;
        //		int				itemRow = 0;
        
		[undo beginUndoGrouping];
		
        while ((_draggedNode = [draggedNodesEnum nextObject])) {
			
			if( [dragDataSource treeDataSource] != nil )
				[[dragDataSource treeDataSource] performSelector:@selector(nodeTypeChanged:toType:)
												  withObject:(SimpleTreeNode*)_draggedNode
												  withObject:destinationFlavor];
			
			//[[dragDataSource outlineView] reloadItem:_draggedNode];
		}
		//[[dragDataSource outlineView] reloadData];
		//[[PADSearchService sharedSearch] searchDataChanged:_draggedNodes];
		
		[undo endUndoGrouping];
		[undo setActionName:NSLocalizedString(@"Change Type", @"Undo Group Action when flavor type is changed for items in a drag")];
		
		[AppController playUISound: kASSystemSoundSuccess];
	}
}

- (void)dropNodesOntoFavoritesGroup:(id <NSDraggingInfo>)info onNode:(TreeNode *)parentNode atIndex:(NSInteger)childIndex
{
    NSPasteboard*	pboard = [info draggingPasteboard];
	SimpleTreeNode*	newMark = nil;
    //	SimpleTreeNode* newMarkTree = nil;
    
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:DragDropSimplePboardType, nil]] != nil) {
        TreeController *dragDataSource = [[info draggingSource] dataSource];
        NSArray *_draggedNodes = [dragDataSource draggedNodes];
        NSEnumerator *draggedNodesEnum = [_draggedNodes objectEnumerator];
        SimpleTreeNode *_draggedNode = nil;
		BOOL	sourceWasUs = [[self treeControl] isEqual:dragDataSource];
        
        while ((_draggedNode = [draggedNodesEnum nextObject]))
		{
			if( !sourceWasUs ) {
				//newMark = (SimpleTreeNode*)[SimpleTreeNode nodeDataWithURL:(NSURL*)[(SimpleNodeData*)[_draggedNode nodeData] itemURL]];
				//newMarkTree = (SimpleTreeNode*)[SimpleTreeNode treeOperationFromLocation:(NSURL*)[(SimpleNodeData*)[_draggedNode nodeData] itemURL] forUI:YES];
				//[[newMark nodeData] setSubTree:newMarkTree];
				//[[newMark nodeData] setIsLeaf:YES];
				//[[newMark nodeData] setExpandable:NO];
				DACALSlotElement*			itemSlotElement = [(SimpleNodeData*)[_draggedNode nodeData] itemElement];
				DACALSlotElementBookmark*	itemSlotBookmark = [itemSlotElement createBookmarkAtLocation:kDACBookmarkLocationInSidebar attachNow:NO];
				if( itemSlotBookmark != nil )
					[parentNode insertChild:[itemSlotBookmark markNode] atIndex:childIndex];
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
	NSArray *_draggedNodes = [[[info draggingSource] treeDataSource] draggedNodes];
	int		nodeIndex, nodeCount = [_draggedNodes count];
	
	if( fromThisView )
		for(nodeIndex=0; nodeIndex<nodeCount; nodeIndex++)
			if( [[[_draggedNodes objectAtIndex:nodeIndex] nodeData] respondsToSelector:@selector(itemSearch)] ) {
				PADSearchRequest*	theSearch = [[[_draggedNodes objectAtIndex:nodeIndex] nodeData] itemSearch];
				if( theSearch != nil ) {
					[theSearch dirtySearchResults];
				}
			}
	
	if( fromThisView ) {
		BOOL allGroups = YES;
		for(nodeIndex=0; nodeIndex<nodeCount; nodeIndex++) {
			if( [[[_draggedNodes objectAtIndex:nodeIndex] nodeData] isLeaf] == YES )
				allGroups = NO;
			break;
		}
		if( allGroups == YES ) {
			if( item && [[item nodeData] isGroup] == YES )
				return NSDragOperationNone;
			else return NSDragOperationMove;
		}
		if( ![item isParentOfNodesInArray: [treeControl draggedNodes]] ) return NSDragOperationNone;
	}
	if( [[item nodeData] itemType] == kPADTypeGroupFavorites ) {
		return NSDragOperationNone;										//	Bookmarks need help!
		if( fromThisView ) return NSDragOperationMove;
		else return NSDragOperationCopy;
	}
	if( [[[item nodeParent] nodeData] itemType] == kPADTypeGroupLibrary ) {
		//NSArray *_draggedNodes = [[[info draggingSource] treeDataSource] draggedNodes];
		//int		nodeIndex, nodeCount = [_draggedNodes count];
		
		for(nodeIndex=0; nodeIndex<nodeCount; nodeIndex++)
			if( [[[[_draggedNodes objectAtIndex:nodeIndex] nodeData] itemFlavor] compare:[[item nodeData] itemFlavor]] != NSOrderedSame )
				return NSDragOperationLink;
	}
	
	if( fromThisView )
        return [super validateDropSource:info proposedItem:item proposedChildIndex:childIndex];
	
	return NSDragOperationNone;
}

- (BOOL)actualOutlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex {
	
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

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex {
    
	BOOL	wasDropped = [self actualOutlineView:ov acceptDrop:info item:item childIndex:childIndex];
	
	if( wasDropped )					// Save the tree order
		[self saveUserOrder];
	
	return wasDropped;
}

- (SimpleTreeNode*)findTreeNodeForDevice:(DACALDeviceRef)theBoxRef
{ return [[[[self treeControl] treeRoot] childWithItemType:kPADTypeGroupDevices] childWithDevice:theBoxRef]; }

// moved to DACALSlot - (BOOL)slotAssignedIndexFromVolume:(DACVolume*)indexVolume asType:(NSString*)newType
- (void)slotAddedToDevice:(DACALDeviceRef)theBoxRef forSlot:(DACALSlotNum)newSlot
{
	NSLog(@"Warning!! Obsolete add method called!?");
	return;
	
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
		
		[[PADSearchService sharedSearch] searchDataChanged:[NSArray arrayWithObject:theSubtreeChild]];
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

- (NSString*)toolTipForCell:(NSCell *)cell rect:(NSRectPointer)inRect tableColumn:(NSTableColumn *)tc item:(id)inItem mouseLocation:(NSPoint)inMouseLocation
{
	if( [[inItem nodeData] itemSlot] != 0 )
		return [inItem tooltip];
	
	return nil;
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
    // TODO: not sure we need to call toolbarSearchFinish unless there was some dirty data in the inspector or view
	[self toolbarSearchFinish:self];
	[[NSApplication sharedApplication] terminate:self];
}

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	// NSLog(@"Dragged Operation: %i", operation);
	
	if( operation == NSDragOperationNone )
	{
		NSPoint		mousePoint = [NSEvent mouseLocation];
		NSPoint		localPoint = [[self outlineView] convertPoint:[[[self outlineView] window] convertScreenToBase:mousePoint] fromView:nil];
		if( [[self outlineView] hitTest:localPoint] == nil )
		{
			//	Actual delete removed because it is too intense!
			//[super draggedImage:image endedAt:screenPoint operation:NSDragOperationDelete];
            /*
             NSDictionary*			visActDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"PADPrefsTreeIndexAvailability"];
             NSMutableDictionary*	visDict = [NSMutableDictionary dictionaryWithCapacity:0];
             
             if( visActDict != nil )
             [visDict addEntriesFromDictionary:visActDict];
             
             NSArray*		byebye = [[self treeControl] draggedNodes];
             NSEnumerator*	byeEnum = [byebye objectEnumerator];
             SimpleTreeNode*	byeNode = nil;
             SimpleTreeNode*	byeParent = nil;
             NSMutableDictionary*	byeDict = nil;
             
             while ( byeNode = (SimpleTreeNode*)[byeEnum nextObject] )
             {
             byeParent = (SimpleTreeNode*)[byeNode nodeParent];
             
             byeDict = [NSMutableDictionary dictionaryWithCapacity:0];
             [byeDict setObject:(id)kCFBooleanFalse forKey:[[byeNode nodeData] name]];
             
             [visDict setObject:byeDict forKey:[[byeParent nodeData] name]];
             }
             
             [[NSUserDefaults standardUserDefaults] setObject:visDict forKey:@"PADPrefsTreeIndexAvailability"];
             
             [[self treeControl] recreateInitialTree];
             */
			NSShowAnimationEffect(NSAnimationEffectPoof, mousePoint, NSZeroSize, nil, nil, nil);
			return;
		}
	}
	
	[super draggedImage:image endedAt:screenPoint operation:operation];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	//NSLog(@"Validate Menu Item: %@", [menuItem title]);
	
    if ([menuItem action]==@selector(deleteSelection:)) {
		// The delete selection item should be disabled if nothing is selected.
		if( [[[self treeControl] selectedNodes] count] == 0 )
			return NO;
		
		if( [[[[self treeControl] selectedNodes] objectAtIndex:0] itemType] == kPADTypeIndexFavorites )
			return YES;
		
		return NO;
    }
	
	if( [menuItem action]==@selector(selectAll:) )
		return NO;
	
    return [super validateMenuItem:menuItem];
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	NSOutlineView*	outlineView = [ treeControl outlineView ];
    NSInteger		clickedRow = [outlineView clickedRow];
    id				item = nil;
    SimpleNodeData*	nodeData = nil;
	NSMenuItem*		workItem = nil;
	SEL				workSelector = nil;
	NSInteger		itemIndex, itemCount = [menu numberOfItems];
	
    if (clickedRow != -1) {
        item = [outlineView itemAtRow:clickedRow];
        nodeData = [item nodeData];
    }
    
    if (menu == outlineViewContextMenu)
	{
		for( itemIndex=0; itemIndex < itemCount; itemIndex++ ) {
			workItem = [menu itemAtIndex:itemIndex];
			workSelector = [workItem action];
			if( workSelector == @selector(ctmDeleteSelection:) )						//	Remove Item
				[workItem setEnabled:[nodeData itemType] == kPADTypeIndexFavorites];
			if( workSelector == @selector(ctmRefreshSearch:) )							//	Refresh Search
				[workItem setEnabled:[nodeData respondsToSelector:@selector(itemSearch)] && [nodeData isLeaf]];
		}
	}
    
}

-(IBAction)ctmRefreshSearch:(id)sender
{
	NSArray*		clickedRows = [self ctmClickedRows];
    id				item = ([clickedRows count] > 0) ? [clickedRows objectAtIndex:0] : nil;
    IndexNodeData*	nodeData = (IndexNodeData*)[item nodeData];
	
	if( [nodeData respondsToSelector:@selector(itemSearch)] )
		[[nodeData itemSearch] dirtySearchResults];
	
	[self doAction];
}

-(IBAction)ctmDeleteSelection:(id)sender
{
	NSOutlineView*	outlineView = [ treeControl outlineView ];
    NSInteger		clickedRow = [outlineView clickedRow];
    id				item = nil;
    SimpleNodeData*	nodeData = nil;
	
    if (clickedRow != -1) {
        item = [outlineView itemAtRow:clickedRow];
        nodeData = [item nodeData];
    }
	
	// NSLog(@"Delete Item: %@\nElement: %@", item, [nodeData itemElement]);
	
	[[nodeData itemElement] removeBookmarkForLocation:kDACBookmarkLocationInSidebar];
	
	[self doAction];
}

@end	// DACALTreeDataSource
