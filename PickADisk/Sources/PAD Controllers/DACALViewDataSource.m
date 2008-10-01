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
	
	[toolControl setSelectedNode:nil];
	
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
	[self updatePrompt];
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


