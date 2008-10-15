//
//  DACALViewDataSource.m
//  PickADisk
//
//  Created by Jack Small on 8/30/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "DACALViewDataSource.h"

@implementation DACALViewDataSource

- (void)dealloc
{
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADColumnSlotType"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADColumnSlotNum"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADColumnDateAdded"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADColumnCheckedOut"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADColumnDateCheckedOut"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADColumnComments"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADColumnTags"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADColumnRating"];

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
	NSTableColumn*		chckCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_CHECKEDOUT];
	NSTableColumn*		cDayCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_DATECHECKEDOUT];
	NSTableColumn*		cmtsCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_COMMENT];
	NSTableColumn*		tagsCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_TAGS];
	NSTableColumn*		strsCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_STARS];
//	NSTableColumn*		rankCol = [[treeControl outlineView] tableColumnWithIdentifier:COLUMNID_SCORE];
	
	// NSSortDescriptor*	nameSort = [[[NSSortDescriptor alloc] initWithKey:@"keyName" ascending:YES selector:@selector(compareDataNames:)] autorelease];
	// NSSortDescriptor*	slotSort = [[[NSSortDescriptor alloc] initWithKey:@"keySlotNumber" ascending:YES selector:@selector(compareDataSlots:)] autorelease];
	// NSSortDescriptor*	aDaySort = [[[NSSortDescriptor alloc] initWithKey:@"keyAddDate" ascending:YES selector:@selector(compareDataAddDates:)] autorelease];
	// NSSortDescriptor*	flavSort = [[[NSSortDescriptor alloc] initWithKey:@"keyFlavor" ascending:YES selector:@selector(compareDataFlavors:)] autorelease];
	// NSSortDescriptor*	rankSort = [[[NSSortDescriptor alloc] initWithKey:@"keyScore" ascending:NO selector:@selector(compareDataScores:)] autorelease];
	
	BOOL				slotVisible = [[NSUserDefaults standardUserDefaults] boolForKey:@"PADColumnSlotNum"];
	BOOL				aDayVisible = [[NSUserDefaults standardUserDefaults] boolForKey:@"PADColumnDateAdded"];
	BOOL				flavVisible = [[NSUserDefaults standardUserDefaults] boolForKey:@"PADColumnSlotType"];
	BOOL				chckVisible = [[NSUserDefaults standardUserDefaults] boolForKey:@"PADColumnCheckedOut"];
	BOOL				cDayVisible = [[NSUserDefaults standardUserDefaults] boolForKey:@"PADColumnDateCheckedOut"];
	BOOL				cmtsVisible = [[NSUserDefaults standardUserDefaults] boolForKey:@"PADColumnComments"];
	BOOL				tagsVisible = [[NSUserDefaults standardUserDefaults] boolForKey:@"PADColumnTags"];
	BOOL				strsVisible = [[NSUserDefaults standardUserDefaults] boolForKey:@"PADColumnRating"];
	
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
	[chckCol setHidden:!chckVisible];
	[cDayCol setHidden:!cDayVisible];
	[cmtsCol setHidden:!cmtsVisible];
	[tagsCol setHidden:!tagsVisible];
	[strsCol setHidden:!strsVisible];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADColumnDateAdded" options:0 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADColumnSlotNum" options:0 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADColumnSlotType" options:0 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADColumnCheckedOut" options:0 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADColumnDateCheckedOut" options:0 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADColumnComments" options:0 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADColumnTags" options:0 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADColumnRating" options:0 context:NULL];

}

- (SimpleTreeNode*)createInitialTree:(id)tree
{
	SimpleTreeNode*		theOutputTree = nil;	
	return theOutputTree;
}

- (void)updatePrompt
	{ [[DACALTreeDataSource shared] doReport]; }

-(id)objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    id objectValue = nil;
    SimpleNodeData *data = [item nodeData];

	if ([[tableColumn identifier] isEqualToString:COLUMNID_SLOT]) {
		objectValue = [NSString stringWithFormat:@"%i", [data itemSlot]];
	} else if ([[tableColumn identifier] isEqualToString:COLUMNID_MODDATE]) {
		//NSDateFormatter*	thisDateForm = [[NSDateFormatter alloc] init];
		//objectValue = [thisDateForm stringFromDate:[data itemModDate]]; 
		objectValue = [data itemAddDate];
	} else if ([[tableColumn identifier] isEqualToString:COLUMNID_TYPE]) {
		objectValue = DACALCreateImageRefForFlavor([data itemFlavor]);
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_SCORE]) {
		SearchNodeData *Sdata = [item nodeData];
		objectValue = [NSNumber numberWithInt:(int)([Sdata matchScore]*100)];
	} else if ([[tableColumn identifier] isEqualToString:COLUMNID_CHECKEDOUT]) {
		SearchNodeData *Sdata = [item nodeData];
		NSString*	imagePath = nil;
		NSImage*	theImage = nil;
		NSBundle*	imageBundle = [NSBundle mainBundle];
		
		if( [Sdata isCheckedOut] )
			if( imagePath = [imageBundle pathForResource:@"CheckedOut" ofType:@"png"] )
				theImage = [[NSImage alloc] initByReferencingFile:imagePath]; 
		
		objectValue = theImage;
	} else if ([[tableColumn identifier] isEqualToString:COLUMNID_DATECHECKEDOUT]) {
		objectValue = [data checkedOutDate];
	} else if ([[tableColumn identifier] isEqualToString:COLUMNID_COMMENT]) {
		NSString*	outComments = [data keyComments];
		objectValue = outComments;
	} else if ([[tableColumn identifier] isEqualToString:COLUMNID_TAGS]) {
		NSArray*	outTags = [data keyTags];
		if( outTags == nil ) outTags = [NSArray array];
		objectValue = outTags;
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_STARS]) {
		objectValue = [NSNumber numberWithInt:(int)([data keyStars])];
	} else
		objectValue = [super objectValueForTableColumn:tableColumn byItem:item];
	
	return objectValue;
}


-(void)setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	SimpleNodeData *data = [item nodeData];
    
   // Here, we manipulate the slot data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_SLOT]) {
		[self nodeSlotChanged:item toSlot:object];
		return;
	}
	
    // Here, we manipulate the type/flavor data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_TYPE]) {
		[self nodeTypeChanged:item toType:object];
		return;
	}

	// Here, we manipulate the comment data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_COMMENT]) {
		[data setKeyComments:object];
		return;
	}
	
	// Here, we manipulate the tag data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_TAGS]) {
		[data setKeyTags:object];
		return;
	}

	// Here, we manipulate the stars data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_STARS]) {
		NSInteger	newStars = [object intValue];
		[item setKeyStars:newStars];
		return;
	}
	
	[super setObjectValue:object forTableColumn:tableColumn byItem:item];
}


- (void)outlineViewAction:(id)tree
{
	NSArray*		selectedNodes = [treeControl selectedNodes];
	NSEnumerator*	selectedEnum = [selectedNodes objectEnumerator];
	SimpleTreeNode*	item = nil;
	int				count = [selectedNodes count];

	DACALSlotNum	theSlot;
	PADIndexToolbarController* toolControl = (PADIndexToolbarController*)[self toolbarControl];
	
	[toolControl setSelectedNode:nil];
	
	while( item = [selectedEnum nextObject] )
		if( [[item nodeData] itemSlot] != 0 ) 
			[toolControl addSelectedNode:item];

	[self updatePrompt];

	return;
}

- (void)nodeNameChanged:(SimpleTreeNode*)theNode toName:(NSString*)theName
{
	SimpleNodeData	*theData = [theNode nodeData];
	DACALSlotElement*	theElement = DACALDeviceSlotElementForURL( (CFURLRef)[theData location] );

	if( [[theData name] compare:theName] == NSOrderedSame ) return;
	if( [theName length] == 0 ) goto SLOTNAMEFAILED;
	if( theElement == nil ) goto SLOTNAMEFAILED;
	
	[theElement setTitle:theName];
	
	[AppController playUISound: kASSystemSoundSuccess];
	return;
	
SLOTNAMEFAILED:
	
	[AppController playUISound: kASSystemSoundDoink];
	return;
}

/*
- (void)nodeNameChanged:(SimpleTreeNode*)theNode toName:(NSString*)theName
{
	SimpleNodeData	*theData = [theNode nodeData];
	// DACALDeviceRef	theBox = [theData itemDevice];
	// DACALSlotNum	theSlot = [theData itemSlot];
	SimpleTreeNode*	actualNode = theNode;
	// CFURLRef		theShortURL = NULL;
	// CFURLRef		theNewURL = NULL;
	// DACALResult		theErr;
	OSStatus		theErr;
	
	if( [[theData name] compare:theName] == NSOrderedSame ) return;
	if( [theName length] == 0 ) goto SLOTNAMEFAILED;
	
	if( [theData respondsToSelector:@selector(matchActual)] ) {
		theNode = [(SearchNodeData*)theData matchActual];
		theData = [theNode nodeData];
		// theBox = [theData itemDevice];
		// theSlot = [theData itemSlot];
	}
	
	// This should not be possible since we checked already before we allowed editing.
	// if( (theURL == NULL) || (CFURLIsSlot(theURL) != TRUE) ) return;
	
	// theErr = DACALSlotSetTitle( theBox, theSlot, (CFStringRef)theName );
	// if( theErr != 0 ) goto SLOTNAMEFAILED;
	
	theErr = CFURLSetReferenceTitle( (CFURLRef)[theData location], (CFStringRef)theName );
	if( theErr != 0 ) goto SLOTNAMEFAILED;

	[theData setName:theName];
	// theShortURL = CFURLCreateCopyDeletingLastPathComponent( kCFAllocatorDefault, (CFURLRef)[theData location] );
	// theNewURL = CFURLCreateCopyAppendingPathComponent( kCFAllocatorDefault, theShortURL, (CFStringRef)theName, TRUE );
	// CFRelease( theShortURL );
	// [theData setLocation:(NSURL*)theNewURL];
	
	if( actualNode != theNode ) {
		// [[actualNode nodeData] setLocation:(NSURL*)theNewURL];
		[(SimpleNodeData*)[actualNode nodeData] setName:theName];
		[self sortExpandedChildrenWithCurrentDescriptors:(SimpleTreeNode*)[actualNode nodeParent]];
	}

	[self sortExpandedChildrenWithCurrentDescriptors:(SimpleTreeNode*)[theNode nodeParent]];

	[[PADSearchService sharedSearch] searchDataChanged:[NSArray arrayWithObject:actualNode]];
	
	[AppController playUISound: kASSystemSoundSuccess];
	return;
	
SLOTNAMEFAILED:
	
	[AppController playUISound: kASSystemSoundDoink];
	return;
}
*/

- (void)nodeSlotChanged:(SimpleTreeNode*)node toSlot:(NSString*)slotString
{
	DACALSlotNum	oldSlot = [[node nodeData] itemSlot];
	DACALSlotNum	newSlot = [slotString intValue];
	DACALDevice*	oldBox = DACALDeviceForDeviceRef( [[node nodeData] itemDevice] );
	
	if( oldSlot == newSlot ) return;
	
	[oldBox swapSlotNumber:oldSlot toDevice:nil toSlotNumber:newSlot];
}

- (void)nodeTypeChanged:(SimpleTreeNode*)theNode toType:(NSString*)theName
{
	SimpleNodeData	*theData = [theNode nodeData];
	DACALSlotElement*	theElement = DACALDeviceSlotElementForURL( (CFURLRef)[theData location] );
	
	if( [[theData name] compare:theName] == NSOrderedSame ) return;
	if( [theName length] == 0 ) goto SLOTNAMEFAILED;
	if( theElement == nil ) goto SLOTNAMEFAILED;
	
	[theElement setFlavor:theName];
	
	[AppController playUISound: kASSystemSoundSuccess];
	return;
	
SLOTNAMEFAILED:
	
	[AppController playUISound: kASSystemSoundDoink];
	return;
}

/*
- (void)nodeTypeChanged:(SimpleTreeNode*)theNode toType:(NSString*)theName
{
	SimpleNodeData	*theData = [theNode nodeData];
	CFURLRef		theURL = (CFURLRef)[theData location];
	
//	CFURLRef		testURL = (CFURLRef)[(SimpleNodeData*)[theNode nodeData] location];
	DACALResult		theErr;
	
//	CFShow(testURL);
//	theURL = testURL;
	
	if( [[theData itemFlavor] compare:theName] == NSOrderedSame ) return;
	
	if( [theData respondsToSelector:@selector(matchActual)] ) {
		[theData setItemFlavor:theName];
		[theData setIconRep:CFURLGetIconAsNSImage( NULL, (CFURLRef)theURL, NULL)];
		[self sortExpandedChildrenWithCurrentDescriptors:(SimpleTreeNode*)[theNode nodeParent]];
		theNode = [(SearchNodeData*)theData matchActual];
		theData = [theNode nodeData];
	}
	
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
*/

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
	//[self updatePrompt];
	[self outlineViewAction:nil];
	return;
}

- (NSInteger)shouldEditTableColumn:(NSTableColumn *)tc item:(id)item
{
	if([[tc identifier] compare:COLUMNID_SLOT] == NSOrderedSame) 
		return YES;	
	
	if([[tc identifier] compare:COLUMNID_NAME] == NSOrderedSame) {
		if( ![[item nodeData] location] ) return NO;
		return YES;
	}
	
	if([[tc identifier] compare:COLUMNID_COMMENT] == NSOrderedSame) 
		return YES;	

	if([[tc identifier] compare:COLUMNID_TAGS] == NSOrderedSame) 
		return YES;	

	if([[tc identifier] compare:COLUMNID_STARS] == NSOrderedSame) 
		return YES;	

	return NO;
}

- (void)doubleClickImage:(id)item inCell:(NSCell*)cell
{
	SimpleNodeData	*theData = [item nodeData];
//	DACALDeviceRef	theBox = [theData itemDevice];
//	DACALSlotNum	theSlot = [theData itemSlot];

//	DACALCommandMoveToSlotWithOptions( theBox, theSlot, kDACALOptionMoveToggle );

	[[[theData itemElement] elementSlot] toggleReservationForUser:nil onHost:nil];
	
}

- (void)doubleClickCellContent:(id)item inCell:(NSCell*)cell
{
	SimpleNodeData	*theData = [item nodeData];
	NSOutlineView	*theView = [[self treeControl] outlineView];
	
	if( [theView clickedColumn] == [theView columnWithIdentifier:COLUMNID_CHECKEDOUT] )
		[[[[item nodeData] itemElement] elementSlot] toggleReservationForUser:nil onHost:nil];
	else if( [theView clickedColumn] == [theView columnWithIdentifier:COLUMNID_DATECHECKEDOUT] )
		[[[[item nodeData] itemElement] elementSlot] toggleReservationForUser:nil onHost:nil];
	else if( [theView clickedColumn] == [theView columnWithIdentifier:COLUMNID_TAGS] )
		[theView editColumn:[theView clickedColumn] row:[theView clickedRow] withEvent:[[NSApplication sharedApplication] currentEvent] select:YES];
	else 	
	{	
		if([theData isExpandable] == YES ) 
			if( [theView isItemExpanded:item] == YES ) {
				[theView collapseItem:item];
			} else {
				[theView expandItem:item];
			}
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
		
		if( [keyPath hasSuffix:@"PADColumnCheckedOut"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_CHECKEDOUT];
			workKey = @"PADColumnCheckedOut";
		}

		if( [keyPath hasSuffix:@"PADColumnDateCheckedOut"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_DATECHECKEDOUT];
			workKey = @"PADColumnDateCheckedOut";
		}

		if( [keyPath hasSuffix:@"PADColumnComments"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_COMMENT];
			workKey = @"PADColumnComments";
		}

		if( [keyPath hasSuffix:@"PADColumnTags"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_TAGS];
			workKey = @"PADColumnTags";
		}

		if( [keyPath hasSuffix:@"PADColumnRating"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_STARS];
			workKey = @"PADColumnRating";
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

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	NSArray*		clickedItems = [self ctmClickedRows];
	NSEnumerator*	clickedEnum = [clickedItems objectEnumerator];
    NSInteger		clickedRow = [[self outlineView] clickedRow];
	
    id				item = nil;
    SimpleNodeData*	nodeData = nil;
	
	NSMenuItem*		workItem = nil;
	SEL				workSelector = nil;
	NSInteger		itemCount = [menu numberOfItems];
	
    if( clickedRow != -1 ) 
        item = [[self outlineView] itemAtRow:clickedRow];
     else 
		item = [clickedItems objectAtIndex:0];
	
	nodeData = [item nodeData];
    
    if (menu == outlineViewContextMenu) 
	{
		while( workItem = (NSMenuItem*)[clickedEnum nextObject] )
		{
			workSelector = [workItem action];
			if( workSelector == @selector(ctmMountOpen:) )						//	Mount & Open
				[workItem setEnabled:NO];	// ![nodeData isCheckedOut]
			if( workSelector == @selector(ctmCheckIn:) )						//	Check In
				[workItem setEnabled:[nodeData isCheckedOut]];
			if( workSelector == @selector(ctmCheckOut:) )						//	Check Out
				[workItem setEnabled:![nodeData isCheckedOut]];
		}
	}
	
}

- (IBAction)ctmMountOpen:(id)sender
{
	NSLog(@"Mount and Open: Unimplemented feature!");	
}

- (IBAction)ctmCheckIn:(id)sender
{
	NSArray*		theItems = [self ctmClickedRows];
	NSEnumerator*	arrayEnum = [theItems objectEnumerator];
	SimpleTreeNode*	workItem = nil;
	
	while( workItem = [arrayEnum nextObject] )
	{
		if( [workItem respondsToSelector:@selector(matchActual)] )
			workItem = [(SearchNodeData*)workItem matchActual];
		
		if( [[[workItem nodeData] itemElement] isCheckedOut] == YES )
			[[[[workItem nodeData] itemElement] elementSlot] toggleReservationForUser:nil onHost:nil];
	}
}

- (IBAction)ctmCheckOut:(id)sender
{
	NSArray*		theItems = [self ctmClickedRows];
	NSEnumerator*	arrayEnum = [theItems objectEnumerator];
	SimpleTreeNode*	workItem = nil;
	
	while( workItem = [arrayEnum nextObject] )
	{
		if( [workItem respondsToSelector:@selector(matchActual)] )
			workItem = [(SearchNodeData*)workItem matchActual];
		
		if( [[[workItem nodeData] itemElement] isCheckedOut] == NO )
			[[[[workItem nodeData] itemElement] elementSlot] toggleReservationForUser:nil onHost:nil];
	}
}

- (IBAction)ctmDeleteSlot:(id)sender
	{ [[[AppController shared] toolbarControl] unassignNodes:[self ctmClickedRows]]; }

@end	// DACALViewDataSource


