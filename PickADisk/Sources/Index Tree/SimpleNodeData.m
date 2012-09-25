//
//  SimpleNodeData.m
//  PickADisk
//
//  Created by Dave Carlton on 9/8/12.
//  Copyright (c) 2012 PolyMicro Systems. All rights reserved.
//

#import "SimpleNodeData.h"
#import "SimpleTreeNode.h"
#import "DACALTreeDataSource.h"
#import "PADSearchRequest.h"

@implementation SimpleNodeData

- (id)initWithName:(NSString *)str isLeaf:(BOOL)leaf {
    if (self = [super init]) {
        name = [str retain];
        isLeaf = leaf;
        iconRep = nil;
        isExpandable = !isLeaf;
		isExpanded = NO;
        isSelectable = isLeaf;
		itemURL = NULL;
		itemType = 0;
		itemDevice = NULL;
		itemSlot = 0;
		itemAddDate = nil;
		itemFlavor = nil;
    }
    return self;
}

- (id)initWithLocation:(NSURL *)loc {
    
	BOOL	isAFolder = (CFURLHasDirectoryPath((CFURLRef)loc)) ? YES : NO;
    //	BOOL	isASlot = (CFURLIsSlot((CFURLRef)loc)) ? YES : NO;
    
    if (self = [super init]) {
        itemURL = [loc retain];
		name = (NSString*)CFURLCopyReferenceTitle( NULL, (CFURLRef)loc, NULL);
        isLeaf = !isAFolder;
        iconRep = CFURLGetIconAsNSImage( NULL, (CFURLRef)loc, NULL);
        isExpandable = isAFolder;
		isExpanded = NO;
        isSelectable = YES;
		itemType = kPADTypeDataSlot;
		itemDevice = CFURLCopyCarouselUUID( kCFAllocatorDefault, (CFURLRef)loc );
		itemSlot = CFURLGetSlotNumber( (CFURLRef)loc, FALSE );
		itemAddDate = (NSDate*)CFURLCopyDateSlotAdded( NULL, (CFURLRef)loc, NULL );
		
		itemFlavor = (NSString*)CFURLCopyItemFlavor( (CFURLRef)loc, NULL );			// was DACALSlotCopyType( itemDevice, itemSlot, NULL );
		if( itemFlavor == nil)
            itemFlavor = PADINDEX_FLAVORVALUE_FILES;
		if( [itemFlavor compare:@"data"] == NSOrderedSame )
            itemFlavor = PADINDEX_FLAVORVALUE_FILES;		// patch for old run slots! please fix.
		
		if( [itemFlavor compare:PADINDEX_FLAVORVALUE_MUSIC] == NSOrderedSame )
			itemType = kPADTypeDataMuisc;
		else if( [itemFlavor compare:PADINDEX_FLAVORVALUE_MOVIE] == NSOrderedSame )
			itemType = kPADTypeDataMovie;
		else if( [(NSString*)@"Images" compare:itemFlavor] == NSOrderedSame )
			itemType = kPADTypeDataImage;
		else if( [(NSString*)@"Files" compare:itemFlavor] == NSOrderedSame )
			itemType = kPADTypeDataFiles;
	}
    return self;
}

- (id)initWithLocation:(NSURL *)loc isLeaf:(BOOL)leaf {
    
    //	BOOL	isASlot = (CFURLIsSlot((CFURLRef)loc)) ? YES : NO;
    
    if (self = [super init]) {
        itemURL = [loc retain];
		name = (NSString*)CFURLCopyReferenceTitle( NULL, (CFURLRef)loc, NULL);
        isLeaf = leaf;
        iconRep = CFURLGetIconAsNSImage( NULL, (CFURLRef)loc, NULL);
        isExpandable = !leaf;
		isExpanded = NO;
        isSelectable = YES;
 		itemType = kPADTypeDataSlot;
		itemDevice = CFURLCopyCarouselUUID( kCFAllocatorDefault, (CFURLRef)loc );
		itemSlot = CFURLGetSlotNumber( (CFURLRef)loc, FALSE );
		itemAddDate = (NSDate*)CFURLCopyDateSlotAdded( NULL, (CFURLRef)loc, NULL );
        
		itemFlavor = (NSString*)CFURLCopyItemFlavor( (CFURLRef)loc, NULL );
        
		if( itemFlavor == nil) itemFlavor = @"Files";
		if( [itemFlavor compare:@"data"] == NSOrderedSame ) itemFlavor = @"Files";
		
		if( [(NSString*)@"Music" compare:itemFlavor] == NSOrderedSame )
			itemType = kPADTypeDataMuisc;
		else if( [(NSString*)@"Movie" compare:itemFlavor] == NSOrderedSame )
			itemType = kPADTypeDataMovie;
		else if( [(NSString*)@"Images" compare:itemFlavor] == NSOrderedSame )
			itemType = kPADTypeDataImage;
		else if( [(NSString*)@"Files" compare:itemFlavor] == NSOrderedSame )
			itemType = kPADTypeDataFiles;
    }
	return self;
}

+ (id)leafDataWithName:(NSString*)str {
    // Convenience method to return a leaf node with its name set.
    return [[SimpleNodeData alloc] initWithName:str isLeaf:YES];
}

+ (id)groupDataWithName:(NSString*)str {
    // Convenience method to return a branch node with its name set.
    return [[SimpleNodeData alloc] initWithName:str isLeaf:NO];
}

+ (id)nodeDataWithURL:(NSURL*)loc {
    // Convenience method to return a leaf node with its itemURL set.
    return [[SimpleNodeData alloc] initWithLocation:loc];
}

+ (id)nodeDataWithURL:(NSURL*)loc isLeaf:(BOOL)leaf {
    // Convenience method to return a leaf node with its itemURL set.
    return [[SimpleNodeData alloc] initWithLocation:loc isLeaf:leaf];
}

- (void)dealloc {
    if(name)		[name release];
    if(iconRep)		[iconRep release];
	if(itemURL)	[itemURL release];
	if(itemFlavor)	[itemFlavor release];
	if(itemAddDate)	[itemAddDate release];
	if(itemDevice)
        [itemDevice release];
	
	if(subTree)		[subTree release];
	if(itemElement) [itemElement release];
	
    [super dealloc];
}

- (void)setName:(NSString *)str {
    if (!name || ![name isEqualToString:str]) {
        [name release];
        name = [str retain];
    }
}

- (NSString *)name {
    return name;
}

- (void)setIsLeaf:(BOOL)leaf {
    isLeaf = leaf;
}

- (BOOL)isLeaf {
    return isLeaf;
}

- (BOOL)isGroup {
    return !isLeaf;
}

- (void)setIconRep:(NSImage *)ir {
    if (!iconRep || ![iconRep isEqual:ir]) {
        [iconRep release];
        iconRep = [ir retain];
    }
}
- (NSImage *)iconRep {
    return iconRep;
}

- (void)setExpandable:(BOOL)value {
    isExpandable = value;
}

- (BOOL)isExpandable {
    return isExpandable;
}

- (void)setExpanded:(BOOL)value {
    isExpanded = value;
}

- (BOOL)isExpanded {
    return isExpanded;
}

- (BOOL)isSelectable {
    return isSelectable;
}

- (void)setSelectable:(BOOL)value {
    isSelectable = value;
}

- (NSString *)description {
    return name;
}

/*
 - (NSComparisonResult)compare:(id)other {
 // We want the data to be sorted by name, so we compare [self name] to [other name]
 if ([other isKindOfClass:[SimpleNodeData class]]) {
 SimpleNodeData *_other = (SimpleNodeData *)other;
 return [name compare:[_other name]];
 } else {
 return NSOrderedAscending;
 }
 }
 */

- (void)setLocation:(NSURL *)loc {
    if (!itemURL || ![itemURL isEqual:loc]) {
		[loc retain];
		[itemURL release];
		itemURL = loc;
    }
}
- (NSURL *)itemURL {
    return itemURL;
}
- (void)setLocationForIcon:(NSURL *)loc {
	// A convience function to set the url data and grab the icon
	
	[self setLocation:loc];
	[self setIconRep: [[NSImage alloc]initByReferencingURL:loc]];
	[self setName: (NSString*)CFURLCopyReferenceTitle( NULL, (CFURLRef)loc, NULL)];
}

- (void)setItemDevice:(DACALDevice *)device {
	DACALDevice *oldDevice = itemDevice;
    
	if( !oldDevice || (oldDevice != device) )
	{
		if( oldDevice != NULL )
            [oldDevice release];
		if( device != NULL )
            [device retain];
		itemDevice = device;
	}
    
}

- (DACALDevice *)itemDevice {
    return itemDevice;
}

- (void)setItemSlot:(DACALSlotNum)slot { itemSlot = slot; }
- (DACALSlotNum)itemSlot { return itemSlot; }

- (NSNumber*)numberForSlotNumber
{ return [NSNumber numberWithInt:[self itemSlot]]; }


- (void)setItemType:(NSInteger)type { itemType = type; }
- (NSInteger)itemType { return itemType; }

- (void)setItemFlavor:(NSString *)flavor
{
    if (!itemFlavor || ![itemFlavor isEqualToString:flavor]) {
		[itemFlavor release];
		itemFlavor = [flavor retain];
    }
}
- (NSString *)itemFlavor { return itemFlavor; }

- (void)setSubTree:(SimpleTreeNode*)tree {
    if (!subTree || ![itemURL isEqual:tree]) {
        [subTree release];
        subTree = [tree retain];
    }
}

- (NSDate *)itemAddDate { return itemAddDate; }

- (void)setItemAddDate:(NSDate *)newDay {
    if (!itemAddDate || ![itemAddDate isEqual:newDay]) {
		[itemAddDate release];
		itemAddDate = [newDay retain];
    }
}

- (SimpleTreeNode*)subTree { return subTree; }

- (void)setItemElement:(id)element {
    if (!itemElement || ![itemElement isEqual:element]) {
		[itemElement release];
		itemElement = [element retain];
    }
	
}

- (id)itemElement {
    return itemElement;
}

- (BOOL)busy { return isBusy; }
- (void)setBusy:(BOOL)value { isBusy = value; }

-(BOOL)isCheckedOut
{
	if( !itemElement ) return NO;
	return [itemElement isCheckedOut];
}

-(NSDate*)checkedOutDate
{
	if( !itemElement ) return nil;
	return [itemElement checkedOutDate];
}

-(NSDate*)checkedInDate
{
	if( !itemElement ) return nil;
	return [itemElement checkedInDate];
}

-(NSString*)keyComments
{
	if( !itemElement ) return nil;
	return [itemElement comments];
}

-(void)setKeyComments:(NSString*)newComment
{
	if( itemElement != nil )
		[itemElement setComments:newComment];
}

-(NSArray*)keyTags
{
	if( !itemElement ) return nil;
	return [itemElement tags];
}

-(void)setKeyTags:(NSArray*)newTags
{
	if( itemElement != nil )
		[itemElement setTags:newTags];
}

-(NSInteger)keyStars
{
	if( !itemElement ) return 0;
	return [itemElement stars];
}

-(void)setKeyStars:(NSInteger)starLevel
{
	if( itemElement != nil )
		[itemElement setStars:starLevel];
}


- (id)reload
{
	
	NSURL*		loc = [self itemURL];
	//BOOL		isAFolder = (CFURLHasDirectoryPath((CFURLRef)loc)) ? YES : NO;
	
	name = (NSString*)CFURLCopyReferenceTitle( NULL, (CFURLRef)loc, NULL);
	//isLeaf = !isAFolder;
	[self setIconRep:CFURLGetIconAsNSImage( NULL, (CFURLRef)loc, NULL)];
	//isExpandable = isAFolder;
	itemDevice = CFURLCopyCarouselUUID( kCFAllocatorDefault, (CFURLRef)loc );
	itemSlot = CFURLGetSlotNumber( (CFURLRef)loc, FALSE );
	itemAddDate = (NSDate*)CFURLCopyDateSlotAdded( NULL, (CFURLRef)loc, NULL );
	
	itemFlavor = (NSString*)CFURLCopyItemFlavor( (CFURLRef)loc, NULL );
    
	if( itemFlavor == nil) itemFlavor = PADINDEX_FLAVORVALUE_FILES;
	if( [itemFlavor compare:@"data"] == NSOrderedSame ) itemFlavor = PADINDEX_FLAVORVALUE_FILES;		// patch for old run slots! please fix.
	
	if( [itemFlavor compare:PADINDEX_FLAVORVALUE_MUSIC] == NSOrderedSame )
		itemType = kPADTypeDataMuisc;
	else if( [itemFlavor compare:PADINDEX_FLAVORVALUE_MOVIE] == NSOrderedSame )
		itemType = kPADTypeDataMovie;
	else if( [itemFlavor compare:PADINDEX_FLAVORVALUE_IMAGE] == NSOrderedSame )
		itemType = kPADTypeDataImage;
	
	return self;
}

- (id)reloadData:(id)newData
{
	self = [self reload];
    //	if( newData == nil) self = [self reload];
    //	else {
    //		[self autorelease];
    //		self = [newData reload];
    //	}
	return self;
}

-(NSComparisonResult)compareDataAddDates:(SimpleNodeData *)other
{
	//	NSLog(@"COMPARE Add Date");
	return( [[self itemAddDate] compare:[other itemAddDate]] );
}

-(NSComparisonResult)compareDataNames:(SimpleNodeData *)other
{
    //	NSLog(@"COMPARE NAME");
	return( [[self name] localizedCaseInsensitiveCompare:(NSString*)[other name]] );
}

-(NSComparisonResult)compareDataSlots:(SimpleNodeData *)other
{
	DACALSlotNum	thisSlot = [self itemSlot];
	DACALSlotNum	thatSlot = [other itemSlot];
    
    //	NSLog(@"COMPARE SLOT");
	if( thisSlot == thatSlot ) return NSOrderedSame;
	if( thisSlot < thatSlot ) return NSOrderedAscending;
	return NSOrderedDescending;
}

-(NSComparisonResult)compareDataFlavors:(SimpleNodeData *)other
{
	//	NSLog(@"COMPARE Flavors");
	return( [[self itemFlavor] compare:[other itemFlavor]] );
}

-(NSComparisonResult)compareDataScores:(SimpleNodeData *)other
{ return NSOrderedSame; }

- (NSComparisonResult)compareKeyCheckedOut:(SimpleNodeData *)other
{
	//	NSLog(@"COMPARE Checked Out");
	BOOL		selfCheckedOut = [self isCheckedOut];
	BOOL		otherCheckedOut = [other isCheckedOut];
    
	if( (selfCheckedOut == NO) && (otherCheckedOut == NO) )
		return [[self checkedInDate] compare:[other checkedInDate]];
	
	if( (selfCheckedOut == NO) && (otherCheckedOut == YES) )
		return NSOrderedAscending;
	
	if( (otherCheckedOut == NO) || !other )
		return NSOrderedDescending;
	
	return( [[self checkedOutDate] compare:[other checkedOutDate]] );
}

-(NSComparisonResult)compareCheckedOutDates:(SimpleNodeData *)other
{
	//	NSLog(@"COMPARE Check Out Dates");
	return( [[self checkedOutDate] compare:[other checkedOutDate]] );
}

-(NSComparisonResult)compareKeyComments:(SimpleNodeData *)other
{
	//	NSLog(@"COMPARE COMMENTS");
	return( [[self keyComments] localizedCaseInsensitiveCompare:(NSString*)[other keyComments]] );
}

- (NSComparisonResult)compareKeyTags:(SimpleNodeData *)other
{
	NSInteger	ourCount = [[self keyTags] count];
	NSInteger	otherCount = [[other keyTags] count];
	
	if( ourCount < otherCount )
		return NSOrderedAscending;
	
	if( ourCount > otherCount )
		return NSOrderedDescending;
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareKeyStars:(SimpleNodeData *)other;
{
	NSInteger	ourStars = [self keyStars];
	NSInteger	otherStars = [other keyStars];
	
	if( ourStars < otherStars )
		return NSOrderedAscending;
	
	if( ourStars > otherStars )
		return NSOrderedDescending;
	
	return NSOrderedSame;
}

- (NSComparisonResult)compare:(id)otherData
{
	NSComparisonResult		slotResult = NSOrderedAscending;
	
	if ([otherData isKindOfClass:[SimpleNodeData class]]) {
		SimpleNodeData *other = (SimpleNodeData *)otherData;
		slotResult = [self compareDataSlots:other];
		if(slotResult == NSOrderedSame)
			slotResult = [name compare:[other name] options:NSNumericSearch+NSCaseInsensitiveSearch];; // [self compareDataNames:other];
	}
	
	return slotResult;
}

-(SimpleTreeNode*)matchActual
{ return nil; }

- (NSNumber*)searchForName:(NSString*)other withOptions:(NSMutableDictionary*)options
{
	NSString*	ourName = [self name];
	NSRange		foundRange;
	PADSearchRelevance	rank = 0.0;
	NSStringCompareOptions	findOptions = NSCaseInsensitiveSearch | NSNumericSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch;
	NSNumber*	optionOption = nil;
	
	if( (options) && (optionOption = [options objectForKey:@"Options"]) )
		findOptions = [optionOption intValue];
	
	if( [ourName localizedCaseInsensitiveCompare:other] == NSOrderedSame ) rank = 1.0;
	else {
		foundRange = [ourName rangeOfString:other options:findOptions];
		if( foundRange.length != 0 ) rank = (foundRange.length*1.0) / ([ourName length]*1.0);
	}
    
	//if( rank )
	//	NSLog(@"Search for:%@ in %@ score:%f length:%i ourlength:%i", other, [self description], rank, foundRange.length, [ourName length]);
	
	return( [NSNumber numberWithFloat:rank] );
}

- (NSNumber*)searchForSlot:(id)other withOptions:(NSMutableDictionary*)options
{
	NSString*			ourSlot = [NSString stringWithFormat:@"%i", [self itemSlot]];
	PADSearchRelevance	rank = 0.0;
	
	if( ourSlot != nil )
		rank = [ourSlot rankWithString:other compareOptions:NSNumericSearch];
	
	//if( rank )
	//	NSLog(@"Slot Search for:%@ in:%@ Rank:%f", other, ourSlot, rank);
	
	return( [NSNumber numberWithFloat:rank] );
}

- (NSNumber*)searchForFlavor:(NSString*)other withOptions:(NSMutableDictionary*)options
{
	NSString*	ourFlavor = [self itemFlavor];
	PADSearchRelevance	rank = 0.0;
	
	if( other )
		if( [ourFlavor compare:other] == NSOrderedSame ) rank = 1.0;
	
	//if( rank )
	//	NSLog(@"Search for:%@ in %@ score:%f", other, [self description], rank);
	
	return( [NSNumber numberWithFloat:rank] );
}

- (NSNumber*)searchForDateAdded:(id)other withOptions:(NSMutableDictionary*)options
{
	CFDateRef	ourDate = (CFDateRef)[self itemAddDate];
    //	CFDateRef	otherDate;
    //	CFTimeInterval	timeBetween;
	
	CFAbsoluteTime  distantTime = (ourDate!=NULL) ? CFDateGetAbsoluteTime(ourDate) : 0.0;
	CFAbsoluteTime	anchorTime = 0.0;
	CFAbsoluteTime	limitTime = 0.0;
	PADSearchRelevance	rank = 0.0;
	NSString*	whichKind = nil;
	
	whichKind = (NSString*)[options objectForKey:@"Range"];
	
	if( [whichKind isEqual:@"Day Count"] ) {
		CFTimeInterval	dayCount = [[options objectForKey:@"Days"] doubleValue];
		CFTimeInterval	daySeconds = dayCount * 86400;
		
		if( other == nil )
            other = [NSDate date];
		if( [other isKindOfClass:[NSString class]] ) {
            NSString *otherAsString = other;
            if ([otherAsString compare:@"Yesterday"] == NSOrderedSame) {
                other = [NSDate yesterday];
            }
        }
		if( (other != nil) && (ourDate != nil) )
		{
			anchorTime = CFDateGetAbsoluteTime((CFDateRef)other);
			limitTime = anchorTime + daySeconds;
			//otherDate = (CFDateRef)[(NSDate*)other addTimeInterval:(NSTimeInterval)daySeconds];
			
			//timeBetween = CFDateGetTimeIntervalSinceDate( ourDate, otherDate );
			if( CFAbsoluteTimeBetweenTimes( limitTime, distantTime, anchorTime ) )
				rank = (PADSearchRelevance) ((anchorTime-distantTime)/daySeconds);
			if( rank < 0.0 )
                rank = -rank;
		}
	}
	
	// if( rank )
	//	NSLog(@"Search distantDate:%f anchorDate:%f limitDate:%f  rank:%f", distantTime, anchorTime, limitTime, rank );
	
	return( [NSNumber numberWithFloat:rank] );
}

- (NSNumber*)searchForDateCheckedIn:(id)other withOptions:(NSMutableDictionary*)options
{
	NSDate*				ourDate = [self checkedInDate];
	float               rank = 0.0;
	
	if( ourDate )
		rank = [ourDate rankWithDate:other withOptions:options];
	
	return( [NSNumber numberWithFloat:rank] );
}

- (NSNumber*)searchForDateCheckedOut:(id)other withOptions:(NSMutableDictionary*)options
{
	NSDate*				ourDate = [self checkedOutDate];
	PADSearchRelevance	rank = 0.0;
    
	if( ourDate )
		rank = (PADSearchRelevance)[ourDate rankWithDate:other withOptions:options];
	
	return( [NSNumber numberWithFloat:rank] );
}

- (NSNumber*)searchForDateCheckedInOut:(id)other withOptions:(NSMutableDictionary*)options
{
	NSDate*				ourDate = nil;
	PADSearchRelevance	rank = 0.0;
    
	if( [self isCheckedOut] == YES )
		ourDate = [self checkedOutDate];
	else
		ourDate = [self checkedInDate];
	
	if( ourDate )
		rank = [ourDate rankWithDate:other withOptions:options];
	
	return( [NSNumber numberWithFloat:rank] );
}

- (NSNumber*)searchForFileUTI:(NSString*)other withOptions:(NSMutableDictionary*)options
{
	CFStringRef			ourUTI = CFURLCopyUTI( kCFAllocatorDefault, (CFURLRef)[self itemURL], NULL );
	PADSearchRelevance	rank = 0.0;
	
	if( other ) {
		if( [other isKindOfClass:[NSString class]] )
			if( UTTypeConformsTo( ourUTI, (CFStringRef)other ) ) rank = 1.0;
		if( [other isKindOfClass:[NSArray class]] )
		{
			NSArray*	utiArray = (NSArray*)other;
			int		utiIndex, utiCount = [utiArray count];
			
			for( utiIndex=0; utiIndex < utiCount; utiIndex++ )
				if( UTTypeConformsTo( ourUTI, (CFStringRef)[utiArray objectAtIndex:utiIndex] ) )
				{
					rank = 1.0;
					break;
				}
		}
	}
	//if( rank )
	//	NSLog(@"Search UTI for:%@ in %@ score:%f", other, ourUTI, rank);
	CFRelease(ourUTI);
	return( [NSNumber numberWithFloat:rank] );
}

- (NSNumber*)searchForComments:(NSString*)other withOptions:(NSMutableDictionary*)options
{
	NSString*	ourComments = [self keyComments];
	PADSearchRelevance	rank = 0.0;
	NSStringCompareOptions	findOptions;
    findOptions = (NSStringCompareOptions) (NSCaseInsensitiveSearch | NSNumericSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch);
    NSNumber*	optionOption = nil;
	
	if( (options) && (optionOption = [options objectForKey:@"Options"]) )
		findOptions = [optionOption intValue];
	
	rank = [ourComments rankWithString:other compareOptions:findOptions];
	
	//if( rank )
	//	NSLog(@"Search for:%@ in %@ score:%f length:%i ourlength:%i", other, [self description], rank, foundRange.length, [ourName length]);
	
	return( [NSNumber numberWithFloat:rank] );
}

- (NSNumber*)searchForTags:(NSString*)other withOptions:(NSMutableDictionary*)options
{
	NSArray*	ourTags = [self keyTags];
    //	NSString*	ourTag = nil;
	NSInteger	tagIndex, tagCount = [ourTags count];
	PADSearchRelevance	rank = 0.0;
	PADSearchRelevance	tagRank = 0.0;
	NSStringCompareOptions	findOptions = NSCaseInsensitiveSearch | NSNumericSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch;
	NSNumber*	optionOption = nil;
	
	if( (options) && (optionOption = [options objectForKey:@"Options"]) )
		findOptions = [optionOption intValue];
	
	for( tagIndex=0; tagIndex < tagCount; tagIndex++ )
	{
		tagRank = [[ourTags objectAtIndex:tagIndex] rankWithString:other compareOptions:findOptions];
		if( tagRank != 0.0 )
			rank += (tagRank / tagCount);
	}
	
	//if( rank )
	//	NSLog(@"Search for:%@ in %@ score:%f length:%i ourlength:%i", other, [self description], rank, foundRange.length, [ourName length]);
	
	return( [NSNumber numberWithFloat:rank] );
}

- (NSNumber*)searchForStars:(id)other withOptions:(NSMutableDictionary*)options
{
	NSString*			ourStars = [NSString stringWithFormat:@"%i", [self keyStars]];
	PADSearchRelevance	rank = 0.0;
	
	if( ourStars != nil )
		rank = [ourStars rankWithString:other compareOptions:NSNumericSearch];
    
	//if( [self keyStars] > 0 )
	//	NSLog(@"Star Search for:%@ in:%@ Rank:%f", other, ourStars, rank);
	
	return( [NSNumber numberWithFloat:rank] );
}


@end
