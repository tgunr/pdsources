//
//  PADSearchRequest.m
//  PickADisc
//
//  Created by Jack Small on 7/30/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "PADSearchRequest.h"


@implementation PADSearchRequest

-(void)dealloc
{
	if( searchLocations!= nil ) [searchLocations release];
	if( searchTerm!= nil ) [searchTerm release];
	if( searchOptions!= nil ) [searchOptions release];
	if( searchWork!= nil ) [searchWork release];
	
	searchLocations = nil;
	searchTerm = nil;
	searchOptions = nil;
	searchWork = nil;
	searchingNow = NO;
	
	[super dealloc];
}

-(void)startSearch
{
//	NSTask*		workTask =nil;	
}

	
- (void)taskDidEnd:(NSNotification*)aNotice
{
	if( [aNotice object] != searchWork ) return;
	
	searchError = [[aNotice object] terminationStatus];
	
}
	


-(id)initSearchInLocations:(NSArray*) inLocs forTerm:(NSString*)inTerm withOptions:(NSString*)inOptions
{
	if( self = [super init] ) 
	{
		searchLocations = inLocs;
		searchTerm = inTerm;
		searchOptions = inOptions;
		searchingNow = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(taskDidEnd:)
													 name:NSTaskDidTerminateNotification
												   object:nil];
		
	}
	return self;
}

+(id)searchCarouselsForTerm:(NSString*)inTerm withOptions:(NSString*)inOptions
{
	PADSearchRequest*	newMe = [PADSearchRequest alloc];
	
	[newMe initSearchInLocations:nil forTerm:inTerm withOptions:inOptions];
	
	return newMe;
}


@end
