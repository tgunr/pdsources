//
//  DACALTreeDataSource.m
//  DragNDropOutlineView
//
//  Created by Jack Small on 7/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DACALTreeDataSource.h"
#import "PADSearchRequest.h"
#import "pmsDACALUtility.h"

@implementation DACALIndexState

-(void)dealloc
{
	if( savedViewData) [savedViewData release];
	savedViewData = nil;
	
	[super dealloc];
}

-(void)restoreSettingsForKey:(NSString*)keyName
{
	NSOutlineView*	theView = [[savedViewData objectForKey:keyName] objectForKey:@"View"];
	NSIndexSet*		theIndex = [[savedViewData objectForKey:keyName] objectForKey:@"Selection"];
	NSArray*		theSorts = [[savedViewData objectForKey:keyName] objectForKey:@"Sorts"];
	
	if( [theView isKindOfClass:[NSOutlineView class]] ) {
		if( theSorts ) [theView setSortDescriptors:theSorts];
		if( theIndex ) [theView selectRowIndexes:theIndex byExtendingSelection:NO];
	}		
}

-(void)restoreSettings
{
	NSString*		theKey = nil;
	NSEnumerator*	keyList = [savedViewData keyEnumerator];

	while ( (theKey = (NSString*)[keyList nextObject])  ) 
		[self restoreSettingsForKey:theKey];	
}

-(void)removeSetting:(NSString*)settingName forKey:(NSString*)keyName
{
	NSMutableDictionary*	itemDict = [savedViewData objectForKey:keyName];
	
	
	if( itemDict ) {
		if( settingName != nil ) [itemDict removeObjectForKey:settingName];
		else [savedViewData removeObjectForKey:keyName];
	}
}

-(id)init
{
	if( self = [super init] )
	{
		savedViewData = [[NSMutableDictionary alloc] initWithCapacity:2];
	}
	return self;
}

-(void)addSettingsForKey:(NSString*)keyName saveView:(NSOutlineView*)doView saveSelection:(BOOL)doSelect saveSorts:(BOOL)doSorts
{
	NSIndexSet*	theIndex = (doSelect) ? [doView selectedRowIndexes] : nil;
	NSArray*	theSorts = (doSorts)  ? [doView sortDescriptors] : nil;
	NSMutableDictionary*	theData = [NSMutableDictionary dictionaryWithCapacity:4];

	[theData setObject:doView forKey:@"View"];
	if( theIndex ) [theData setObject:theIndex forKey:@"Selection"];
	if( theSorts ) [theData setObject:theSorts forKey:@"Sorts"];
	
	[savedViewData setObject:theData forKey:keyName];
}

+(id)saveSetupForKey:(NSString*)keyName saveView:(NSOutlineView*)doView saveSelection:(BOOL)doSelect saveSorts:(BOOL)doSorts
{
	DACALIndexState* newState = [[DACALIndexState alloc] init];
	
	[newState addSettingsForKey:keyName saveView:doView saveSelection:doSelect saveSorts:doSorts];
	
	return newState;
}

@end	// DACALIndexState

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
	SimpleTreeNode*		theGroupNode = nil;
	IndexNodeData*		theWorkData = nil;
	
	[tree setAllowGroupRowLook:YES];
	[tree setAllowBetweenDrop:YES];

	PADBOX_VALID_BEGIN
		
	// Load our initial outline view data from the "InitInfo" dictionary.
	NSDictionary *initData = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"InitInfo" ofType: @"dict"]];
	if( initData != nil ) theOutputTree = [SimpleTreeNode treeIndexFromDictionary: initData];	
		
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
	[theWorkData setItemSearch:[PADSearchRequest searchCarouselsForDateAddedBeforeDays:1 ofDate:nil resultType:kPADSearchOptionResultTypeItem]];
	
	theWorkNode = [theGroupNode childWithName:@"Yesterday"];
	theWorkData = [theWorkNode nodeData];
	[theWorkData setItemSearch:[PADSearchRequest searchCarouselsForDateAddedBeforeDays:1 ofDate:@"Yesterday" resultType:kPADSearchOptionResultTypeItem]];
	
	theWorkNode = [theGroupNode childWithName:@"Past Week"];
	theWorkData = [theWorkNode nodeData];
	[theWorkData setItemSearch:[PADSearchRequest searchCarouselsForDateAddedBeforeDays:7 ofDate:nil resultType:kPADSearchOptionResultTypeItem]];
	
	theWorkNode = [theGroupNode childWithName:@"Past Month"];
	theWorkData = [theWorkNode nodeData];
	[theWorkData setItemSearch:[PADSearchRequest searchCarouselsForDateAddedBeforeDays:30 ofDate:nil resultType:kPADSearchOptionResultTypeItem]];
	
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
	if( !savedSelection ) {
		savedSelection = [DACALIndexState saveSetupForKey:@"DataIndex" saveView:[[self treeControl] outlineView] saveSelection:YES saveSorts:NO];
		[savedSelection addSettingsForKey:@"DataView" saveView:[secondaryController outlineView] saveSelection:YES saveSorts:YES];
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
		sortedSelection = [DACALIndexState saveSetupForKey:@"SortData" saveView:[secondaryController outlineView] saveSelection:NO saveSorts:YES];
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
	   	   
- (void)searchFoundResults:(NSArray*)itemsFound forSearch:(PADSearchRequest*)theSearch
{
	[[secondaryController dataSource] sortExpandedChildrenWithCurrentDescriptors:[theSearch resultsSubTree]];
	
	[[secondaryController outlineView] reloadData];
	[[secondaryController dataSource] updatePrompt];
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
	NSArray *selectedNodes = [treeControl selectedNodes];
//	NSMutableArray *selectedBoxes = [NSMutableArray arrayWithCapacity:0];
	IndexNodeData *data;
	SimpleTreeNode *subTree;
	PADSearchRequest* itemSearch;
	int		index;
//	NSURL*	theURL;
	DACALDeviceRef theDevice;
	DACALSlotNum	theSlot;
	PADIndexToolbarController* toolControl = (PADIndexToolbarController*)[self toolbarControl];
	
	if( [selectedNodes count] == 0 ) [tabView selectTabViewItemWithIdentifier:@"Home"];
	else  {
		[tabView selectTabViewItemWithIdentifier:@"Data"];
		[self toolbarSearchFinish:tree];
	}
	
	[secondaryController setTreeRoot:nil];
	//[secondaryController removeAllChildren];
	[toolControl resetSelection];
	
	for( index=0; index<[selectedNodes count]; index++ )
	{
		data = [[selectedNodes objectAtIndex:index] nodeData];
		subTree = [data subTree];
		if( [data respondsToSelector:@selector(itemSearch)] ) {
			itemSearch = [data itemSearch];
			if( itemSearch != nil )
			{
				if( subTree == nil ) {
				}
				
				if( ([itemSearch searchBusy] == NO) && ([itemSearch searchResultsDirty]) ) {					
					subTree = [[SimpleTreeNode alloc] initWithData:nil parent:nil children:[NSArray array]];
					[data setSubTree:subTree];
					[[[[AppController shared] toolbarController] busyProgress] startAnimation:self];
					[itemSearch startSearchForTarget:self andSubTree:subTree];
				}
			}
		}
			

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
		[AppController playUISound: kASSystemSoundSuccess];
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
	NSArray *_draggedNodes = [[[info draggingSource] dataSource] draggedNodes];
	int		nodeIndex, nodeCount = [_draggedNodes count];
	
	if( fromThisView )
		for(nodeIndex=0; nodeIndex<nodeCount; nodeIndex++)
			if( [[[_draggedNodes objectAtIndex:nodeIndex] nodeData] respondsToSelector:@selector(itemSearch)] ) {
				PADSearchRequest*	theSearch = [[[_draggedNodes objectAtIndex:nodeIndex] nodeData] itemSearch];
				if( theSearch != nil ) {
					[theSearch dirtySearchResults];
				}
			}
	
	if( [[item nodeData] itemType] == kPADTypeGroupFavorites ) {
		if( fromThisView ) return NSDragOperationMove;
		else return NSDragOperationCopy;
	}
	else if( [[[item nodeParent] nodeData] itemType] == kPADTypeGroupLibrary ) {
		//NSArray *_draggedNodes = [[[info draggingSource] dataSource] draggedNodes];
		//int		nodeIndex, nodeCount = [_draggedNodes count];
		
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
	[self toolbarSearchFinish:self];
	[[NSApplication sharedApplication] terminate:self];
}


@end	// DACALTreeDataSource


@implementation DACALViewDataSource

- (void)dealloc
{
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADColumnSlotType"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADColumnSlotNum"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADColumnDateAdded"];

	[super dealloc];
}

- (void)awakeFromNib 
{
	if( !PADBOX_VALIDATED ) [[[treeControl outlineView] window] orderOut:self];
	
	[[AppController shared] setDataView: treeControl];

//	NSTableColumn*		nameCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_NAME];
	NSTableColumn*		slotCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_SLOT];
	NSTableColumn*		aDayCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_MODDATE];
	NSTableColumn*		flavCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_TYPE];
//	NSTableColumn*		rankCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_SCORE];
	
	// NSSortDescriptor*	nameSort = [[[NSSortDescriptor alloc] initWithKey:@"keyName" ascending:YES selector:@selector(compareDataNames:)] autorelease];
	// NSSortDescriptor*	slotSort = [[[NSSortDescriptor alloc] initWithKey:@"keySlotNumber" ascending:YES selector:@selector(compareDataSlots:)] autorelease];
	// NSSortDescriptor*	aDaySort = [[[NSSortDescriptor alloc] initWithKey:@"keyAddDate" ascending:YES selector:@selector(compareDataAddDates:)] autorelease];
	// NSSortDescriptor*	flavSort = [[[NSSortDescriptor alloc] initWithKey:@"keyFlavor" ascending:YES selector:@selector(compareDataFlavors:)] autorelease];
	// NSSortDescriptor*	rankSort = [[[NSSortDescriptor alloc] initWithKey:@"keyScore" ascending:NO selector:@selector(compareDataScores:)] autorelease];
	
	BOOL				slotVisible = [[NSUserDefaults standardUserDefaults] boolForKey:@"PADColumnSlotNum"];
	BOOL				aDayVisible = [[NSUserDefaults standardUserDefaults] boolForKey:@"PADColumnDateAdded"];
	BOOL				flavVisible = [[NSUserDefaults standardUserDefaults] boolForKey:@"PADColumnSlotType"];
	
	// NSMutableArray*		startOrder = [NSMutableArray arrayWithCapacity:5];
	
	// [nameCol setSortDescriptorPrototype:nameSort];
	// [slotCol setSortDescriptorPrototype:slotSort];
	// [aDayCol setSortDescriptorPrototype:aDaySort];
	// [flavCol setSortDescriptorPrototype:flavSort];
	// [rankCol setSortDescriptorPrototype:rankSort];
	
	// if( slotVisible )	[startOrder addObject:slotSort];
	// 					[startOrder addObject:nameSort];
	// if( flavVisible )	[startOrder addObject:flavSort];
	// if( aDayVisible )	[startOrder addObject:aDaySort];
		
	// [[treeControl outlineView] setSortDescriptors:startOrder];
	
	[slotCol setHidden:!slotVisible];
	[aDayCol setHidden:!aDayVisible];
	[flavCol setHidden:!flavVisible];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADColumnDateAdded" options:0 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADColumnSlotNum" options:0 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADColumnSlotType" options:0 context:NULL];

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
	
	//[AppController playUISound: kASSystemSoundSuccess];
	return;
	
SLOTTYPEFAILED:
	if( theErr != 0 ) NSLog(@"Error:%i Setting to:%@ for URL:%@", (int)theErr, theName, (NSURL*)theURL);
	[AppController playUISound: kASSystemSoundDoink];
	return;
}

- (void)nodeDidCollapse:(SimpleTreeNode*)theNode
{
	[self updatePrompt];
	return;
}

- (void)nodeDidExpand:(SimpleTreeNode*)theNode
{
	[self updatePrompt];
	return;
}

- (void)selectionDidChange
{
	[self updatePrompt];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == [NSUserDefaultsController sharedUserDefaultsController] )
	{
		NSTableColumn*		workColumn = nil;
		NSSortDescriptor*	workSorter = nil;
		NSArray*			viewSorts = nil;
		NSMutableArray*		viewNewSorts = nil;
		NSInteger			workIndex = 0;
		NSString*			workKey = nil;
		BOOL				isVisible = NO;
		
		if( [keyPath hasSuffix:@"PADColumnDateAdded"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_MODDATE];
			workKey = @"PADColumnDateAdded";
		}
		
		if( [keyPath hasSuffix:@"PADColumnSlotNum"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_SLOT];
			workKey = @"PADColumnSlotNum";
		}
		
		if( [keyPath hasSuffix:@"PADColumnSlotType"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_TYPE];
			workKey = @"PADColumnSlotType";
		}
		
		if( workKey ) isVisible = [[NSUserDefaults standardUserDefaults] boolForKey:workKey];
		if( workColumn ) {
			[workColumn setHidden:!isVisible];

			workSorter = [workColumn sortDescriptorPrototype];
			viewSorts = [[[self treeControl] outlineView] sortDescriptors];
			workIndex = [viewSorts indexOfObjectIdenticalTo:workSorter];

			viewNewSorts = [NSMutableArray arrayWithCapacity:[viewSorts count]];
			[viewNewSorts addObjectsFromArray:viewSorts];
			if( (workIndex != NSNotFound) && !isVisible ) 
				[viewNewSorts removeObjectAtIndex:workIndex];
			if( isVisible && (workIndex == NSNotFound) )
				[viewNewSorts addObject:workSorter];
			
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_NAME];
			workSorter = [workColumn sortDescriptorPrototype];
			[viewNewSorts removeObjectIdenticalTo:workSorter];
			[viewNewSorts insertObject:workSorter atIndex:0];
			
			[[[self treeControl] outlineView] setSortDescriptors:viewNewSorts];
			[self sortExpandedChildrenWithCurrentDescriptors:nil];
		}
		//NSLog(@"Column:%@ key:%@ visible:%i", workColumn, workKey, isVisible);
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


@end	// DACALViewDataSource
