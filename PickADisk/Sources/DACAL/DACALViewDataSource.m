//
//  DACALViewDataSource.m
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import "DACALViewDataSource.h"
#import "PADLifecycleSetup.h"

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
		NSString*	isCOString = nil;
		//NSString*	imagePath = nil;
		//NSImage*	theImage = nil;
		//NSBundle*	imageBundle = [NSBundle mainBundle];
		
		if( [Sdata isCheckedOut] ) {
			//if( imagePath = [imageBundle pathForResource:@"CheckedOut" ofType:@"png"] )		//	or redx.png?
			//	theImage = [[NSImage alloc] initByReferencingFile:imagePath]; 
			if( [[[Sdata itemElement] elementSlot] isSlotMounted] )
				isCOString = @"⏏";
			else
				isCOString = @"◎";
		}
		//objectValue = theImage;
		objectValue = isCOString;
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
	SimpleTreeNode*	actual = [item matchActual];
    
   // Here, we manipulate the slot data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_SLOT]) {
		[self nodeSlotChanged:actual toSlot:object];
		return;
	}
	
    // Here, we manipulate the type/flavor data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_TYPE]) {
		[self nodeTypeChanged:actual toType:object];
		return;
	}

	// Here, we manipulate the comment data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_COMMENT]) {
		[self nodeCommentChanged:actual toComment:object];
		return;
	}
	
	// Here, we manipulate the tag data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_TAGS]) {
		[self nodeTagsChanged:actual toTags:object];
		return;
	}

	// Here, we manipulate the stars data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_STARS]) {
		[self nodeStarsChanged:actual toStars:object];
		return;
	}
	
	[super setObjectValue:object forTableColumn:tableColumn byItem:item];
}


- (void)outlineViewAction:(id)tree
{
	NSArray*		selectedNodes = [NSArray arrayWithArray:[treeControl selectedNodes]];
	NSEnumerator*	selectedEnum = [selectedNodes objectEnumerator];
	SimpleTreeNode*	item = nil;
	int				count = [selectedNodes count];

	PADIndexToolbarController* toolControl = (PADIndexToolbarController*)[self toolbarControl];
	
	[toolControl resetSelectedNodesAndAdoptSelection:(count == 0)];
	
	while( item = [selectedEnum nextObject] )
		if( [[item nodeData] itemSlot] != 0 ) 
			[toolControl addSelectedNode:item adoptSelection:([item isEqual:[selectedNodes lastObject]])];

	[self updatePrompt];

	return;
}

- (void)nodeNameChanged:(SimpleTreeNode*)theNode toName:(NSString*)theName
{
	NSUndoManager*		undo = [self undoManager];
	SimpleNodeData*		theData = [theNode nodeData];
	DACALSlotElement*	theElement = [theData itemElement]; //	DACALDeviceSlotElementForURL( (CFURLRef)[theData location] );
	NSString*			nowName = nil;
	
	if( [[theData name] compare:theName] == NSOrderedSame ) return;
	if( [theName length] == 0 ) goto SLOTNAMEFAILED;
	if( theElement == nil ) goto SLOTNAMEFAILED;
	
	nowName = [NSString stringWithString:[theData name]];
	
	[[undo prepareWithInvocationTarget:self] nodeNameChanged:theNode toName:nowName];
	[undo setActionName:NSLocalizedString(@"Change Name", @"Undo Action when name column is changed")];

	[theElement setTitle:theName];
	[[PADSearchService sharedSearch] searchDataChanged:[NSArray arrayWithObject:theNode]];
	
SLOTNAMEFAILED:
	
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
	NSUndoManager*	undo = [self undoManager];
//	SimpleNodeData*	theData = [node nodeData];
	DACALSlotNum	oldSlot = [[node nodeData] itemSlot];
	DACALSlotNum	newSlot = [slotString intValue];
	DACALDevice*	oldBox = DACALDeviceForDeviceRef( [[node nodeData] itemDevice] );
	NSString*		nowSlot = nil;
	
	if( oldSlot == newSlot ) return;
	
	nowSlot = [NSString stringWithFormat:@"%i", oldSlot];
	
	[[undo prepareWithInvocationTarget:self] nodeSlotChanged:node toSlot:nowSlot];
	[undo setActionName:NSLocalizedString(@"Change Slot", @"Undo Action when slot number column is changed")];
	
	[oldBox swapSlotNumber:oldSlot toDevice:nil toSlotNumber:newSlot];
	[[PADSearchService sharedSearch] searchDataChanged:[NSArray arrayWithObject:node]];
}

- (void)nodeTypeChanged:(SimpleTreeNode*)theNode toType:(NSString*)theName
{
	NSUndoManager*		undo = [self undoManager];
	SimpleNodeData*		theData = [theNode nodeData];
	DACALSlotElement*	theElement = [theData itemElement];	// DACALDeviceSlotElementForURL( (CFURLRef)[theData location] );
	NSString*			nowType = nil;
	
	if( [[theData itemFlavor] compare:theName] == NSOrderedSame ) return;
	if( [theName length] == 0 ) goto SLOTNAMEFAILED;
	if( theElement == nil ) goto SLOTNAMEFAILED;
	
	nowType = [NSString stringWithString:[theData itemFlavor]];
	
	[[undo prepareWithInvocationTarget:self] nodeTypeChanged:theNode toType:nowType];
	[undo setActionName:NSLocalizedString(@"Change Type", @"Undo Action when flavor type column is changed")];
	
	[theElement setFlavor:theName];
	[[PADSearchService sharedSearch] searchDataChanged:[NSArray arrayWithObject:theNode]];
	
SLOTNAMEFAILED:
	
	return;
}

- (void)nodeCommentChanged:(SimpleTreeNode*)theNode toComment:(NSString*)theComment
{
	NSUndoManager*	undo = [self undoManager];
	SimpleNodeData*	data = [theNode nodeData];
	NSString*		nowActual = [data keyComments];
	NSString*		nowComment = (nowActual != nil) ? [NSString stringWithString:nowActual] : nil;
	
	[[undo prepareWithInvocationTarget:self] nodeCommentChanged:theNode toComment:nowComment];
	[undo setActionName:NSLocalizedString(@"Change Comment", @"Undo Action when comment column is changed")];
	
	[data setKeyComments:theComment];
	[[PADSearchService sharedSearch] searchDataChanged:[NSArray arrayWithObject:theNode]];
}

- (void)nodeTagsChanged:(SimpleTreeNode*)theNode toTags:(NSArray*)theTags
{
	NSUndoManager*	undo = [self undoManager];
	SimpleNodeData*	data = [theNode nodeData];
	NSArray*		nowTags = nil;
	
	if( [data keyTags] )
		nowTags = [NSArray arrayWithArray:[data keyTags]];
	else
		nowTags = [NSArray array];
	
	[[undo prepareWithInvocationTarget:self] nodeTagsChanged:theNode toTags:nowTags];
	[undo setActionName:NSLocalizedString(@"Change Tags", @"Undo Action when tags column is changed")];
	
	[data setKeyTags:theTags];
	[[PADSearchService sharedSearch] searchDataChanged:[NSArray arrayWithObject:theNode]];
}

- (void)nodeStarsChanged:(SimpleTreeNode*)theNode toStars:(id)theRating
{
	NSUndoManager*	undo = [self undoManager];
	SimpleNodeData*	data = [theNode nodeData];
	NSInteger		newStars = [theRating intValue];
	NSNumber*		nowStars = [NSNumber numberWithInt:[data keyStars]];
	
	[[undo prepareWithInvocationTarget:self] nodeStarsChanged:theNode toStars:nowStars];
	[undo setActionName:NSLocalizedString(@"Change Rating", @"Undo Action when stars column is changed")];
	
	[data setKeyStars:newStars];
	[[PADSearchService sharedSearch] searchDataChanged:[NSArray arrayWithObject:theNode]];
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
		return NO;	

	if([[tc identifier] compare:COLUMNID_TAGS] == NSOrderedSame) 
		return NO;	

	if([[tc identifier] compare:COLUMNID_STARS] == NSOrderedSame) 
		return YES;	

	return NO;
}

- (void)doubleClickToggleItemReservation:(id)item
{
	// Allow power users to goto slots with option key
	
	if( [[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSAlternateKeyMask ) {
		[DACALSlot moveDevicesToSlotsOfNodes:[NSArray arrayWithObject:item]];
		return;
	}
	
	if( [[[[item nodeData] itemElement] elementSlot] isSlotMounted] && ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSCommandKeyMask) )
		[[[item nodeData] itemElement] openMountedElement];
	else
		[[[[item nodeData] itemElement] elementSlot] toggleReservationForUser:nil onHost:nil withUI:YES];
}

- (void)doubleClickImage:(id)item inCell:(NSCell*)cell
	{ [self doubleClickToggleItemReservation:item]; }

- (void)doubleClickCellContent:(id)item inCell:(NSCell*)cell
{
	SimpleNodeData	*theData = [item nodeData];
	NSOutlineView	*theView = [[self treeControl] outlineView];
	
	if( [theView clickedColumn] == [theView columnWithIdentifier:COLUMNID_CHECKEDOUT] )
		[self doubleClickToggleItemReservation:item];
	else if( [theView clickedColumn] == [theView columnWithIdentifier:COLUMNID_DATECHECKEDOUT] )
		[self doubleClickToggleItemReservation:item];
//	else if( [theView clickedColumn] == [theView columnWithIdentifier:COLUMNID_TAGS] )
//		[theView editColumn:[theView clickedColumn] row:[theView clickedRow] withEvent:[[NSApplication sharedApplication] currentEvent] select:YES];
	else 	
	{	
		if([theData isExpandable] == YES ) {
			if( [[[[item nodeData] itemElement] elementSlot] isSlotMounted] && ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSCommandKeyMask) )
					[[[item nodeData] itemElement] openMountedElement];
			else if( [theView isItemExpanded:item] == YES ) {
				[theView collapseItem:item];
			} else {
				[theView expandItem:item];
			}
		} else {
			if( [[[[item nodeData] itemElement] elementSlot] isSlotMounted] )
				[[[item nodeData] itemElement] openMountedElement];
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
		NSString*			workName = nil;
		BOOL				isVisible = NO;
		
		if( [keyPath hasSuffix:@"PADColumnDateAdded"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_MODDATE];
			workKey = @"PADColumnDateAdded";
			workName = @"Date Added";
		}
		
		if( [keyPath hasSuffix:@"PADColumnSlotNum"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_SLOT];
			workKey = @"PADColumnSlotNum";
			workName = @"Slot Number";
		}
		
		if( [keyPath hasSuffix:@"PADColumnSlotType"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_TYPE];
			workKey = @"PADColumnSlotType";
			workName = @"Type";
		}
		
		if( [keyPath hasSuffix:@"PADColumnCheckedOut"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_CHECKEDOUT];
			workKey = @"PADColumnCheckedOut";
			workName = @"Checked Out?";
		}

		if( [keyPath hasSuffix:@"PADColumnDateCheckedOut"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_DATECHECKEDOUT];
			workKey = @"PADColumnDateCheckedOut";
			workName = @"Check Out Date";
		}

		if( [keyPath hasSuffix:@"PADColumnComments"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_COMMENT];
			workKey = @"PADColumnComments";
			workName = @"Comments";
		}

		if( [keyPath hasSuffix:@"PADColumnTags"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_TAGS];
			workKey = @"PADColumnTags";
			workName = @"Tags";
		}

		if( [keyPath hasSuffix:@"PADColumnRating"] ) {
			workColumn = [[[self treeControl] outlineView] tableColumnWithIdentifier:COLUMNID_STARS];
			workKey = @"PADColumnRating";
			workName = @"Rating";
		}
		
		if( workKey ) isVisible = [[NSUserDefaults standardUserDefaults] boolForKey:workKey];
		if( workColumn ) {
			
			NSUndoManager*		undo = [self undoManager];
			NSUserDefaults*		defaults = [NSUserDefaults standardUserDefaults];
			BOOL				whichAction = [undo isUndoing] ? !isVisible : isVisible;					// Redo the other thing
			NSString*			actionName = whichAction ? @"Show" : @"Hide";
			NSString*			undoName = [NSString stringWithFormat:@"%@ %@", actionName, workName];		// All these should be localized!
			
			[[undo prepareWithInvocationTarget:defaults] setBool:!isVisible forKey:workKey];
			[undo setActionName:undoName];
			
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
//	NSEnumerator*	clickedEnum = [clickedItems objectEnumerator];
	NSEnumerator*	menuItemEnum = [[menu itemArray] objectEnumerator];
    NSInteger		clickedRow = [[self outlineView] clickedRow];
	
    id				item = nil;
    SimpleNodeData*	nodeData = nil;
	
	NSMenuItem*		workItem = nil;
	SEL				workSelector = nil;
	
    if( clickedRow != -1 ) 
        item = [[self outlineView] itemAtRow:clickedRow];
     else 
		item = [clickedItems objectAtIndex:0];
	
	nodeData = [item nodeData];
   
    if (menu == outlineViewContextMenu) 
	{
		while( workItem = (NSMenuItem*)[menuItemEnum nextObject] )
		{
			workSelector = [workItem action];
			//NSLog(@"Testing Item: %@", NSStringFromSelector(workSelector));
			
			if( workSelector == @selector(ctmMountOpen:) )						//	Mount & Open
				[workItem setEnabled:[nodeData isCheckedOut]];
			if( workSelector == @selector(ctmCheckIn:) )						//	Check In
				[workItem setEnabled:[nodeData isCheckedOut]];
			if( workSelector == @selector(ctmCheckOut:) )						//	Check Out
				[workItem setEnabled:![nodeData isCheckedOut]];
			if( workSelector == @selector(ctmGotoSlot:) )						//	Go To Slot
				[workItem setEnabled:YES];
			if( workSelector == @selector(ctmInspector:) )	{					//	Show/Hide Inspector
				[workItem setEnabled:[[PADInspectorController sharedInspector] validateContextualMenuItem:workItem withSelection:clickedItems]];
			}
		}
	}
	
}

- (IBAction)ctmMountOpen:(id)sender
{
	NSArray*		theItems = [self ctmClickedRows];
	NSEnumerator*	arrayEnum = [theItems objectEnumerator];
	SimpleTreeNode*	workItem = nil;
	
	while( workItem = [arrayEnum nextObject] )
	{
		workItem = [workItem matchActual];
		
		if( [[[workItem nodeData] itemElement] isCheckedOut] == YES )
			[[[workItem nodeData] itemElement] openMountedElement];
	}
}

- (IBAction)ctmCheckIn:(id)sender
{
	NSArray*		theItems = [self ctmClickedRows];
	NSEnumerator*	arrayEnum = [theItems objectEnumerator];
	SimpleTreeNode*	workItem = nil;
	
	while( workItem = [arrayEnum nextObject] )
	{
		workItem = [workItem matchActual];
		
		if( [[[workItem nodeData] itemElement] isCheckedOut] == YES )
			[[[[workItem nodeData] itemElement] elementSlot] toggleReservationForUser:nil onHost:nil withUI:YES];
	}
}

- (IBAction)ctmCheckOut:(id)sender
{
	NSArray*		theItems = [self ctmClickedRows];
	NSEnumerator*	arrayEnum = [theItems objectEnumerator];
	SimpleTreeNode*	workItem = nil;
	
	while( workItem = [arrayEnum nextObject] )
	{
		workItem = [workItem matchActual];
		
		if( [[[workItem nodeData] itemElement] isCheckedOut] == NO )
			[[[[workItem nodeData] itemElement] elementSlot] toggleReservationForUser:nil onHost:nil withUI:YES];
	}
}

- (IBAction)ctmDeleteSlot:(id)sender
	{ [[[AppController shared] toolbarControl] unassignNodes:[self ctmClickedRows]]; }

- (IBAction)ctmGotoSlot:(id)sender
	{ [DACALSlot moveDevicesToSlotsOfNodes:[self ctmClickedRows]]; }

- (IBAction)ctmEject:(id)sender
	{ [DACALSlot ejectSlotVolumesOfNodes:[self ctmClickedRows]]; }

- (IBAction)ctmInspector:(id)sender
	{ [[PADInspectorController sharedInspector] dispatchInspectorPanelTo:[sender title] withSelection:[self ctmClickedRows]]; }

@end	// DACALViewDataSource

NSImage*		DACALCreateImageRefForFlavor( NSString* flavorName )
{
	OSType			genericIconType = 'gFil';
	
	if( [(NSString*)PADINDEX_FLAVORVALUE_MUSIC compare:(NSString*)flavorName] == NSOrderedSame )
		genericIconType = 'gMus';				// CDAudioVolume
	else if( [(NSString*)PADINDEX_FLAVORVALUE_MOVIE compare:(NSString*)flavorName] == NSOrderedSame )
		genericIconType = 'gMov';				// public.dvd-media
	else if( [(NSString*)PADINDEX_FLAVORVALUE_IMAGE compare:(NSString*)flavorName] == NSOrderedSame )
		genericIconType = 'gImg';				// generic-image
	
	return( DACALGetIconImageForType(genericIconType) );
}


