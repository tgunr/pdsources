//
//  PADIndexNodeData.m
//  PickADisk
//
//  Created by Jack Small on 8/27/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

PADSearchRequest* PADCreateSearchForType( OSType aType );
PADSearchRequest* PADCreateSearchForType( OSType aType )
{
	PADSearchRequest*	theReq = nil;
	
	if( aType == 'gMov' )
		theReq = [PADSearchRequest searchCarouselsForKind:(NSString*)PADINDEX_FLAVORVALUE_MOVIE resultType:kPADSearchOptionResultTypeItem];
	
	if( aType == 'gMus' )
		theReq = [PADSearchRequest searchCarouselsForKind:(NSString*)PADINDEX_FLAVORVALUE_MUSIC resultType:kPADSearchOptionResultTypeItem];
	
	if( aType == 'gFil' )
		theReq = [PADSearchRequest searchCarouselsForKind:(NSString*)PADINDEX_FLAVORVALUE_FILES resultType:kPADSearchOptionResultTypeItem];
	
	if( aType == 'gImg' )
		theReq = [PADSearchRequest searchCarouselsForKind:(NSString*)PADINDEX_FLAVORVALUE_IMAGE resultType:kPADSearchOptionResultTypeItem];

	return theReq;
}


@implementation IndexNodeData

-(PADSearchRequest*)itemSearch
	{ return itemSearch; }

-(void)setItemSearch:(PADSearchRequest*)newSearch
{
	if( newSearch ) [newSearch retain];
	if( itemSearch ) [itemSearch release];
	itemSearch = newSearch;
}

+ (id)leafDataWithName:(NSString*)str {
    // Convenience method to return a leaf node with its name set.
    return [[IndexNodeData alloc] initWithName:str isLeaf:YES];
}

+ (id)groupDataWithName:(NSString*)str {
    // Convenience method to return a branch node with its name set.
    return [[IndexNodeData alloc] initWithName:str isLeaf:NO];
}

@end		// IndexNodeData

@implementation SimpleTreeNode(PADIndexExtensions)

- (id)initIndexFromDictionary:(NSDictionary*)dict
{
    // This is a convenience init method to return a tree root of a tree derived from an input dictionary.
    // The input dictionary for this example app is InitInfo.dict.  Look at that file to understand the format.
    IndexNodeData *data = [IndexNodeData groupDataWithName:[dict objectForKey:KEY_GROUPNAME]];
    NSEnumerator *entryEnum = [[dict objectForKey:KEY_ENTRIES] objectEnumerator];
    id entry;
    SimpleTreeNode *child = nil;
	NSString*	entryName;
	NSString*	entryIconType; 
    
    self = [super initWithData:data parent:nil children:[[NSArray alloc] init]];
    if (self != nil) {
        while ((entry = [entryEnum nextObject])) {
			
            if ([entry isKindOfClass: [NSDictionary class]])
                child = [SimpleTreeNode treeIndexFromDictionary:entry];
			else if ([entry isKindOfClass: [NSArray class]]) {
				entryName = [entry objectAtIndex:0];
				entryIconType = [entry objectAtIndex:1];
				child = [[SimpleTreeNode alloc] initWithData:[IndexNodeData leafDataWithName:entryName] parent:nil children:[[NSArray alloc] init]];
				[[child nodeData] setIconRep: DACALGetIconImageForType( UTGetOSTypeFromString( (CFStringRef)entryIconType ) )];
				[[child nodeData] setItemSearch:PADCreateSearchForType( UTGetOSTypeFromString( (CFStringRef)entryIconType ) )];
			} else 
                child = [[SimpleTreeNode alloc] initWithData:[IndexNodeData leafDataWithName:entry] parent:nil children:[[NSArray alloc] init]];
            [self insertChild: child atIndex: [self numberOfChildren]];
        }
    }
    
    return self;
}



+ (id)treeIndexFromDictionary:(NSDictionary *)dict
{
    return [[SimpleTreeNode alloc] initIndexFromDictionary:dict];
}


@end
