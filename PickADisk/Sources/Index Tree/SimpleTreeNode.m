/*
    SimpleTreeNode.m
    Copyright (c) 2001-2006, Apple Computer, Inc., all rights reserved.
    Author: Chuck Pisula

    Milestones:
    Initially created 3/1/01

    Tree node data structure carrying simple data (SimpleTreeNode, and SimpleNodeData).
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple‚Äö√Ñ√¥s copyrights in 
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

#import "SimpleTreeNode.h"
#import "PADIndexOperation.h"
#import "DACALTreeDataSource.h"
#import <DACAL/pmsDACALUtility.h>
#import <PMSUtility/NSString_Extensions.h>
#import <PMSUtility/NSApplication_Extensions.h>


@implementation SimpleNodeData

- (id)initWithName:(NSString *)str isLeaf:(BOOL)leaf {
    if (self = [super init]) {
        name = [str retain];
        isLeaf = leaf;
        iconRep = nil;
        isExpandable = !isLeaf;
		isExpanded = NO;
        isSelectable = isLeaf;    
		location = NULL;
		itemType = 0;
		itemDevice = (DACALDeviceRef)NULL;
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
        location = [loc retain];
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
		if( itemFlavor == nil) itemFlavor = PADINDEX_FLAVORVALUE_FILES;
		if( [itemFlavor compare:@"data"] == NSOrderedSame ) itemFlavor = PADINDEX_FLAVORVALUE_FILES;		// patch for old run slots! please fix.
		
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
        location = [loc retain];
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

		itemFlavor = (NSString*)CFURLCopyItemFlavor( (CFURLRef)loc, NULL );			// was DACALSlotCopyType( itemDevice, itemSlot, NULL );
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
    // Convenience method to return a leaf node with its location set.
    return [[SimpleNodeData alloc] initWithLocation:loc];
}

+ (id)nodeDataWithURL:(NSURL*)loc isLeaf:(BOOL)leaf {
    // Convenience method to return a leaf node with its location set.
    return [[SimpleNodeData alloc] initWithLocation:loc isLeaf:leaf];
}

- (void)dealloc {
    if(name)		[name release];
    if(iconRep)		[iconRep release];
	if(location)	[location release];
	if(itemFlavor)	[itemFlavor release];
	if(itemAddDate)	[itemAddDate release];
	if(itemDevice)	CFRelease((CFTypeRef)itemDevice);
	
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
    if (!location || ![location isEqual:loc]) {
		[loc retain];
		[location release];
		location = loc;
    }
}
- (NSURL *)location {
    return location;
}
- (void)setLocationForIcon:(NSURL *)loc {
	// A convience function to set the url data and grab the icon
	
	[self setLocation:loc];
	[self setIconRep: [[NSImage alloc]initByReferencingURL:loc]];
	[self setName: (NSString*)CFURLCopyReferenceTitle( NULL, (CFURLRef)loc, NULL)];
}

- (void)setItemDevice:(DACALDeviceRef)device {
	CFURLRef oldDevice = (CFURLRef)itemDevice;

	if( !oldDevice || (!CFEqual(oldDevice, (CFURLRef)device)) )
	{
		if( oldDevice != NULL ) CFRelease( oldDevice );
		if( (CFURLRef)device != NULL ) CFRetain( (CFURLRef)device );
		itemDevice = device;
	}

}

- (DACALDeviceRef)itemDevice { return itemDevice; }

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
    if (!subTree || ![location isEqual:tree]) {
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

- (id)itemElement { return itemElement; }

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
	
	NSURL*		loc = [self location];
	//BOOL		isAFolder = (CFURLHasDirectoryPath((CFURLRef)loc)) ? YES : NO;
	
	name = (NSString*)CFURLCopyReferenceTitle( NULL, (CFURLRef)loc, NULL);
	//isLeaf = !isAFolder;
	[self setIconRep:CFURLGetIconAsNSImage( NULL, (CFURLRef)loc, NULL)];
	//isExpandable = isAFolder;
	itemDevice = CFURLCopyCarouselUUID( kCFAllocatorDefault, (CFURLRef)loc );
	itemSlot = CFURLGetSlotNumber( (CFURLRef)loc, FALSE );
	itemAddDate = (NSDate*)CFURLCopyDateSlotAdded( NULL, (CFURLRef)loc, NULL );
	
	itemFlavor = (NSString*)CFURLCopyItemFlavor( (CFURLRef)loc, NULL );			// was DACALSlotCopyType( itemDevice, itemSlot, NULL );
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
	NSStringCompareOptions	findOptions = NSCaseInsensitiveSearch || NSNumericSearch || NSDiacriticInsensitiveSearch || NSWidthInsensitiveSearch;
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
		
		if( other == nil ) other = [NSDate date];
		if( ([other isKindOfClass:[NSString class]] ) && ([other compare:@"Yesterday"] == NSOrderedSame) )
			other = [NSDate yesterday];
		
		if( (other != nil) && (ourDate != nil) )
		{
			anchorTime = CFDateGetAbsoluteTime((CFDateRef)other);
			limitTime = anchorTime + daySeconds;
			//otherDate = (CFDateRef)[(NSDate*)other addTimeInterval:(NSTimeInterval)daySeconds];
			
			//timeBetween = CFDateGetTimeIntervalSinceDate( ourDate, otherDate );
			if( CFAbsoluteTimeBetweenTimes( limitTime, distantTime, anchorTime ) )
				rank = (anchorTime-distantTime)/daySeconds;
			if( rank < 0.0 ) rank = -rank;
		}
	}	
	
	// if( rank )
	//	NSLog(@"Search distantDate:%f anchorDate:%f limitDate:%f  rank:%f", distantTime, anchorTime, limitTime, rank );
	
	return( [NSNumber numberWithFloat:rank] );
}

- (NSNumber*)searchForDateCheckedIn:(id)other withOptions:(NSMutableDictionary*)options
{
	NSDate*				ourDate = [self checkedInDate];
	PADSearchRelevance	rank = 0.0;
	
	if( ourDate )
		rank = (PADSearchRelevance)[ourDate rankWithDate:other withOptions:options];
	
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
	CFStringRef			ourUTI = CFURLCopyUTI( kCFAllocatorDefault, (CFURLRef)[self location], NULL );
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
	NSStringCompareOptions	findOptions = NSCaseInsensitiveSearch || NSNumericSearch || NSDiacriticInsensitiveSearch || NSWidthInsensitiveSearch;
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
	NSStringCompareOptions	findOptions = NSCaseInsensitiveSearch || NSNumericSearch || NSDiacriticInsensitiveSearch || NSWidthInsensitiveSearch;
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

@implementation SimpleTreeNode

- (id)init
{
	if (![super init]) return nil;

	return self;
}

-(id)initWithData:(id)data
{
	self = [super initWithData:data parent:nil children:[[NSArray alloc] init]];
	return self;
}

- (id)initFromDictionary:(NSDictionary*)dict {
    // This is a convenience init method to return a tree root of a tree derived from an input dictionary.
    // The input dictionary for this example app is InitInfo.dict.  Look at that file to understand the format.
    SimpleNodeData *data = [SimpleNodeData groupDataWithName:[dict objectForKey:KEY_GROUPNAME]];
    NSEnumerator *entryEnum = [[dict objectForKey:KEY_ENTRIES] objectEnumerator];
    id entry;
    SimpleTreeNode *child = nil;
	NSString*	entryName;
	NSString*	entryIconType; 
    
    self = [super initWithData:data parent:nil children:[[NSArray alloc] init]];
    if (self != nil) {
        while ((entry = [entryEnum nextObject])) {
			
            if ([entry isKindOfClass: [NSDictionary class]])
                child = [SimpleTreeNode treeFromDictionary:entry];
			else if ([entry isKindOfClass: [NSArray class]]) {
				entryName = [entry objectAtIndex:0];
				entryIconType = [entry objectAtIndex:1];
				child = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData leafDataWithName:entryName] parent:nil children:[[NSArray alloc] init]];
				[[child nodeData] setIconRep: DACALGetIconImageForType( UTGetOSTypeFromString( (CFStringRef)entryIconType ) )];
			} else 
                child = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData leafDataWithName:entry] parent:nil children:[[NSArray alloc] init]];
            [self insertChild: child atIndex: [self numberOfChildren]];
        }
    }
    
    return self;
}

- (id)initFromLocation:(NSURL*)loc
{
    // This is a convenience init method to return a tree root of a tree derived from a filesystem URL.
    // This version uses treeFromLocation and is called from the Indexing NSOperation for speedy collections in most cases. 
    //SimpleNodeData *data = [SimpleNodeData nodeDataWithURL:loc];
	
	CFDictionaryRef		dataDict = NULL;
	CFArrayRef			dataProps = CFArrayCreate(NULL, (const void**)&kCFURLFileDirectoryContents, 1, &kCFTypeArrayCallBacks);
	CFArrayRef			folderList = NULL;
	Boolean				wasFound = FALSE;
	Boolean				isSlot = CFURLIsSlot( (CFURLRef)loc );
	DACALSlotElement*	ourElement = DACALDeviceSlotElementForURL( (CFURLRef)loc );
	DACALSlotElement*	anElement = nil;
	
	wasFound = CFURLCreateDataAndPropertiesFromResource(NULL, (CFURLRef)loc, NULL, &dataDict, dataProps, NULL);
	if( wasFound ) {
		folderList = (CFArrayRef)CFDictionaryGetValue( dataDict, kCFURLFileDirectoryContents );
		if( folderList != NULL ) CFRetain( folderList );
		CFRelease( dataDict );
	}

	if( isSlot ) {
		if( (folderList != NULL ) && (CFArrayGetCount(folderList) > 0) ) {
			//data = [self nodeData];
			CFRelease( folderList );
			wasFound = CFURLCreateDataAndPropertiesFromResource(NULL, (CFURLRef)loc, NULL, &dataDict, dataProps, NULL);
			if( wasFound ) {
				folderList = (CFArrayRef)CFDictionaryGetValue( dataDict, kCFURLFileDirectoryContents );
				if( folderList != NULL ) CFRetain( folderList );
				CFRelease( dataDict );
			}
		}
	}
	
    NSEnumerator *entryEnum = [(NSArray*)folderList objectEnumerator];
    id entry;
    SimpleTreeNode *child = nil;
    
    if( [self nodeData] == nil ) self = [super initWithData:[SimpleNodeData nodeDataWithURL:loc] parent:nil children:[[NSArray alloc] init]]; // [super initWithData:data parent:nil children:[NSArray array]];
    if (self != nil) {
		[ourElement setElementNode:self];
		[[self nodeData] setItemElement:ourElement];
		anElement = [DACALSlotElement slotElementForNode:self];
        while ((entry = [entryEnum nextObject])) {
			if( CFURLIsVisible((CFURLRef)entry) ) {
				if (CFURLHasDirectoryPath((CFURLRef)entry))
					child = [SimpleTreeNode treeFromLocation:entry];
				else 
				{
					child = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData nodeDataWithURL:entry] parent:nil children:[[NSArray alloc] init]];
					anElement = [DACALSlotElement slotElementForNode:child];
				}
				[self insertChild: child atIndex: [self numberOfChildren]];
			}
        }
    }
    
	CFRelease( dataProps );
	if( folderList != NULL ) CFRelease( folderList );
	
    return self;
}

- (id)initOperationFromLocation:(NSURL*)loc
{
    // This is a convenience init method to return a tree root of a tree derived from a filesystem URL.
    // This version uses treeOperationFromLocation and is therefore very unsuitable for recursive filesets
   // SimpleNodeData *data = nil;
	
	CFDictionaryRef		dataDict = NULL;
	CFArrayRef			dataProps = CFArrayCreate(NULL, (const void**)&kCFURLFileDirectoryContents, 1, &kCFTypeArrayCallBacks);
	CFArrayRef			folderList = NULL;
	Boolean				wasFound = FALSE;
	Boolean				isSlot = CFURLIsSlot( (CFURLRef)loc );
	
	wasFound = CFURLCreateDataAndPropertiesFromResource(NULL, (CFURLRef)loc, NULL, &dataDict, dataProps, NULL);
	if( wasFound ) {
		folderList = (CFArrayRef)CFDictionaryGetValue( dataDict, kCFURLFileDirectoryContents );
		if( folderList != NULL ) CFRetain( folderList );
		CFRelease( dataDict );
	}
	
	if( isSlot ) {
		if( CFArrayGetCount(folderList) > 0 ) {
			//data = [self nodeData];
			CFRelease( folderList );
			wasFound = CFURLCreateDataAndPropertiesFromResource(NULL, (CFURLRef)loc, NULL, &dataDict, dataProps, NULL);
			if( wasFound ) {
				folderList = (CFArrayRef)CFDictionaryGetValue( dataDict, kCFURLFileDirectoryContents );
				if( folderList != NULL ) CFRetain( folderList );
				CFRelease( dataDict );
			}
		}
	} //else data = [SimpleNodeData nodeDataWithURL:loc];
	
    NSEnumerator *entryEnum = [(NSArray*)folderList objectEnumerator];
    id entry;
    SimpleTreeNode *child = nil;
    
    if( [self nodeData] == nil ) self = [super initWithData:[SimpleNodeData nodeDataWithURL:loc] parent:nil children:[[NSArray alloc] init]];
    if (self != nil) {
        while ((entry = [entryEnum nextObject])) {
			if( CFURLIsVisible((CFURLRef)entry) ) {
				if (CFURLHasDirectoryPath((CFURLRef)entry))
					child = [SimpleTreeNode treeOperationFromLocation:entry];
				else 
					child = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData nodeDataWithURL:entry] parent:nil children:[[NSArray alloc] init]];
				[self insertChild: child atIndex: [self numberOfChildren]];
			}
        }
    }

	CFRelease( dataProps );
	CFRelease( folderList );
	
    return self;
}

- (void)dealloc {
    [self setBusy:NO];
    [super dealloc];
}

+ (id)nodeDataWithURL:(NSURL*)loc {
    // Convenience method to return a leaf node with its location set.
	return [[SimpleTreeNode alloc] initWithData:[SimpleNodeData nodeDataWithURL:loc] parent:nil children:[NSArray array]];
}


+ (id)treeFromDictionary:(NSDictionary *)dict {
    return [[SimpleTreeNode alloc] initFromDictionary:dict];
}

+ (id)treeFromLocation:(NSURL *)loc {
    return [[SimpleTreeNode alloc] initFromLocation:loc];
}

+ (id)treeOperationFromLocation:(NSURL *)loc forUI:(BOOL)uiQueue
{
	SimpleTreeNode*		ourNode = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData nodeDataWithURL:loc] parent:nil children:[[NSArray alloc] init]];// [SimpleTreeNode nodeDataWithURL:loc];

	self = ourNode;	

	PADIndexOperation *indexOp = [[PADIndexOperation alloc] initWithLocation:loc forChild:ourNode];
	if( uiQueue ) [[AppController shared] queueUIOperation:indexOp];
	else [[AppController shared] queueOperation:indexOp];

	[indexOp release];
	
    return self;
}

+ (id)treeOperationFromLocation:(NSURL *)loc
{
	return [SimpleTreeNode treeOperationFromLocation:loc forUI:NO];
}

- (void)setDataDeviceAndSlotFromData:(id)data
{
	//Do Self
	[[self nodeData] setItemDevice:[data itemDevice]];
	[[self nodeData] setItemSlot:[data itemSlot]];
	
	[[self children] makeObjectsPerformSelector:@selector(setDataDeviceAndSlotFromData:) withObject:data];
}

- (void)setDataDevice:(DACALDeviceRef)inDevice slot:(DACALSlotNum)inSlot
{
	//Do Self
	[[self nodeData] setItemDevice:inDevice];
	[[self nodeData] setItemSlot:inSlot];
	
	[[self children] makeObjectsPerformSelector:@selector(setDataDeviceAndSlotFromData:) withObject:[self nodeData]];
}

- (BOOL)busy 
{
	return [[self nodeData] busy]; 
}

- (void)setBusy:(BOOL)value 
{ 
	BOOL	isBusy = [[self nodeData] busy];
	if( isBusy == value ) return;
	
	isBusy = value;
	
	if( isBusy == YES )
	{	//NSLog(@"%@:Got Busy",self);
		[[AppController shared]	performSelectorOnMainThread:@selector(scheduleAddBusyBody:)
												 withObject:self
											  waitUntilDone:YES];
	} else {
		//NSLog(@"%@:Not Busy",self);
		[[AppController shared]	performSelectorOnMainThread:@selector(scheduleRemoveBusyBody:)
												 withObject:self
											  waitUntilDone:NO];		
	}
	[[self nodeData] setBusy:value];
}

- (SimpleTreeNode*)childWithName:(NSString*)theName
{
	SimpleTreeNode*		outFoundNode = nil;
	SimpleTreeNode*		testChildNode = nil;
	UInt32	headCount = [self numberOfChildren];
	UInt32	childIndex = 0;
	
	for( childIndex=0; childIndex < headCount; childIndex++ )
	{
		testChildNode = (SimpleTreeNode*)[self childAtIndex:childIndex];
		if( CFEqual((CFStringRef)[[testChildNode nodeData] name], (CFStringRef)theName) )
		{
			outFoundNode = testChildNode;
			goto FOUND;
		}
	}
	
FOUND:
	return( outFoundNode );
}

- (SimpleTreeNode*)childWithDevice:(DACALDeviceRef)theBoxRef
{
	SimpleTreeNode*		outFoundNode = nil;
	SimpleTreeNode*		testChildNode = nil;
	UInt32	headCount = [self numberOfChildren];
	UInt32	childIndex = 0;
	
	for( childIndex=0; childIndex < headCount; childIndex++ )
	{
		testChildNode = (SimpleTreeNode*)[self childAtIndex:childIndex];
		if( CFEqual((CFUUIDRef)[[testChildNode nodeData] itemDevice], (CFUUIDRef)theBoxRef) )
		{
			outFoundNode = testChildNode;
			goto FOUND;
		}
	}
	
FOUND:
	return( outFoundNode );
}

- (SimpleTreeNode*)childWithSlotNum:(DACALSlotNum)theSlotNum
{
	SimpleTreeNode*		outFoundNode = nil;
	SimpleTreeNode*		testChildNode = nil;
	UInt32	headCount = [self numberOfChildren];
	UInt32	childIndex = 0;
	
	for( childIndex=0; childIndex < headCount; childIndex++ )
	{
		testChildNode = (SimpleTreeNode*)[self childAtIndex:childIndex];
		if( [[testChildNode nodeData] itemSlot] == theSlotNum ) 
		{
			outFoundNode = testChildNode;
			goto FOUND;
		}
	}
	
FOUND:
	return( outFoundNode );
}

- (SimpleTreeNode*)childWithItemType:(NSInteger)theItemType
{
	SimpleTreeNode*		outFoundNode = nil;
	SimpleTreeNode*		testChildNode = nil;
	UInt32	headCount = [self numberOfChildren];
	UInt32	childIndex = 0;
	
	for( childIndex=0; childIndex < headCount; childIndex++ )
	{
		testChildNode = (SimpleTreeNode*)[self childAtIndex:childIndex];
		if( [[testChildNode nodeData] itemType] == theItemType ) 
		{
			outFoundNode = testChildNode;
			goto FOUND;
		}
	}
	
FOUND:
	return( outFoundNode );
}

- (NSNumber*)numberForSlotNumber
	{ return [[self nodeData] numberForSlotNumber]; }

-(SimpleNodeData*)keyName { return [self nodeData]; }
-(SimpleNodeData*)keySlotNumber { return [self nodeData]; }
-(SimpleNodeData*)keyAddDate { return [self nodeData]; }
-(SimpleNodeData*)keyFlavor { return [self nodeData]; }
-(SimpleNodeData*)keyCheckedOut { return [self nodeData]; }
-(SimpleNodeData*)keyCheckedOutDate { return [self nodeData]; }
-(SimpleNodeData*)keyComments { return [self nodeData]; }
-(SimpleNodeData*)keyTags { return [self nodeData]; }
-(SimpleNodeData*)keyStars { return [self nodeData]; }
-(void)setKeyStars:(NSInteger)starLevel
	{ [[self nodeData] setKeyStars:starLevel]; }

-(SimpleTreeNode*)matchActual
{
	SimpleTreeNode*		realNode = [[self nodeData] matchActual];
	
	if( realNode == nil )
		realNode = self;
	
	return realNode; 
}

- (NSString*)localPathName { return [[self nodeData] name]; }

- (NSString*)localPathString {
	
	if( [[self nodeData] itemDevice] == kDACALNullDevice ) return nil;
	
	NSString*				outName = nil;
	NSMutableString*		workNames = [NSMutableString stringWithCapacity:0];
	SimpleTreeNode*			aParent = (SimpleTreeNode*)self;	//[self nodeParent];
	
	while ([aParent nodeParent] != nil) {
		[workNames setString:[NSString stringWithFormat:@"%@/%@",[aParent localPathName],workNames]];
		aParent = (SimpleTreeNode*)[aParent nodeParent];
	}
	
	if( [workNames length] > 0 )
		outName = [workNames substringToIndex:[workNames length]-1];
	
	return outName;
}

- (NSString*)absolutePathName
{
	NSString*	outName = nil;
	CFStringRef	workName = CFURLCopyActualName( kCFAllocatorDefault, (CFURLRef)[(SimpleNodeData*)[self nodeData] location], NULL );
	
	if( workName != NULL )
	{
		outName = [NSString stringWithString:(NSString*)workName];
		CFRelease( workName );
	}
	
	return outName;
}

- (NSString*)absolutePathString
{
	if( [[self nodeData] itemDevice] == kDACALNullDevice ) return nil;
	
	NSString*				outName = nil;
	NSMutableString*		workNames = [NSMutableString stringWithCapacity:0];
	SimpleTreeNode*			aParent = [self matchActual];
	CFURLRef				aSpot = (CFURLRef)[(SimpleNodeData*)[aParent nodeData] location];
	
	if( CFURLIsTopInSlot( kCFAllocatorDefault, aSpot ) || CFURLIsSlot( aSpot ) )
		[workNames setString:@"/"];
	else 
		while ([aParent nodeParent] != nil) {
			[workNames setString:[NSString stringWithFormat:@"%@/%@",[aParent absolutePathName],workNames]];
			aParent = (SimpleTreeNode*)[aParent nodeParent];
			aSpot = (CFURLRef)[(SimpleNodeData*)[aParent nodeData] location];
			if( CFURLIsTopInSlot( kCFAllocatorDefault, aSpot ) || CFURLIsSlot( aSpot ) ) break;
		}
	
	if( [workNames length] > 0 ) outName = [workNames substringToIndex:[workNames length]-1];
	else outName = nil;
	
	return outName;
}

- (NSString *)description
{
	
	if( [[self nodeData] itemDevice] == kDACALNullDevice ) return [[self nodeData] name];
	if( [[self nodeData] itemSlot] == 0 ) return [[self nodeData] name];
	
	NSString*			localPath = [self localPathString];
	NSString*			localDevice = (NSString*)DACALCommandCopyName([[self nodeData] itemDevice], NULL );
	NSString*			outString = [NSString stringWithFormat:NSLocalizedString(@"“%@” Slot %i: %@", @"Element Node Description Format with device, slot num and item path"), localDevice, [[self nodeData] itemSlot], localPath];

	[localDevice release];
    return outString;
}

- (NSString*)urlString
{
	
	if( [[self nodeData] itemDevice] == kDACALNullDevice ) return [[self nodeData] name];
	
	NSString*			localPath = [self localPathString];
	NSString*			localHost = @"";
	NSString*			localDevice = (NSString*)CFUUIDCreateString( kCFAllocatorDefault, (CFUUIDRef)[[self nodeData] itemDevice] );
	NSString*			urlString = [NSString stringWithFormat:@"carousel://%@/%@/%i/%@", localHost, localDevice, [[self nodeData] itemSlot], localPath];
	
	[localDevice release];
    return urlString;
}

- (NSString *)tooltip
{
	if( [[self nodeData] itemDevice] == kDACALNullDevice ) return [[self nodeData] name];
	if( [[self nodeData] itemSlot] == 0 ) return [[self nodeData] name];
	
	NSString*			localPath = [self localPathString];
	NSDate*				checkOutDate = [[self nodeData] checkedOutDate];
	NSString*			checkedOutString = NSLocalizedString(@"", @"Element Node Tooltip Format for items checked in");
	
	localPath = [[self matchActual] localPathString];
	
	if( checkOutDate != nil )
		checkedOutString = [NSString stringWithFormat:NSLocalizedString(@"Checked out on %@\n", @"Element Node Tooltip Format for date checked out"), [checkOutDate description]];
	
	NSString*			localDevice = (NSString*)DACALCommandCopyName([[self nodeData] itemDevice], NULL );
	NSString*			outString = [NSString stringWithFormat:NSLocalizedString(@"“%@” Slot %i\n%@%@", @"Element Node Tooltip Format for device name, slot num, checked out string, item path"), localDevice, [[self nodeData] itemSlot], checkedOutString, localPath];
	
	[localDevice release];
    return outString;
}


@end

