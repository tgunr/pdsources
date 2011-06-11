//
//  PADSearchRequest.m
//  PickADisc
//
//  Created by Jack Small on 7/30/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "PADSearchRequest.h"
#import "NSString_Extensions.h"

// Default # of matches before notifying target
#define PADMATCHQUEUE_THRESHOLD		22

const	NSString*			kPADSearchByTitle				= @"Title";
const	NSString*			kPADSearchByTitleID					= @"com.polymicrosystems.pickadisk.searchterm.title";
const	NSString*			kPADSearchBySlot				= @"Slot";
const	NSString*			kPADSearchBySlotID					= @"com.polymicrosystems.pickadisk.searchterm.slot";
const	NSString*			kPADSearchByType				= @"Library Type";
const	NSString*			kPADSearchByTypeID					= @"com.polymicrosystems.pickadisk.searchterm.user.type";
const	NSString*			kPADSearchByDateAdded			= @"Date Added";
const	NSString*			kPADSearchByDateAddedID				= @"com.polymicrosystems.pickadisk.searchterm.date.added";
const	NSString*			kPADSearchByFileUTI				= @"File Type";
const	NSString*			kPADSearchByFileUTIID				= @"com.polymicrosystems.pickadisk.searchterm.uti.file";
const	NSString*			kPADSearchByDateCheckedOut		= @"Date Checked Out";
const	NSString*			kPADSearchByDateCheckedOutID		= @"com.polymicrosystems.pickadisk.searchterm.date.checkedout";
const	NSString*			kPADSearchByDateCheckedIn		= @"Date Checked In";
const	NSString*			kPADSearchByDateCheckedInID			= @"com.polymicrosystems.pickadisk.searchterm.date.checkedin";
const	NSString*			kPADSearchByDateCheckedInOut	= @"Date Checked In or Out";
const	NSString*			kPADSearchByDateCheckedInOutID		= @"com.polymicrosystems.pickadisk.searchterm.date.checkedinout";
const	NSString*			kPADSearchByComments			= @"User Comments";
const	NSString*			kPADSearchByCommentsID				= @"com.polymicrosystems.pickadisk.searchterm.user.comments";
const	NSString*			kPADSearchByTags				= @"User Tags";
const	NSString*			kPADSearchByTagsID					= @"com.polymicrosystems.pickadisk.searchterm.user.tags";
const	NSString*			kPADSearchByStars				= @"User Stars";
const	NSString*			kPADSearchByStarsID					= @"com.polymicrosystems.pickadisk.searchterm.user.stars";

const	PADSearchRelevance	kPADSearchWeightNormal			= 1.0;
const	PADSearchRelevance	kPADSearchWeightHalf			= 0.5;
const	PADSearchRelevance	kPADSearchWeightNone			= 0.0;

const	NSString*			kPADSearchTermKeyValue			= @"Value";
const	NSString*			kPADSearchTermKeyConjunction	= @"Conjunction";
const	NSString*			kPADSearchTermKeyOrder			= @"Order";
const	NSString*			kPADSearchTermKeyWeight			= @"Weight";

const	NSString*			kPADSearchOptionResultType		= @"Result Type";
const	NSString*			kPADSearchOptionResultTypeLeaf	= @"Leaf";
const	NSString*			kPADSearchOptionResultTypeItem	= @"Default";

@implementation PADSearchTerm
//static NSMutableArray*		gPADSearchTerms = nil;

- (void)dealloc
{
	[self setTermTitle:nil];
	[self setTermID:nil];
	[self setCompareData:nil];
	[self setGetSelector:nil];
	[self setCompareSelector:nil];
	[self setTermOptions:nil];
	
	[super dealloc];
}

- (NSString*)termTitle { return termTitle; }
- (void)setTermTitle:(NSString*)title
{
	if( title ) [title retain];
	if( termTitle ) [termTitle release];
	termTitle = title;
}

- (NSString*)termID { return termID; }
- (void)setTermID:(NSString*)id
{ termID = id; 
	if( id ) [id retain];
	if( termID ) [termID release];
	termID = id;
}

- (int)termOrder { return termOrder; }
- (void)setTermOrder:(int)id { termOrder = id; }

- (PADSearchConjunction)termConjuntion { return termConjuntion; }
- (void)setTermConjunction:(PADSearchConjunction)newConjunction
	{ termConjuntion = newConjunction; }

- (float)termWeight { return termWeight; }
- (void)setTermWeight:(float)weight { termWeight = weight; }

- (id)compareData { return termCompareDataValue; }
- (void)setCompareData:(id)data
{
	if( data ) [data retain];
	if( termCompareDataValue ) [termCompareDataValue release];
	termCompareDataValue = data;
}

- (SEL)getSelector { return termGetDataSelector; }
- (void)setGetSelector:(SEL)data
{
	termGetDataSelector = data;
}

- (SEL)compareSelector { return termCompareDataSelector; }
- (void)setCompareSelector:(SEL)data
{
	termCompareDataSelector = data;
}

- (NSMutableDictionary*)termOptions { return termOptions; }
- (void)setTermOptions:(NSMutableDictionary*)options
{
	if( options ) [options retain];
	if( termOptions ) [termOptions release];
	termOptions = options;
}

- (PADSearchRelevance)compareWithElement:(id)element
{
	id					elementValue = nil;
	NSNumber*			elementNSRank = nil;
	PADSearchRelevance	elementRank = 0.0;
	float				elementWeight = [self termWeight];
	
	if( element )
		if( [self getSelector] != nil ) elementValue = [element performSelector:[self getSelector]];
		else elementValue = element;
	if( elementValue != nil )
		elementNSRank = [elementValue performSelector:[self compareSelector] withObject:[self compareData] withObject:[self termOptions]];
	
	if( elementNSRank != nil )
		elementRank = [elementNSRank floatValue];

	return elementRank * elementWeight;
}

- (PADSearchRelevance)compareForSearch:(id)value withOptions:(NSMutableDictionary*)options
{	
	id						ourData = [self compareData];
	PADSearchRelevance		rank = 0.0;
	NSStringCompareOptions	findOptions = NSCaseInsensitiveSearch || NSNumericSearch || NSDiacriticInsensitiveSearch || NSWidthInsensitiveSearch;

	if( ourData == nil ) rank = 1.0;
	else if( [ourData isKindOfClass:[NSString class]] )
		rank = [ourData rankWithString:value compareOptions:findOptions];
	else if( [ourData isKindOfClass:[NSDate class]] )
		rank = [ourData rankWithDate:value withOptions:options];
	else if( [ourData isEqual:value] )
		rank = 1.0;
	
	return rank;
}

- (PADSearchTerm*)initWithTitle:(NSString*)title termID:(NSString*)newID getSelector:(SEL)getSel compareSelector:(SEL)cmpSel compareData:(id)data andOptions:(NSDictionary*)options
{
	if( self = [super init] )
	{
		[self setTermTitle:title];
		[self setTermID:newID];
		[self setGetSelector:getSel];
		[self setCompareData:data];
		[self setTermConjunction:kPADSearchConjunctionNormal];

		if( cmpSel ) [self setCompareSelector:cmpSel];
		else [self setCompareSelector:@selector(compareForSearch:withOptions:)];
				
		[self setTermOptions:[[NSMutableDictionary alloc] initWithCapacity:0]];
		if( options )
			[[self termOptions] addEntriesFromDictionary:options];
	}
		
	return self;
}

+ (PADSearchTerm*)termWithTitle:(NSString*)title termID:(NSString*)newID getSelector:(SEL)getSel compareSelector:(SEL)cmpSel compareData:(id)data andOptions:(NSDictionary*)options
	{ return [[PADSearchTerm alloc] initWithTitle:title termID:newID getSelector:getSel compareSelector:cmpSel compareData:data andOptions:options]; }

- (PADSearchTerm*)termWithTerm
{	return [PADSearchTerm termWithTitle:[self termTitle] 
								 termID:[self termID] 
							getSelector:[self getSelector] 
						compareSelector:[self compareSelector] 
							compareData:[self compareData]
							 andOptions:[self termOptions]];
}


@end		// PADSearchTerm

/*
void			PADSearchTermSetup()
{
	NSLog(@"PADSearchTermSetup: No Longer Called");
	
//	[PADSearchService sharedSearch];
	
	PADAddSearchTerm( kPADSearchByTitle, kPADSearchByTitleID, @selector(nodeData), @selector(searchForName:withOptions:), nil, nil );
	PADAddSearchTerm( kPADSearchBySlot, kPADSearchBySlotID, @selector(nodeData), @selector(searchForSlot:withOptions:), nil, nil );
	PADAddSearchTerm( kPADSearchByType, kPADSearchByTypeID, @selector(nodeData), @selector(searchForFlavor:withOptions:), nil, nil );
	PADAddSearchTerm( kPADSearchByDateAdded, kPADSearchByDateAddedID, @selector(nodeData), @selector(searchForDateAdded:withOptions:), nil, nil );
	PADAddSearchTerm( kPADSearchByFileUTI, kPADSearchByFileUTIID, @selector(nodeData), @selector(searchForFileUTI:withOptions:), nil, nil );
	PADAddSearchTerm( kPADSearchByDateCheckedIn, kPADSearchByDateCheckedInID, @selector(nodeData), @selector(searchForDateCheckedIn:withOptions:), nil, nil );
	PADAddSearchTerm( kPADSearchByDateCheckedOut, kPADSearchByDateCheckedOutID, @selector(nodeData), @selector(searchForDateCheckedOut:withOptions:), nil, nil );
	PADAddSearchTerm( kPADSearchByDateCheckedInOut, kPADSearchByDateCheckedInOutID, @selector(nodeData), @selector(searchForDateCheckedInOut:withOptions:), nil, nil );
	PADAddSearchTerm( kPADSearchByComments, kPADSearchByCommentsID, @selector(nodeData), @selector(searchForComments:withOptions:), nil, nil );
	PADAddSearchTerm( kPADSearchByTags, kPADSearchByTagsID, @selector(nodeData), @selector(searchForTags:withOptions:), nil, nil );
	PADAddSearchTerm( kPADSearchByStars, kPADSearchByStarsID, @selector(nodeData), @selector(searchForStars:withOptions:), nil, nil );
}

void PADAddSearchTerm( const NSString* title, const NSString* newID, SEL getSel, SEL cmpSel, id data, NSDictionary* options )
{
	PADSearchTerm*		newTerm = [PADSearchTerm termWithTitle:(NSString*)title
														termID:(NSString*)newID
												getSelector:getSel
											compareSelector:cmpSel
											   compareData:data
												andOptions:options];
	
	if( !gPADSearchTerms ) gPADSearchTerms = [NSMutableArray arrayWithCapacity:0];
	[gPADSearchTerms addObject:newTerm];
	[gPADSearchTerms retain];
}

PADSearchTerm*	PADCopySearchTermWithTitleOrID( NSString* aTermName )
{
	int				termIndex, termCount = (gPADSearchTerms != nil) ? [gPADSearchTerms count] : 0;
	PADSearchTerm*	workTerm = nil;
	PADSearchTerm*	outTerm = nil;
	
	if( termCount == 0 ) return outTerm;
	
	for( termIndex=0; termIndex < termCount; termIndex++ )
	{
		workTerm = [gPADSearchTerms objectAtIndex:termIndex];

		if( [[workTerm termTitle] compare:aTermName] == NSOrderedSame ) outTerm = [workTerm termWithTerm];
		else if( [[workTerm termID] compare:aTermName] == NSOrderedSame ) outTerm = [workTerm termWithTerm];
		
		if( outTerm != nil ) break;
	}
	
	return outTerm;
}
*/

@implementation PADSearchRequest

-(void)dealloc
{
	
	NSLog(@"DEALLOC REQUEST");
	
	[[PADSearchService sharedSearch] removeActiveSearch:self];
	
	if( searchLocations!= nil )			[searchLocations release];
	if( searchTermDictionary!= nil )	[searchTermDictionary release];
	if( searchTermElements!= nil )		[searchTermElements release];
	if( searchTermOperations!= nil )	[searchTermOperations release];
	if( searchOptions!= nil )			[searchOptions release];
	if( searchResults!= nil )			[searchResults release];
	if( searchSubTree != nil )			[searchSubTree release];
	
	searchLocations = nil;
	searchTermDictionary = nil;
	searchTermElements = nil;
	searchOptions = nil;
	searchResults = nil;
	searchTarget = nil;
	searchNode = nil;
	searchSubTree = nil;
	searchingNow = NO;
	
	[super dealloc];
}

-(SimpleTreeNode*)resultsSubTree
	{ return searchSubTree; }

-(NSMutableDictionary*)searchTermDictionary
	{ return searchTermDictionary; }

-(NSArray*)searchOriginalSelection
	{ return searchOriginalSelection; }

-(void)setSearchOriginalSelection:(NSArray*)selection
{ 
	if( !searchOriginalSelection || ![searchOriginalSelection isEqual:selection] )
	{
		[selection retain];
		[searchOriginalSelection release];
		searchOriginalSelection = selection;
	}
}


- (NSArray*)insertMatchesIntoSubTree:(PADSearchTermOperation*)theSearch
{
	NSArray*		newResults = [theSearch pullMatchQueue];
	TreeNode*		newNode = nil;
	int				resultIndex, resultCount = [newResults count];
	BOOL			useParent = [(NSString*)kPADSearchOptionResultTypeItem isEqual:[searchOptions objectForKey:kPADSearchOptionResultType]];
	TreeNode*		parentNode = (TreeNode*)searchSubTree;
	
	for (resultIndex=0; resultIndex < resultCount; resultIndex++) {
		newNode = (TreeNode*)[newResults objectAtIndex:resultIndex];
		if( useParent )
			parentNode = [theSearch parentMatchOfChildMatch:(SimpleTreeNode*)newNode];
		if( parentNode == nil )
			parentNode = searchSubTree;
		
		if( parentNode != nil )
			[parentNode insertChild:newNode atIndex:[parentNode numberOfChildren]];
	}
	
	return newResults;
}	

-(id)valueForTerm:(id)term
{
	NSMutableDictionary*	termDict = nil;
	
	if( !searchTermDictionary ) return nil;
	if( !term ) return nil;

	termDict = [searchTermDictionary objectForKey:term];
	if( !termDict ) return nil;
	return [termDict objectForKey:kPADSearchTermKeyValue];
}

-(BOOL)searchResultsDirty
	{ return searchResultsDirty; }

-(void)dirtySearchResults
	{ searchResultsDirty = YES; }

-(id)searchTarget
	{ return searchTarget; }

-(BOOL)searchBusy
{
	BOOL			allFinished = YES;
	int				opCount = 0;
	int				opMax = [searchTermOperations count];
	
	while( (allFinished == YES) && (opCount < opMax) ) {
		allFinished = ![[searchTermOperations objectAtIndex:opCount] searchBusy];
		if( allFinished ) opCount++;
	}
	
	return !allFinished;
}	

//
// Called in search thread to create an element for value that matched
//
-(id)searchCreateMatchForElement:(id)element withScore:(PADSearchRelevanceRef)scoreRef
{ 
	SimpleTreeNode*		newNode = nil;
	PADSearchRelevance	score = [scoreRef floatValue];
	NSString*			isOption = [searchTermDictionary objectForKey:kPADSearchOptionResultType];
	
	if( [[element nodeData] itemSlot] != 0 )
		newNode = [SimpleTreeNode treeForActualMatch:element withScore:score asResult:isOption];
	
	return newNode;
}

//
// Called in main thread to respond to matching values in queue
//	Maximum number of objects held is PADMATCHQUEUE_THRESHOLD before
//  this method is called.
//
- (void)searchFoundResults:(PADSearchTermOperation*)theSearch
{
	NSArray*		newResults = [self insertMatchesIntoSubTree:theSearch];
	
	//  Notify target of new insertions
	
	if( ( searchTarget != nil ) && ( [newResults count] > 0 ) )
		[searchTarget performSelector:@selector(searchFoundResults:forSearch:) withObject:newResults withObject:self];
}

//
// Called in main thread when a search thread is exhausted
//
- (void)searchFinished:(PADSearchTermOperation*)theSearch
{
	NSArray*		newResults = [self insertMatchesIntoSubTree:theSearch];
	BOOL			allFinished = YES;

	[theSearch endSearch];
	
	// Notify target if everything is finished and/or if there are any remaining results.
		
	allFinished = ![self searchBusy]; 
	
	if( !allFinished ) {
		if( ( searchTarget != nil ) && ( [newResults count] > 0 ) )
			[searchTarget performSelector:@selector(searchFoundResults:forSearch:) withObject:newResults withObject:self];
	} else {
		searchResultsDirty = NO;
		if( searchTarget != nil ) {
			if( [newResults count] > 0 ) 
				[searchTarget performSelector:@selector(searchFoundResults:forSearch:) withObject:newResults withObject:self];
			[searchTarget performSelector:@selector(searchCompleted:) withObject:self];
		}
		[searchTermOperations removeAllObjects];
		//if( searchNode != nil )
			//[searchNode setBusy:NO];
		[[PADSearchService sharedSearch] searchFinished:self];
	}	
}

-(PADSearchRequest*)setupSearchForTarget:(id)target onNode:(id)node andSubTree:(id)subTree
{
	searchTarget = target;
	searchNode = node;
	searchSubTree = subTree;
	searchResultsDirty = YES;

	[[PADSearchService sharedSearch] addActiveSearch:self];
	
	return self;
}

-(PADSearchRequest*)startSearch
{
	int		locIndex, locCount = [searchLocations count];
	PADSearchTermOperation*		newTerm;
	SimpleTreeNode*				devicesNode = nil;
	
	if( searchResultsDirty == NO )
		return self;

	if( searchSubTree != nil )
		[[searchSubTree children] makeObjectsPerformSelector:@selector(removeFromParent)];

	[[PADSearchService sharedSearch] searchStarted:self];
	
	[self createTermsForKeys];
	
	if( locCount == 0 ) {
		devicesNode = [[[[DACALTreeDataSource shared] treeControl] treeRoot] childWithItemType:kPADTypeGroupDevices];
		searchLocations = [[NSArray alloc] initWithArray:[[devicesNode children] arrayWithSubTrees]];
		locCount = [searchLocations count];
	}

	//NSLog(@"Searching locations: %@", searchLocations);
	
	//if( searchNode != nil )
	//	[searchNode setBusy:YES];
	
	for( locIndex=0; locIndex < locCount; locIndex++ )
	{
		newTerm = [PADSearchTermOperation searchOperationsForTreeNode:[searchLocations objectAtIndex:locIndex] forTerms:searchTermElements andTarget:self];
		if( newTerm ) [searchTermOperations addObject:newTerm];
	}
	
	[searchTermOperations makeObjectsPerformSelector:@selector(startSearch)];
	
	return self;
}

-(void)cancel
{
	if( searchTermOperations != nil )
		[searchTermOperations makeObjectsPerformSelector:@selector(cancel)];
}


-(void)addSearchTerm:(id)inTerm forValue:(id)inValue inOrder:(int)order andConjunction:(PADSearchConjunction)inConj withWeight:(float)weight andOptions:(NSDictionary*)options
{
	id		setValue = nil;
	NSMutableDictionary*	newOptions = [NSMutableDictionary dictionaryWithCapacity:0];
	NSNumber*				setOrder = nil;
	NSNumber*				setWeight = [NSNumber numberWithFloat:weight];
	NSNumber*				setConj = [NSNumber numberWithInt:inConj];
	
	if( inValue != nil ) setValue = inValue;
	else setValue = [NSNull null];
	
	if( order == 0 ) order = [searchTermDictionary count] + 1;
	setOrder = [NSNumber numberWithInt:order];
	
	if( options ) [newOptions addEntriesFromDictionary:options];
	[newOptions setObject:setValue	forKey:kPADSearchTermKeyValue];
	[newOptions setObject:setOrder	forKey:kPADSearchTermKeyOrder];
	[newOptions setObject:setConj	forKey:kPADSearchTermKeyConjunction];
	[newOptions setObject:setWeight forKey:kPADSearchTermKeyWeight];
	
	[searchTermDictionary setObject:newOptions forKey:inTerm];
}

-(void)createTermsForKeys
{
	NSMutableArray*		newTerms = searchTermElements;
	NSEnumerator*		termEnumerator = [searchTermDictionary keyEnumerator];
	NSString*			keyName = nil;
	NSMutableDictionary* keyDict = nil;
	id					keyValue = nil;
	id					tempTerm = nil;
	PADSearchConjunction	keyConj = kPADSearchConjunctionNormal;
	float				keyWeight = 0;
	int					fillLoop, keyIndex = 0;
	
	for( fillLoop=0;fillLoop < [searchTermDictionary count]; fillLoop++ )
		[newTerms addObject:[NSNull null]];
		
	while ((keyName = (NSString*)[termEnumerator nextObject])) {
		tempTerm = [[PADSearchService sharedService] copySearchTermWithTitleOrID:keyName];

		keyDict = [searchTermDictionary objectForKey:keyName];
		keyValue = [keyDict objectForKey:kPADSearchTermKeyValue];
		keyIndex = [[keyDict objectForKey:kPADSearchTermKeyOrder] intValue] - 1;
		keyConj = [[keyDict objectForKey:kPADSearchTermKeyConjunction] intValue];
		keyWeight = [[keyDict objectForKey:kPADSearchTermKeyWeight] floatValue];

		if( tempTerm != nil ) {
			if( [[NSNull null] isEqual:keyValue] ) keyValue = nil;
			[tempTerm setCompareData:keyValue];
			[tempTerm setTermOptions:keyDict];
			[tempTerm setTermConjunction:keyConj];
			[tempTerm setTermWeight:keyWeight];
			[newTerms replaceObjectAtIndex:keyIndex withObject:tempTerm];
		} else
			NSLog(@"No term for key:%@", keyName);
			
	}
}

-(void)searchDataChanged:(NSArray*)theItems
{
	if( ![self searchBusy] ) {
		[self dirtySearchResults];
		// NSLog(@"Results Dirty: %@", self);
	}
}


-(id)initSearchInLocations:(NSArray*)inLocs andOptions:(NSDictionary*)inOptions
{
	if( self = [super init] ) 
	{
		NSMutableDictionary*	newOptions = [[NSMutableDictionary alloc] initWithCapacity:0];
		
		searchLocations = inLocs;
		
		searchOptions = newOptions;
		if( inOptions != nil ) [newOptions addEntriesFromDictionary:inOptions];
		searchingNow = NO;
		searchResultsDirty = YES;
		
		searchTermDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];	
		searchTermElements = [[NSMutableArray alloc] initWithCapacity:0];
		searchTermParents = [[NSMutableArray alloc] initWithCapacity:0];
		searchTermOperations = [[NSMutableArray alloc] initWithCapacity:0];
		searchError = 0;
		searchResults = [[NSMutableArray alloc] initWithCapacity:0];
	}
	return self;
}

+(id)searchCarouselsForStars:(NSString*)inUTI resultType:(const NSString*)inType
{ 
	NSDictionary*		optionDict = [NSDictionary dictionaryWithObject:inType forKey:kPADSearchOptionResultType];
	PADSearchRequest*	newRequest = [[PADSearchRequest alloc] initSearchInLocations:nil andOptions:optionDict];
	
	if( newRequest )
	{
		[newRequest addSearchTerm:kPADSearchByStars forValue:inUTI inOrder:0 andConjunction:kPADSearchConjunctionNormal withWeight:kPADSearchWeightNormal andOptions:nil];
	}
	
	return newRequest;
}

+(id)searchCarouselsForFileUTI:(NSString*)inUTI resultType:(const NSString*)inType
{ 
	NSDictionary*		optionDict = [NSDictionary dictionaryWithObject:inType forKey:kPADSearchOptionResultType];
	PADSearchRequest*	newRequest = [[PADSearchRequest alloc] initSearchInLocations:nil andOptions:optionDict];
	
	if( newRequest )
	{
		[newRequest addSearchTerm:kPADSearchByFileUTI forValue:inUTI inOrder:0 andConjunction:kPADSearchConjunctionNormal withWeight:kPADSearchWeightNormal andOptions:nil];
	}
	
	return newRequest;
}

+(id)searchCarouselsForDateAddedBeforeDays:(NSTimeInterval)inDays ofDate:(id)inDate resultType:(const NSString*)inType
{ 
	NSDictionary*			optionDict = [NSDictionary dictionaryWithObject:inType forKey:kPADSearchOptionResultType];
	PADSearchRequest*		newRequest = [[PADSearchRequest alloc] initSearchInLocations:nil andOptions:optionDict];
	NSMutableDictionary*	dateOptions = [NSMutableDictionary dictionaryWithCapacity:2];
										   
	[dateOptions setObject:@"Day Count" forKey:@"Range"];
	[dateOptions setObject:[NSNumber numberWithDouble:-inDays] forKey:@"Days"];
	
	if( newRequest )
	{
		[newRequest addSearchTerm:kPADSearchByDateAdded forValue:inDate inOrder:0 andConjunction:kPADSearchConjunctionNormal withWeight:kPADSearchWeightNormal andOptions:dateOptions];
	}
	
	return newRequest;
}

+(id)searchCarouselsForCheckedInOutBeforeDays:(NSTimeInterval)inDays ofDate:(id)inDate resultType:(const NSString*)inType
{ 
	NSDictionary*			optionDict = [NSDictionary dictionaryWithObject:inType forKey:kPADSearchOptionResultType];
	PADSearchRequest*		newRequest = [[PADSearchRequest alloc] initSearchInLocations:nil andOptions:optionDict];
	NSMutableDictionary*	dateOptions = [NSMutableDictionary dictionaryWithCapacity:2];
	
	[dateOptions setObject:@"Day Count" forKey:@"Range"];
	[dateOptions setObject:[NSNumber numberWithDouble:-inDays] forKey:@"Days"];
	
	if( newRequest )
	{
		[newRequest addSearchTerm:kPADSearchByDateCheckedInOut forValue:inDate inOrder:0 andConjunction:kPADSearchConjunctionNormal withWeight:kPADSearchWeightNormal andOptions:dateOptions];
	}
	
	return newRequest;
}

+(id)searchCarouselsForKind:(NSString*)inKind resultType:(const NSString*)inType
{ 
	NSDictionary*		optionDict = [NSDictionary dictionaryWithObject:inType forKey:kPADSearchOptionResultType];
	PADSearchRequest*	newRequest = [[PADSearchRequest alloc] initSearchInLocations:nil andOptions:optionDict];
	
	if( newRequest )
	{
		[newRequest addSearchTerm:kPADSearchByType forValue:inKind inOrder:0 andConjunction:kPADSearchConjunctionNormal withWeight:kPADSearchWeightNormal andOptions:nil];
	}
	
	return newRequest;
}

+(id)searchCarouselsForSlots:(NSString*)inSlot resultType:(const NSString*)inType
{ 
	NSDictionary*		optionDict = [NSDictionary dictionaryWithObject:inType forKey:kPADSearchOptionResultType];
	PADSearchRequest*	newRequest = [[PADSearchRequest alloc] initSearchInLocations:nil andOptions:optionDict];
	
	if( newRequest )
	{
		[newRequest addSearchTerm:kPADSearchBySlot forValue:inSlot inOrder:0 andConjunction:kPADSearchConjunctionNormal withWeight:kPADSearchWeightNormal andOptions:nil];
	}
	
	return newRequest;
}

+(id)searchCarouselsForTitle:(NSString*)inKind resultType:(const NSString*)inType
{ 
	NSDictionary*		optionDict = [NSDictionary dictionaryWithObject:inType forKey:kPADSearchOptionResultType];
	PADSearchRequest*	newRequest = [[PADSearchRequest alloc] initSearchInLocations:nil andOptions:optionDict];
	
	if( newRequest )
	{
		[newRequest addSearchTerm:kPADSearchByTitle forValue:inKind inOrder:0 andConjunction:kPADSearchConjunctionNormal withWeight:kPADSearchWeightNormal andOptions:nil];
	}
	
	return newRequest;
}

+(id)searchCarouselsForTerm:(NSString*)inTerm
{ 
	NSDictionary*		optionDict = [NSDictionary dictionaryWithObject:kPADSearchOptionResultTypeLeaf forKey:kPADSearchOptionResultType];
	PADSearchRequest*	newRequest = [[PADSearchRequest alloc] initSearchInLocations:nil andOptions:optionDict];
	
	if( newRequest )
	{
		[newRequest addSearchTerm:kPADSearchByTitle forValue:inTerm inOrder:0 andConjunction:kPADSearchConjunctionNormal withWeight:kPADSearchWeightNormal andOptions:nil];
		[newRequest addSearchTerm:kPADSearchBySlot forValue:inTerm inOrder:0 andConjunction:kPADSearchConjunctionNormal withWeight:kPADSearchWeightNormal andOptions:nil];
		[newRequest addSearchTerm:kPADSearchByComments forValue:inTerm inOrder:0 andConjunction:kPADSearchConjunctionNormal withWeight:kPADSearchWeightNormal andOptions:nil];
		[newRequest addSearchTerm:kPADSearchByTags forValue:inTerm inOrder:0 andConjunction:kPADSearchConjunctionNormal withWeight:kPADSearchWeightNormal andOptions:nil];
		[newRequest addSearchTerm:kPADSearchByStars forValue:inTerm inOrder:0 andConjunction:kPADSearchConjunctionNormal withWeight:kPADSearchWeightNormal andOptions:nil];
	}

	return newRequest;
}

@end		// PADSearchRequest


@implementation PADSearchTermOperation

-(void)dealloc
{
	NSLog(@"DEALLOC OPERATION"); 
	
	if( searchTree ) [searchTree release];
	if( searchTerms ) [searchTerms release];
	
	if( inQueue ) [inQueue release];
	if( matchQueue ) [matchQueue release];
	if( parentQueue ) [parentQueue release];
	
	[super dealloc];
}

-(BOOL)searchDone
{ 
	if( searchBusy == YES ) return NO;
	if( [self isExecuting] ) return NO;
	if( !matchQueue ) return YES;
	
	return ([matchQueue count] == 0) ? YES : NO;
}

-(BOOL)elementsWaiting
{
	if( !inQueue ) return NO;
	return ([inQueue count] == 0) ? NO : YES;	
}

-(PADSearchTermOperation*)initWithTree:(SimpleTreeNode*)aTree forTerms:(NSArray*)theTerms andTarget:(id)aTarget
{
	if( self = [super init] ) {
		searchTree = [aTree retain];
		searchTerms = [theTerms retain];
		messageTarget = [aTarget retain];
		
		inQueue = [[NSMutableArray alloc] initWithCapacity:0];
		matchQueue = [[NSMutableArray alloc] initWithCapacity:0];
		parentQueue = [[NSMutableArray alloc] initWithCapacity:0];
	}
	return self;
}

-(void)pushInQueue:(id)element
{ [inQueue addObject:element]; }
-(id)popInQueue
{ 
	id	theElement;
	
	if( !inQueue || ([inQueue count] == 0) ) return nil;
	theElement = [inQueue objectAtIndex:0];
	[inQueue removeObjectAtIndex:0];
	
	return theElement;
}

-(id)parentMatchOfChildMatch:(SimpleTreeNode*)child
{
	id					foundParent = nil;
	SimpleTreeNode*		indexParent = nil;
	SimpleTreeNode*		testParent = nil;
	SimpleTreeNode*		testChild = nil;
	NSInteger			parentActual, parentIndex, parentCount = [parentQueue count];
	BOOL				lastChild = NO;
	
	for( parentIndex=0; parentIndex < parentCount; parentIndex++ )
	{
		indexParent = [parentQueue objectAtIndex:parentIndex];
		testParent = [indexParent matchActual];
		testChild = [child matchActual];
		//testParent = [[indexParent nodeData] matchActual];
		//testChild = [[child nodeData] matchActual];
		parentActual = [[testParent children] indexOfObjectIdenticalTo:testChild];
		if( parentActual != NSNotFound ) {
			foundParent = indexParent;
			if( parentActual == [[testParent children] count] - 1 )
				lastChild = YES;
			break;
		}
	}
	
	if( lastChild ) {
		[foundParent retain];
		[parentQueue removeObjectAtIndex:parentIndex];
	}
	
	return foundParent;
}

-(void)pushChildrenInQueue:(SimpleTreeNode*)element
{ 
	//NSLog(@"Pushing children: %@", [element children]);

	if( [[element children] count] == 0 ) return; 
	[inQueue addObjectsFromArray:[element children]]; 

}


-(void)pushMatchQueue:(id)element withScore:(PADSearchRelevance)score
{ 
	id		newNode = nil;
	
	newNode = [messageTarget performSelector:@selector(searchCreateMatchForElement:withScore:) withObject:element withObject:[NSNumber numberWithFloat:score]];
	
	if( newNode != nil ) {
		[matchQueue addObject:newNode]; 
		if( [[element children] count] > 0 ) [parentQueue addObject:newNode];
	}
	if( [matchQueue count] > PADMATCHQUEUE_THRESHOLD ) [self notifyTarget:NO];
}

-(NSArray*)pullMatchQueue
{ 
	NSArray*	theElements;
	
	if( !matchQueue || ([matchQueue count] == 0) ) return nil;
	theElements = [NSArray arrayWithArray:matchQueue];
	[matchQueue removeAllObjects];
	
	return theElements;
}

-(BOOL)bailIfCancelled
{
	if( ![self isCancelled] ) return NO;
	
	NSLog(@"Cancelled %@", self);
	
	[self dealloc];
	
	return YES;
}

-(void)notifyTarget:(BOOL)done
{
	if( messageTarget != nil )
	{
		if( !done )
			[messageTarget performSelectorOnMainThread:@selector(searchFoundResults:) withObject:self waitUntilDone:YES];
		else
			[messageTarget performSelectorOnMainThread:@selector(searchFinished:) withObject:self waitUntilDone:YES];
	}
}


-(void)main
{
	SimpleTreeNode*			searchNode = nil;
	NSEnumerator*			termEnumerator = [searchTerms objectEnumerator];
	PADSearchRelevance		searchRelevance = 0.0;
	PADSearchRelevance		searchRank = 0.0;
	PADSearchConjunction	searchConjunction = kPADSearchConjunctionNormal;
	PADSearchTerm*			thisTerm = nil;
	float					termsCount = (float)[searchTerms count];
	float					termsWeight = 0.0;
	BOOL					isNot = NO;
	BOOL					isAnd = NO;
	
	[self pushChildrenInQueue:searchTree];

STARTSEARCH:
	
	while( [inQueue count] > 0 )
	{
		searchNode = [self popInQueue];
		searchRelevance = 0.0;
		termsWeight = 0.0;
		termEnumerator = [searchTerms objectEnumerator];

		while ((thisTerm = (PADSearchTerm*)[termEnumerator nextObject])) 
		{
			if( [thisTerm isKindOfClass:[NSNull class]] ) continue;
			
			searchConjunction = [thisTerm termConjuntion];
			isNot = (searchConjunction & kPADSearchConjunctionNot);
			isAnd = (searchConjunction & kPADSearchConjunctionAnd);
			
			if( [self bailIfCancelled] ) return;
			searchRank = [thisTerm compareWithElement:searchNode];
			
			if( isNot == YES ) {
				if( searchRank > 0.0 ) searchRank = 0.0;
				else searchRank = 1.0;
			}
			if( (isAnd == YES) && (searchRank == 0.0) )
				break;
			if( searchRank > 0.0 ) {
				searchRelevance += searchRank / termsCount;
				termsWeight += [thisTerm termWeight] / termsCount;
			}
		}
		if( [self bailIfCancelled] ) return;
		
		if( searchRelevance > 0.0 )
			[self pushMatchQueue:searchNode withScore:(searchRelevance / termsWeight)];
		
		[self pushChildrenInQueue:searchNode];
	}
	
	[self notifyTarget:![self elementsWaiting]];
	if( [self elementsWaiting] ) goto STARTSEARCH;
}

-(BOOL)searchBusy
	{ return searchBusy; }

// Called internally
-(void)endSearch
{
	searchBusy = NO;
}

// Called internally
-(void)startSearch
{
	searchBusy = YES;
	[[AppController shared] queueSearchOperation:self];	
}

+(PADSearchTermOperation*)searchOperationsForTreeNode:(SimpleTreeNode*)rootSubTree forTerms:(NSArray*)theTerms andTarget:(id)aTarget
	{ return [[PADSearchTermOperation alloc] initWithTree:rootSubTree forTerms:theTerms andTarget:aTarget]; }

@end		// PADSearchTermOperation

@implementation PADSearchService

-(void)dealloc
{
	if( searchTerms != nil ) [searchTerms release];
	searchTerms = nil;
	if( activeSearches != nil ) [activeSearches release];
	activeSearches = nil;
	if( activeWatchers != nil ) [activeWatchers release];
	activeWatchers = nil;
	
	[super dealloc];
}

-(void)initSelf
{
	searchTerms = [[NSMutableArray alloc] initWithCapacity:0];
	activeSearches = [[NSMutableArray alloc] initWithCapacity:0];
	activeWatchers = [[NSMutableArray alloc] initWithCapacity:0];
}

-(void)openService
{
	[self addSearchTermWithTitle:kPADSearchByTitle andTermID:kPADSearchByTitleID getSelector:@selector(nodeData) compareSelector:@selector(searchForName:withOptions:) compareData:nil andOptions:nil];
	[self addSearchTermWithTitle:kPADSearchBySlot andTermID:kPADSearchBySlotID getSelector:@selector(nodeData) compareSelector:@selector(searchForSlot:withOptions:) compareData:nil andOptions:nil];
	[self addSearchTermWithTitle:kPADSearchByType andTermID:kPADSearchByTypeID getSelector:@selector(nodeData) compareSelector:@selector(searchForFlavor:withOptions:) compareData:nil andOptions:nil];
	[self addSearchTermWithTitle:kPADSearchByDateAdded andTermID:kPADSearchByDateAddedID getSelector:@selector(nodeData) compareSelector:@selector(searchForDateAdded:withOptions:) compareData:nil andOptions:nil];
	[self addSearchTermWithTitle:kPADSearchByFileUTI andTermID:kPADSearchByFileUTIID getSelector:@selector(nodeData) compareSelector:@selector(searchForFileUTI:withOptions:) compareData:nil andOptions:nil];
	[self addSearchTermWithTitle:kPADSearchByDateCheckedIn andTermID:kPADSearchByDateCheckedInID getSelector:@selector(nodeData) compareSelector:@selector(searchForDateCheckedIn:withOptions:) compareData:nil andOptions:nil];
	[self addSearchTermWithTitle:kPADSearchByDateCheckedOut andTermID:kPADSearchByDateCheckedOutID getSelector:@selector(nodeData) compareSelector:@selector(searchForDateCheckedOut:withOptions:) compareData:nil andOptions:nil];
	[self addSearchTermWithTitle:kPADSearchByDateCheckedInOut andTermID:kPADSearchByDateCheckedInOutID getSelector:@selector(nodeData) compareSelector:@selector(searchForDateCheckedInOut:withOptions:) compareData:nil andOptions:nil];
	[self addSearchTermWithTitle:kPADSearchByComments andTermID:kPADSearchByCommentsID getSelector:@selector(nodeData) compareSelector:@selector(searchForComments:withOptions:) compareData:nil andOptions:nil];
	[self addSearchTermWithTitle:kPADSearchByTags andTermID:kPADSearchByTagsID getSelector:@selector(nodeData) compareSelector:@selector(searchForTags:withOptions:) compareData:nil andOptions:nil];
	[self addSearchTermWithTitle:kPADSearchByStars andTermID:kPADSearchByStarsID getSelector:@selector(nodeData) compareSelector:@selector(searchForStars:withOptions:) compareData:nil andOptions:nil];
}

+(id)sharedSearch
	{ return [PADSearchService sharedService]; }

+(void)updateAllSearches
	{ [[PADSearchService sharedService] searchDataChanged:nil]; }

-(void)addSearchTermWithTitle:(const NSString*)title andTermID:(const NSString*)newID getSelector:(SEL)getSel compareSelector:(SEL)cmpSel compareData:(id)data andOptions:(NSDictionary*)options
{
	PADSearchTerm*		newTerm = [PADSearchTerm termWithTitle:(NSString*)title
													termID:(NSString*)newID
											   getSelector:getSel
										   compareSelector:cmpSel
											   compareData:data
												andOptions:options];
	
	[searchTerms addObject:newTerm];
}

-(PADSearchTerm*)copySearchTermWithTitleOrID:(NSString*)aTermName
{
	int				termIndex, termCount = (searchTerms != nil) ? [searchTerms count] : 0;
	PADSearchTerm*	workTerm = nil;
	PADSearchTerm*	outTerm = nil;
	
	if( termCount == 0 ) return outTerm;
	
	for( termIndex=0; termIndex < termCount; termIndex++ )
	{
		workTerm = [searchTerms objectAtIndex:termIndex];
		
		if( [[workTerm termTitle] compare:aTermName] == NSOrderedSame ) outTerm = [workTerm termWithTerm];
		else if( [[workTerm termID] compare:aTermName] == NSOrderedSame ) outTerm = [workTerm termWithTerm];
		
		if( outTerm != nil ) break;
	}
	
	return outTerm;
}

-(void)addActiveSearch:(PADSearchRequest*)newRequest
{
	if( !activeSearches ) return;
	
	if( [activeSearches indexOfObject:newRequest] == NSNotFound )
	{
		[activeSearches addObject:newRequest];
	}
}

-(void)removeActiveSearch:(PADSearchRequest*)oldRequest
{
	if( !activeSearches ) return;
	
	
	if( [activeSearches indexOfObject:oldRequest] != NSNotFound )
	{
		[activeSearches removeObject:oldRequest];
	}
}

-(void)addActiveWatcher:(id)newWatcher
{
	if( !activeWatchers ) return;
	
	if( [activeWatchers indexOfObject:newWatcher] == NSNotFound )
		[activeWatchers addObject:newWatcher];
}

-(void)removeActiveWatcher:(id)oldWatcher
{
	if( !activeWatchers ) return;
	
	[activeWatchers removeObject:oldWatcher];
}

-(void)searchStarted:(PADSearchRequest*)aRequest
{
	[activeWatchers makeObjectsPerformSelector:@selector(searchStarted:) withObject:(id)aRequest];	
}

-(void)searchFinished:(PADSearchRequest*)aRequest
{
	[activeWatchers makeObjectsPerformSelector:@selector(searchFinished:) withObject:(id)aRequest];	
}

-(void)searchDataChanged:(NSArray*)theItems
{
	[activeSearches makeObjectsPerformSelector:@selector(searchDataChanged:) withObject:(id)theItems]; 
	[activeWatchers makeObjectsPerformSelector:@selector(searchDataChanged:) withObject:(id)theItems];
}

@end		// PADSearchService



@implementation SearchNodeData

-(void)dealloc
{
	if( matchActual != nil ) [matchActual release];
	matchActual = nil;

	[super dealloc];
}

-(id)reload
{
	if( matchActual != nil ) 
		[self setLocation:[(SimpleNodeData*)[matchActual nodeData] location]];
	
	self = [super reload];
	return self;
}

-(NSComparisonResult)compareDataScores:(SearchNodeData *)other
{
	PADSearchRelevance	thisScore = [self matchScore];
	PADSearchRelevance	thatScore = [other matchScore];
	NSComparisonResult	outResult = NSOrderedDescending;
	
	//	NSLog(@"COMPARE SCORE");
	if( thisScore == thatScore ) outResult = NSOrderedSame;
	if( thisScore < thatScore ) outResult = NSOrderedAscending;
	return outResult;
}

-(PADSearchRelevanceRef)searchForScore:(NSNumber*)score withOptions:(NSMutableDictionary*)options
{
	PADSearchRelevance	ourNumber = [self matchScore];
	PADSearchRelevance  anyNumber = [score floatValue];
	
	PADSearchRelevance	searchScore = (ourNumber - anyNumber) / 1.0;
	
	return [NSNumber numberWithFloat:searchScore];
}

-(SimpleTreeNode*)matchActual
	{ return matchActual; }
-(PADSearchRelevance)matchScore
	{ return matchScore; }

-(id)initWithLocationOfActual:(SimpleTreeNode*)inMatch withScore:(PADSearchRelevance)inScore asResult:(NSString*)resultType
{
	NSURL*	matchLocation = [(SimpleNodeData*)[inMatch nodeData] location];
	
	if( resultType && ([(NSString*)kPADSearchOptionResultTypeLeaf compare:resultType] == NSOrderedSame) )
		self = [self initWithLocation:matchLocation isLeaf:YES];
	else
		self = [self initWithLocation:matchLocation];
	
	if( self )
	{
		matchActual = [inMatch retain];
		matchScore = inScore;
		[self setItemElement:[[inMatch nodeData] itemElement]];
	}

	return self;
}

+(id)nodeDataWithLocationOfActual:(SimpleTreeNode*)inMatch withScore:(PADSearchRelevance)inScore asResult:(NSString*)resultType
	{ return [[SearchNodeData alloc] initWithLocationOfActual:inMatch withScore:inScore asResult:resultType]; }

@end		// SearchNodeData

@implementation SimpleTreeNode(PADSearchExtensions)


-(SimpleNodeData*)keyScore { return [self nodeData]; }

-(id)initForActualMatch:(SimpleTreeNode*)aMatch withScore:(PADSearchRelevance)aScore asResult:(NSString*)resultType
{
	return( [self initWithData:[SearchNodeData nodeDataWithLocationOfActual:aMatch withScore:aScore asResult:resultType]] );
}

+(id)treeForActualMatch:(SimpleTreeNode*)aMatch withScore:(PADSearchRelevance)aScore asResult:(NSString*)resultType
{
	return [[SimpleTreeNode alloc] initForActualMatch:aMatch withScore:aScore asResult:resultType];
}

@end		// SimpleTreeNode(PADSearchExtensions)








