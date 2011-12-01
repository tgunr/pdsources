//
//  DACALIndexState.m
//  PickADisk
//
//  Created by Dave Carlton on 06/24/11.
//  Copyright 2011 Polymicro Systems. All rights reserved.
//

//#import "DACALIndexState.h"


@implementation DACALIndexState

-(id)init
{
	if (self = [super init]) {
		savedViewData = [[NSMutableDictionary alloc] initWithCapacity: 2];
	}
	return self;
}

-(void)dealloc
{
	if (savedViewData) [savedViewData release];
	savedViewData = nil;
	
	[super dealloc];
}

-(void)restoreSettingsForKey: (NSString *) keyName
{
	NSOutlineView * theView = [[savedViewData objectForKey: keyName] objectForKey: @"View"];
	NSIndexSet    * theIndex = [[savedViewData objectForKey: keyName] objectForKey: @"Selection"];
	NSArray       * theSorts = [[savedViewData objectForKey: keyName] objectForKey: @"Sorts"];
	
	if ([theView isKindOfClass: [NSOutlineView class]]) {
		if (theSorts) [theView setSortDescriptors: theSorts];
		if (theIndex) [theView selectRowIndexes: theIndex byExtendingSelection: NO];
	}
}

-(void)restoreSettings
{
	NSString     * theKey = nil;
	NSEnumerator * keyList = [savedViewData keyEnumerator];
	
	while ( (theKey = (NSString *)[keyList nextObject]) )
		[self restoreSettingsForKey: theKey];
}

-(void)removeSetting: (NSString *) settingName forKey: (NSString *) keyName
{
	NSMutableDictionary * itemDict = [savedViewData objectForKey: keyName];
	
	if (itemDict) {
		if (settingName != nil)
			[itemDict removeObjectForKey: settingName];
		else
			[savedViewData removeObjectForKey: keyName];
	}
}

-(void)addSettingsForKey: (NSString *) keyName saveView: (NSOutlineView *) doView saveSelection: (BOOL) doSelect saveSorts: (BOOL) doSorts
{
	NSIndexSet          * theIndex = (doSelect == YES) ? [doView selectedRowIndexes] : nil;
	NSArray             * theSorts = (doSorts == YES)  ? [doView sortDescriptors] : nil;
	NSMutableDictionary * theData = [NSMutableDictionary dictionaryWithCapacity: 4];
	
	[theData setObject: doView forKey: @"View"];
	if (theIndex)
		[theData setObject: theIndex forKey: @"Selection"];
	if (theSorts)
		[theData setObject: theSorts forKey: @"Sorts"];
	
	[savedViewData setObject: theData forKey: keyName];
}

+(id)saveSetupForKey: (NSString *) keyName saveView: (NSOutlineView *) doView saveSelection: (BOOL) doSelect saveSorts: (BOOL) doSorts
{
	DACALIndexState * newState = [[DACALIndexState alloc] init];
	
	[newState addSettingsForKey: keyName saveView: doView saveSelection: doSelect saveSorts: doSorts];
	
	return newState;
}

@end    // DACALIndexState
