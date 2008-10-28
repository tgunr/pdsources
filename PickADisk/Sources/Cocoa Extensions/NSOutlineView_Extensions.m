/*
	NSOutlineView_Extensions.m
	Copyright (c) 2001-2006, Apple Computer, Inc., all rights reserved.
	Author: Chuck Pisula

        NSOutlineView category (MyExtensions), and subclass (MyOutlineView)
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "TreeController.h"
#import "NSOutlineView_Extensions.h"

@implementation NSOutlineView(MyExtensions)

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

@end

@implementation MyOutlineView

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

-(void)reloadData
{
	NSArray*			saveSelection = [self allSelectedItems];

	[super reloadData];

	[self selectItems:saveSelection byExtendingSelection:NO];
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
	}
//	NSLog(@"Search Finished: %@", ourSearch);
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {

	BOOL isValid = YES;
	
	if( [[self delegate] respondsToSelector:@selector(validateMenuItem:)] )
		isValid = [[self delegate] validateMenuItem:menuItem];
	else
        isValid = [super validateMenuItem:menuItem];
	
	return isValid;
}

// This NSOutlineView subclass is necessary only if you want to delete items by dragging them to the trash.  
// In order to support drags to the trash, you need to implement draggedImage:endedAt:operation: and handle the NSDragOperationDelete operation.  
// For any other operation, pass the message to the superclass

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	
	if( [[self delegate] respondsToSelector:@selector(draggedImage:endedAt:operation:)] )
	   [[self delegate] draggedImage:image endedAt:screenPoint operation:operation];
	else {
        [super draggedImage:image endedAt:screenPoint operation:operation];
    }
}

@end		// MyOutlineView

