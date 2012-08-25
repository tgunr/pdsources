/*
	PADOutlineView.m
	Copyright (c) 2001-2006, Apple Computer, Inc., all rights reserved.
	Author: Chuck Pisula

        NSOutlineView category (PMExtensions), and subclass (PADOutlineView)
*/

#import "TreeController.h"
#import "PADOutlineView.h"
#import "PADSearchRequest.h"
#import <PMUtility/PMUtility.h>

@implementation PADOutlineView

- (id)selectedItem { 
    return [self itemAtRow: [self selectedRow]]; 
}

- (NSArray *)allSelectedItems {
    NSMutableArray *items = [NSMutableArray array];
    NSEnumerator *selectedRows = [self selectedRowEnumerator];
    NSNumber *selRow = nil;
    while( (selRow = [selectedRows nextObject]) ) {
        if ([self itemAtRow:[selRow integerValue]]) 
            [items addObject: [self itemAtRow:[selRow integerValue]]];
    }
    return items;
}

- (NSArray *)allSelectedNodes {
    NSMutableArray *items = [NSMutableArray array];
    NSEnumerator *selectedRows = [self selectedRowEnumerator];
    NSNumber *selRow = nil;
	SimpleTreeNode* selItem = nil;
	
    while( (selRow = [selectedRows nextObject]) ) {
		selItem = [self itemAtRow:[selRow integerValue]];
        if (selItem) 
            [items addObject: [selItem matchActual]];
    }
	//NSLog(@"Items: %@", items);
    return items;
}

- (void)selectItems:(NSArray *)items byExtendingSelection:(BOOL)extend {
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
    NSUInteger i, totalCount = [items count];
#else
	int i, totalCount = [items count];
#endif
    if (extend==NO) [self deselectAll:nil];
    for (i = 0; i < totalCount; i++) {
		NSInteger row = [self rowForItem:[items objectAtIndex:i]];
        if(row>=0) [self selectRow: row byExtendingSelection:YES];
    }
}

- (void)selectNodes:(NSArray *)items byExtendingSelection:(BOOL)extend {
    NSUInteger i, totalCount = [self numberOfRows];
	SimpleTreeNode*		actualItem = nil;
	NSMutableArray*		itemsLeft = [NSMutableArray arrayWithCapacity:[items count]];
	
	[itemsLeft addObjectsFromArray:items];
    if (extend==NO) [self deselectAll:nil];

    for (i = 0; i < totalCount; i++) {
		if( [itemsLeft count] == 0 ) break;
		if( i > [self numberOfRows] ) {
			NSLog(@"number changed!");
			break;
		}
		actualItem = [[self itemAtRow:i] matchActual];
//		NSLog(@"Actual Item: %@", actualItem);
		
		if( [itemsLeft indexOfObject:actualItem] != NSNotFound ) {
			[itemsLeft removeObject:actualItem];
			[self selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:YES];
			//NSLog(@"Actual Item: %@", actualItem);
		}
    }
}

- (void)selectItems:(NSArray*)items
	{ [self selectItems:items byExtendingSelection:NO]; }

- (void)extendSelectItems:(NSArray*)items
	{ [self selectItems:items byExtendingSelection:YES]; }

- (void)autoExpandItemAndChildren:(id)item
{
	if( item == nil )
		item = [[self dataSource] treeRoot];
	
	if( [[(SimpleTreeNode*)item nodeData] isExpanded] )
	{
		NSArray*		theKids = [(SimpleTreeNode*)item children];
		NSEnumerator*	kidEnum = [theKids objectEnumerator];
		SimpleTreeNode*	thisKid = nil;
		
		while ( thisKid = (SimpleTreeNode*)[kidEnum nextObject] )
			if( [[thisKid nodeData] isExpanded] == YES )
				[self autoExpandItemAndChildren:thisKid];
		
		[self expandItem:item];
	}
}


-(PADSearchRequest*)currentSearch
	{ return currentSearch; }

-(void)setCurrentSearch:(PADSearchRequest*)newSearch
{
	if( currentSearch == newSearch ) return;
	if( newSearch != nil ) [newSearch retain];
	if( currentSearch != nil ) [currentSearch release];
	currentSearch = newSearch;
	
	//if( currentSearch && [currentSearch searchResultsDirty] && ![currentSearch searchBusy] )
		//[currentSearch startSearch];
//	NSLog(@"View Search: %@", newSearch);
}

-(void)dealloc
{
	[self setCurrentSearch:nil];
	
	[[PADSearchService sharedSearch] removeActiveWatcher:self];
	
	[super dealloc];
}

// TODO: 2012-08-25 This needs to be looked at. Causing severe delay as it goes thru every node, outlineViewAction is called over 100000 times
-(void)reloadData
{
	
	PADSearchRequest*	ourSearch = [self currentSearch];
	NSArray*			saveSelection = nil;

	if( ourSearch != nil ) {
		NSLog(@"Our Search: %@", ourSearch);
		saveSelection = [self allSelectedNodes];
		[super reloadData];
		[self selectNodes:saveSelection byExtendingSelection:NO];
	} else {
		saveSelection = [self allSelectedItems];
		[super reloadData];
		[self selectItems:saveSelection byExtendingSelection:NO];
	}
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if( self = [super initWithCoder:decoder] ) {
		[[PADSearchService sharedSearch] addActiveWatcher:self];
	}
	
	return self;
}

-(void)searchDataChanged:(NSArray*)theItems
{
	PADSearchRequest*	ourSearch = [self currentSearch];
	
	if( ourSearch != nil )
	{
		if( ![ourSearch searchBusy] ){
			[ourSearch startSearch];
			// NSLog(@"Research: %@", ourSearch);
		}
		// NSLog(@"Busy: %@", ourSearch);
	}
//	NSLog(@"No Search?: %@", self);

}

-(void)searchStarted:(PADSearchRequest*)newSearch
{
	PADSearchRequest*	ourSearch = [self currentSearch];
	
	if( ourSearch == newSearch )
	{
		if( [ourSearch searchOriginalSelection] == nil ) {
			[ourSearch setSearchOriginalSelection:[self allSelectedNodes]];
			// NSLog(@"Selected Nodes: %@", [ourSearch searchOriginalSelection]);
		}
		//[self reloadData];
	}

//	NSLog(@"Search Started: %@", ourSearch);

}

-(void)searchFinished:(PADSearchRequest*)newSearch
{
	PADSearchRequest*	ourSearch = [self currentSearch];
	
	if( ourSearch == newSearch )
	{
		[self reloadData];
		if( [ourSearch searchOriginalSelection] != nil )
		{
			[self selectNodes:[ourSearch searchOriginalSelection] byExtendingSelection:NO];
			[ourSearch setSearchOriginalSelection:nil];
		}
	}
//	NSLog(@"Search Finished: %@", ourSearch);
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {

	BOOL isValid = YES;
	
	if( [[self delegate] respondsToSelector:@selector(validateMenuItem:)] )
		isValid = (BOOL)[[self delegate] validateMenuItem:menuItem];
	else
        isValid = [super validateMenuItem:menuItem];
	
	return isValid;
}

// This NSOutlineView subclass is necessary only if you want to delete items by dragging them to the trash.  
// In order to support drags to the trash, you need to implement draggedImage:endedAt:operation: and handle the NSDragOperationDelete operation.  
// For any other operation, pass the message to the superclass

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	
	if( [[self delegate]
         respondsToSelector:@selector(draggedImage:endedAt:operation:)] )
	   [[self delegate] draggedImage:image endedAt:screenPoint operation:operation];
	else {
        [super draggedImage:image endedAt:screenPoint operation:operation];
    }
}

@end		// PADOutlineView

