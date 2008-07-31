//
//  PADSearchRequest.h
//  PickADisc
//
//  Created by Jack Small on 7/30/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PADSearchRequest : NSObject {

	NSArray*	searchLocations;
	NSString*	searchTerm;
	NSString*	searchOptions;
	
	BOOL		searchingNow;
	NSTask*		searchWork;
	NSArray*	searchResults;
	int			searchError;
}

-(void)startSearch;

-(id)initSearchInLocations:(NSArray*) inLocs forTerm:(NSString*)inTerm withOptions:(NSString*)inOptions;

+(id)searchCarouselsForTerm:(NSString*)inTerm withOptions:(NSString*)inOptions;

@end
