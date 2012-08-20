//
// Created by davec on 8/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "DACALSlotElementBookmark.h"
#import "DACALDeviceObjC.h"
#import "TreeController.h"
#import "DACALTreeDataSource.h"
#import "/Volumes/data/Sources/Projects/PickADisk/Sources/pmssource/carlib/dacalconstants.h"
#import "DACALSlotElement.h"
#import <PMUtility/pmNSUtility.h>

@implementation DACALSlotElementBookmark

-(void)dealloc
{
	if( markElement ) markElement = nil;
	if( markLocation ) [markLocation release];
	markLocation = nil;
	[self removeMarkNode];

	[super dealloc];
}

-(DACALSlotElement*)markElement { return markElement; }
-(NSString*)markLocation { return markLocation; }
-(SimpleTreeNode*)markNode { return markNode; }

-(BOOL)isBookmarkLocation:(NSString*)theLocation
	{ return( BooleanToBOOL([markLocation compare:theLocation] == NSOrderedSame) ); }

-(BOOL)removeBookmark
	{ return [markElement removeBookmarkForLocation:markLocation]; }

-(void)removeMarkNode
{
	if( markNode ) {
		if( [markNode nodeParent] != nil ) {
			[markNode removeFromParent];
			[[DACALTreeDataSource shared] updateChangesWithAction:YES];
		}
		markNode = nil;
	}
}

-(void)removeBookmarkForLocation
{
	[self removeMarkNode];
	[self autorelease];
}

-(id)initBookmarkForElement:(DACALSlotElement*)theElement atLocation:(NSString*)theLocation attachNow:(BOOL)doAttach
{
	self = [super init];
	if(self)
	{
		markElement = theElement;
		markLocation = theLocation;

		SimpleTreeNode* newMark = (SimpleTreeNode*)[SimpleTreeNode nodeDataWithURL:[theElement elementURL]];
		SimpleTreeNode* newMarkTree = (SimpleTreeNode*)[SimpleTreeNode treeOperationFromLocation:[theElement elementURL] forUI:YES];
		[[newMark nodeData] setItemElement:theElement];
		[[newMark nodeData] setSubTree:newMarkTree];
		[[newMark nodeData] setIsLeaf:YES];
		[[newMark nodeData] setExpandable:NO];
		[[newMark nodeData] setItemType:kPADTypeIndexFavorites];
		[[newMarkTree nodeData] setItemElement:theElement];

		markNode = newMark;

		if( doAttach == YES )
			if( [theLocation compare:kDACBookmarkLocationInSidebar] == NSOrderedSame ) {
				SimpleTreeNode* workNode = [[[[DACALTreeDataSource shared] treeControl] treeRoot] childWithName:PADINDEX_GROUPTITLE_FAVORITES];
				[workNode insertChild:(TreeNode*)markNode atIndex:[workNode numberOfChildren]];
				[[DACALTreeDataSource shared] orderForUser:nil];
				[[[[DACALTreeDataSource shared] treeControl] outlineView] reloadItem:workNode reloadChildren:YES];
			} else
				NSLog(@"Unimplemented bookmark location: %@", theLocation);
	}
	return self;
}

+(id)bookmarkForElement:(DACALSlotElement*)theElement atLocation:(NSString*)theLocation attachNow:(BOOL)doAttach
	{ return [[DACALSlotElementBookmark alloc] initBookmarkForElement:theElement atLocation:theLocation attachNow:doAttach]; }

@end	//	DACALSlotElementBookmark
