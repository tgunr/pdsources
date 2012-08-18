//
//  PADPrefsTreeController.m
//  PickADisk
//
//  Created by Jack Small on 10/14/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "PADPrefsTreeController.h"

@implementation PADPrefsTreeController
static PADPrefsTreeController *PADPrefsTreeController_shared;

- (id)init
{
    if (PADPrefsTreeController_shared) 
	{
        [self autorelease];
        return PADPrefsTreeController_shared;
    }
	if (self = [super init]) 
	{
		PADPrefsTreeController_shared = self;
	}
	return self;
}

+ (id)sharedPrefsTree;
{
    if (!PADPrefsTreeController_shared) {
        [[PADPrefsTreeController alloc] init];
    }
    return PADPrefsTreeController_shared;
}

-(NSMutableDictionary*)itemInfo
	{ return itemInfo; }


- (SimpleTreeNode*)createInitialTree:(id)tree
{
	SimpleTreeNode*		theOutputTree = nil;
//	SimpleTreeNode*		theGroupNode = nil;
	IndexNodeData*		theWorkData = nil;
	NSArray*			tempChildren = nil;
	
	[tree setAllowGroupRowLook:YES];
	
	// Load our initial outline view data from the "InitInfo" dictionary.
	NSDictionary *initData = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"InitInfo" ofType: @"dict"]];
	if( initData != nil ) theOutputTree = [SimpleTreeNode treeIndexFromDictionary: initData];	
	
	[[theOutputTree childWithName:PADINDEX_GROUPTITLE_DEVICES] removeFromParent];
	[[theOutputTree childWithName:PADINDEX_GROUPTITLE_FAVORITES] removeFromParent];

	[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] nodeData] setItemType:kPADTypeGroupLibrary];
	
	//[[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_FILES] nodeData] setItemType:kPADTypeGroupLibrary]; //kPADTypeDataFiles];
	theWorkData = (IndexNodeData*)[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_FILES] nodeData];
	[theWorkData setItemFlavor:PADINDEX_GROUPTITLE_LIBRARY];
	[theWorkData setItemType:kPADTypeDataFiles];
	
	theWorkData = (IndexNodeData*)[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_IMAGE] nodeData];
	[theWorkData setItemType:kPADTypeDataImage];
	[theWorkData setItemFlavor:PADINDEX_GROUPTITLE_LIBRARY];
	
	theWorkData = (IndexNodeData*)[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_MUSIC] nodeData];
	[theWorkData setItemType:kPADTypeDataMuisc];
	[theWorkData setItemFlavor:PADINDEX_GROUPTITLE_LIBRARY];
	
	theWorkData = (IndexNodeData*)[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] childWithName:PADINDEX_FLAVORTITLE_MOVIE] nodeData];
	[theWorkData setItemType:kPADTypeDataMovie];
	[theWorkData setItemFlavor:PADINDEX_GROUPTITLE_LIBRARY];

	tempChildren = [[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] children];
	[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] removeChildrenIdenticalTo:tempChildren];
	[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY] nodeData] setExpandable:NO];
	[theOutputTree insertChildren:tempChildren atIndex:[theOutputTree indexOfChild:[theOutputTree childWithName:PADINDEX_GROUPTITLE_LIBRARY]]+1];
	
	tempChildren = [[theOutputTree childWithName:PADINDEX_GROUPTITLE_SEARHCES] children];
	[[theOutputTree childWithName:PADINDEX_GROUPTITLE_SEARHCES] removeChildrenIdenticalTo:tempChildren];
	[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_SEARHCES] nodeData] setExpandable:NO];
	
	{
		NSEnumerator*	tempEnum = [tempChildren objectEnumerator];
		SimpleTreeNode*	item = nil;
		
		while( item = [tempEnum nextObject] )
			[[item nodeData] setItemFlavor:PADINDEX_GROUPTITLE_SEARHCES];
	}
	
	[theOutputTree insertChildren:tempChildren atIndex:[theOutputTree indexOfChild:[theOutputTree childWithName:PADINDEX_GROUPTITLE_SEARHCES]]+1];
	
	return [theOutputTree retain];
}

- (void)outlineViewInit
{
	[super outlineViewInit];
	//[[self treeControl] setAllowOnDropOnLeaf:YES]; 
	//[[self treeControl] setAllowOnDropOnGroup:YES];
	
	NSDictionary*	existingInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"PADPrefsTreeIndexAvailability"];
	
	itemInfo = [[NSMutableDictionary alloc] initWithCapacity:0];
	
	if( existingInfo != nil )
		[itemInfo addEntriesFromDictionary:existingInfo];
	
	[[[self treeControl] outlineView] expandItem:nil expandChildren:YES];
}

-(id)objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    id				objectValue = nil;
	NSString*		groupName = nil;
	NSDictionary*	groupDict = nil;
	NSString*		itemName = nil;
	NSNumber*		itemValue = nil;
	BOOL			itemCheck = NO;
	
    if ((tableColumn != nil) && [[tableColumn identifier] isEqualToString:COLUMNID_PREFSCHECKBOX]) {
		groupName = [[item nodeData] itemFlavor];
		itemName = [[item nodeData] name];
		
		if( itemInfo != nil )
			groupDict = [itemInfo objectForKey:groupName];
		
		if( groupDict != nil )
			itemValue = [groupDict objectForKey:itemName];
		
		if( itemValue != nil )
			itemCheck = [itemValue boolValue];
		else
			itemCheck = YES;
		
		objectValue = [NSNumber numberWithBool:itemCheck];
	} else
		objectValue = [super objectValueForTableColumn:tableColumn byItem:item];
	
	return objectValue;
}

-(void)setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    // Here, we manipulate the checked data stored in the itemInfo attribute.
    if ((tableColumn != nil) && [[tableColumn identifier] isEqualToString:COLUMNID_PREFSCHECKBOX]) {
		
		NSMutableDictionary*	groupDict = [itemInfo objectForKey:[[item nodeData] itemFlavor]];
		
		if( groupDict == nil )
			groupDict = [NSMutableDictionary dictionaryWithCapacity:0];
				
		[groupDict setObject:object forKey:[[item nodeData] name]];
		[itemInfo setObject:groupDict forKey:[[item nodeData] itemFlavor]];
		[[NSUserDefaults standardUserDefaults] setObject:itemInfo forKey:@"PADPrefsTreeIndexAvailability"];
		
		// reflect now
		[[[DACALTreeDataSource shared] treeControl] recreateInitialTree];

		return;
	}
	
	[super setObjectValue:object forTableColumn:tableColumn byItem:item];
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldExpandItem:(id)item
{
	return NO;
    return [super outlineView:ov shouldExpandItem:item];
}

-(BOOL)outlineView:(NSOutlineView*)ov shouldCollapseItem:(id)item
{
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item
{
    return NO;
}

- (BOOL)outlineView:ov isGroupItem:(id)item
{
	return [super outlineView:ov isGroupItem:item];
	
    if( [[[item nodeData] name] compare:PADINDEX_GROUPTITLE_LIBRARY] == NSOrderedSame ) {
		NSLog(@"Item Name:%@", [[item nodeData] name]);
		return YES;
	}
    if( [[[item nodeData] name] compare:PADINDEX_GROUPTITLE_SEARHCES] == NSOrderedSame )
		return YES;

	return NO;
}

- (IBAction)restoreTreeIndexPrefs:(id)sender
{
	//	Remove pref settings
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PADMainSidebarOrder"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PADPrefsTreeIndexAvailability"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	//	Reflect here
	[itemInfo removeAllObjects];
	[[self outlineView] reloadData];
	
	//	Reflect now
	[[[DACALTreeDataSource shared] treeControl] recreateInitialTree];
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{

}

- (void)dealloc {
	[itemInfo release];
	[super dealloc];
}

@end
