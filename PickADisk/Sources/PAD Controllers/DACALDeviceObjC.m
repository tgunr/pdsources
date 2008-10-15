//
//  DACALDevice.m
//  PickADisk
//
//  Created by Jack Small on 9/3/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "DACALDeviceObjC.h"
#import "PADOperationOpenDevice.h"
#import "PADOperationControlDevice.h"

CFStringRef		kPADClientIdentifier = CFSTR("PAD.DACAL.CLIENT");

//	Externally referenced

NSString*	kDACSlotReservationKeyTime			= @"DACResTime";
NSString*	kDACSlotReservationKeyType			= @"DACResType";
NSString*	kDACSlotReservationKeyUser			= @"DACResUser";
NSString*	kDACSlotReservationKeyHost			= @"DACResHost";
NSString*	kDACSlotReservationKeyCountCheckOut	= @"DACResCheckOutCount";

NSString*	kDACSlotReservationTypeCheckOut		= @"DACCheckOut";
NSString*	kDACSlotReservationTypeCheckIn		= @"DACCheckIn";

NSString*	kDACBookmarkLocationInSidebar		= @"_DACSide";
NSString*	kDACBookmarkLocationInMenubar		= @"_DACMenu";
NSString*	kDACBookmarkLocationInBookmarks		= @"_DACBook";

//	Internal constants

NSString*	kDACSlotReservationFileName					= @".reservations";
NSString*	kDACSlotReservationFileNameWithExtension	= @".reservations.plist";


NSMutableArray*		gDACALDevices;

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
	if( self = [super init] )
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


@implementation DACALSlotElement

-(void)dealloc
{
	if( elementSlot ) [elementSlot removeSlotElement:self];
	
	if( elementSlot ) [elementSlot release];
	if( elementNode ) [elementNode release];
	if( elementURL  ) [elementURL  release];
	
	elementSlot = nil;
	elementNode = nil;
	elementURL  = nil;
	
	[super dealloc];
}

-(DACALSlot*)elementSlot
	{ return elementSlot; }

-(void)setElementSlot:(DACALSlot*)newSlot
{ 
	elementSlot = newSlot;

/*	if( !elementSlot || elementSlot != newSlot )
	{
		if( newSlot ) [newSlot retain];
		if( elementSlot ) [elementSlot release];
		elementSlot = newSlot;
	}
 */
}

-(SimpleTreeNode*)elementNode
	{ return elementNode; }

-(void)setElementNode:(SimpleTreeNode*)newNode
{ 
	if( !elementNode || elementNode != newNode )
	{
		if( newNode ) [newNode retain];
		if( elementNode ) [elementNode release];
		elementNode = newNode;
	}
}

-(FSRef*)elementFSRef
	{ return &elementFSRef; }

-(NSURL*)elementURL
	{ return elementURL; }

-(BOOL)isElementFSRef:(const FSRef*)otherFSRef
	{ return( (FSCompareFSRefs( (const FSRef*)&elementFSRef, otherFSRef ) == 0) ? YES : NO ); }

-(BOOL)isElementURL:(NSURL*)otherURL
{
	FSRef	thisFS;
	FSRef	thatFS;
	
	CFURLGetFSRef( (CFURLRef)elementURL, &thisFS );
	CFURLGetFSRef( (CFURLRef)otherURL, &thatFS );
	
	return( (FSCompareFSRefs( (const FSRef*)&thisFS, (const FSRef*)&thatFS ) == 0) ? YES : NO ); 
}

-(BOOL)saveBookmarks
{
	BOOL			didSave = NO;
	NSInteger		markIndex, markCount = [elementBookmarks count];
	NSMutableArray*	markNames = [NSMutableArray arrayWithCapacity:markCount];
	
	for( markIndex=0; markIndex < markCount; markIndex++ )
		[markNames addObject:[[elementBookmarks objectAtIndex:markIndex] markLocation]];
	
	// NSLog(@"Saving Names: %@\nFrom Bookmarks: %@", markNames, elementBookmarks);
	
	didSave = (FSSetXattrProperty( kCFAllocatorDefault, &elementFSRef, kDACALCarouselDocumentXAttrBookmarks, markNames ) == 0);
	
	return didSave;
}

-(void)reloadAttributes
{
	comments	= (NSString*)FSCopyXattr( kCFAllocatorDefault, &elementFSRef, kDACALCarouselDocumentXAttrUserComments, NULL );
	tags		= (NSArray*)FSCopyXattrProperty( kCFAllocatorDefault, &elementFSRef, kDACALCarouselDocumentXAttrUserTags, NULL );
	
	CFStringRef		newStars = FSCopyXattr( kCFAllocatorDefault, &elementFSRef, kDACALCarouselDocumentXAttrUserStars, NULL );
	if( newStars != NULL ) {
		stars = CFStringGetIntValue( newStars );
		CFRelease( newStars );
	} else
		stars = 0;
	
	[elementBookmarks removeAllObjects];
	NSArray*	newMarks = (NSArray*)FSCopyXattrProperty( kCFAllocatorDefault, &elementFSRef, kDACALCarouselDocumentXAttrBookmarks, NULL );
	NSInteger	markIndex, markCount = [newMarks count];
	
	for( markIndex=0; markIndex < markCount; markIndex++ )
		if( [self bookmarkForLocation:[newMarks objectAtIndex:markIndex]] == nil )
			[elementBookmarks addObject:[DACALSlotElementBookmark bookmarkForElement:self atLocation:[newMarks objectAtIndex:markIndex] attachNow:YES]];
	
	for( markIndex=[elementBookmarks count]-1; markIndex >= 0; markIndex-- )
		if( [newMarks indexOfObjectIdenticalTo:[[elementBookmarks objectAtIndex:markIndex] markLocation]] == NSNotFound )
			[elementBookmarks removeObjectAtIndex:markIndex];
	
	//if( comments || tags )
		//NSLog(@"New Element Comment: %@\nTags: %@\nMarks: %@", [comments UTF8String], tags, elementBookmarks );
}

-(id)initElementForSlot:(DACALSlot*)newSlot atLocation:(NSURL*)newLoc
{
	if( self = [super init] )
	{
		elementSlot = newSlot;
		if( !CFURLGetFSRef( (CFURLRef)newLoc, &elementFSRef ) ) {
			NSLog(@"ELement NullRef: %@", self);
			//[self autorelease];
			//return nil;
		}
		elementURL = [newLoc retain];
		elementBookmarks = [[NSMutableArray alloc] initWithCapacity:0];
		
		[self reloadAttributes];
		
		if( newSlot ) [newSlot addSlotElement:self];
	}
	return self;
}

+(id)slotElementForNode:(SimpleTreeNode*)newNode
{
	if( [[newNode nodeData] itemElement] != nil )
		return [[newNode nodeData] itemElement];
	
	DACALSlotElement*	ourElement = DACALDeviceSlotElementForURL( (CFURLRef)[(SimpleNodeData*)[newNode nodeData] location] );
	
	if( ourElement != nil ) {
		[ourElement setElementNode:newNode];
		[[newNode nodeData] setItemElement:ourElement];
	}
	
	return ourElement;
}

+(id)slotElementForSlot:(DACALSlot*)newSlot atLocation:(NSURL*)newLoc
	{ return [[DACALSlotElement alloc] initElementForSlot:newSlot atLocation:newLoc]; }

-(void)updateElementChanges:(BOOL)doAction
	{ [[[[AppController shared] dataView] dataSource] updateChangesForItem:elementNode withAction:doAction]; }

-(void)reloadElement
{
	NSURL*		newURL = (NSURL*)CFURLCreateFromFSRef( kCFAllocatorDefault, [self elementFSRef] );
	
	if( newURL )
	{
		// NSLog(@"Reloading Element: %@", newURL);
		
		[[elementNode nodeData] setLocation:newURL];
		[elementNode reloadDataAndChildren];
		[self reloadAttributes];
		
		[self updateElementChanges:YES];
	}
}

-(NSString*)title 
{
	CFStringRef		itemName = NULL;
	
	itemName = FSCopyXattr( kCFAllocatorDefault, &elementFSRef, kDACALCarouselDocumentXAttrUserTitle, NULL );
	if( itemName == NULL )
		LSCopyDisplayNameForRef( &elementFSRef, &itemName );
	
	return( (NSString*)itemName );
}

-(void)setTitle:(NSString*)newTitle
{
	FSSetXattr( &elementFSRef, kDACALCarouselDocumentXAttrUserTitle, (CFStringRef)newTitle );
	[elementSlot reloadElement:self];
}

-(NSString*)flavor 
{
	CFStringRef		itemName = NULL;
	
	itemName = FSCopyXattr( kCFAllocatorDefault, &elementFSRef, kDACALCarouselDocumentXAttrSlotKind, NULL );
	if( itemName == NULL )	itemName = (CFStringRef)[elementSlot flavor];
	if( itemName == NULL )	itemName = (CFStringRef)PADINDEX_FLAVORVALUE_FILES;
	
	return( (NSString*)itemName );
}

-(void)setFlavor:(NSString*)newFlavor
{
	FSSetXattr( &elementFSRef, kDACALCarouselDocumentXAttrSlotKind, (CFStringRef)newFlavor );
	[elementSlot reloadElement:self];
}

-(BOOL)isCheckedOut
{
	if( !elementSlot ) return NO;
	return [elementSlot isCheckedOut];
}

-(NSDate*)checkedOutDate
{
	if( !elementSlot ) return nil;
	return [elementSlot checkedOutDate];
}

-(NSDate*)checkedInDate
{
	if( !elementSlot ) return nil;
	return [elementSlot checkedInDate];
}

-(NSString*)comments 
{
	return comments;
}

-(void)setComments:(NSString*)newComment
{
	if( !comments || ![comments isEqual:newComment] )
	{
		if( newComment != nil ) [newComment retain];
		if( comments != nil ) [comments release];
		comments = newComment;

		FSSetXattr( &elementFSRef, kDACALCarouselDocumentXAttrUserComments, (CFStringRef)newComment );
		[self updateElementChanges:YES];
	}
	
}

-(NSArray*)tags
{ return tags; }

-(void)setTags:(NSArray*)newTags
{
	if( !tags || ![tags isEqual:newTags] )
	{
		if( newTags != nil ) [newTags retain];
		if( tags != nil ) [tags release];
		tags = newTags;
		
		FSSetXattrProperty( kCFAllocatorDefault, &elementFSRef, kDACALCarouselDocumentXAttrUserTags, (CFPropertyListRef)newTags );
		[self updateElementChanges:YES];
	}
}

-(NSInteger)stars
	{ return stars; }

-(void)setStars:(NSInteger)starLevel
{
	if( stars == starLevel ) return;
	stars = starLevel;
	
	FSSetXattr( &elementFSRef, kDACALCarouselDocumentXAttrUserStars, (CFStringRef)[NSString stringWithFormat:@"%i", starLevel] );
	[self updateElementChanges:YES];
}

-(NSMutableArray*)bookmarks { return elementBookmarks; }

-(BOOL)removeBookmarkForLocation:(NSString*)markLocation
{
	BOOL		didRemove = NO;
	DACALSlotElementBookmark*	foundMark = nil;
	NSInteger	markIndex, markCount = [elementBookmarks count];
	
	for( markIndex=0; markIndex < markCount; markIndex++ )
	{
		foundMark = [elementBookmarks objectAtIndex:markIndex];
		if( [foundMark isBookmarkLocation:markLocation] == YES ) {
			[elementBookmarks removeObject:foundMark];
			[foundMark removeBookmarkForLocation];
			didRemove = YES;
			break;
		}
	}
	
	if( didRemove )
		[self saveBookmarks];
	
	return didRemove;
}

-(DACALSlotElementBookmark*)bookmarkForLocation:(NSString*)markLocation
{
	DACALSlotElementBookmark*	foundMark = nil;
	NSInteger	markIndex, markCount = [elementBookmarks count];
	
	for( markIndex=0; markIndex < markCount; markIndex++ )
	{
		foundMark = [elementBookmarks objectAtIndex:markIndex];
		if( [foundMark isBookmarkLocation:markLocation] == YES )
			break;
		else
			foundMark = nil;
	}
	
	return foundMark;
}

-(DACALSlotElementBookmark*)createBookmarkAtLocation:(NSString*)markLocation attachNow:(BOOL)doAttach
{ 
	DACALSlotElementBookmark* newMark = [self bookmarkForLocation:markLocation];
	
	if( newMark == nil ) {
		newMark = [DACALSlotElementBookmark bookmarkForElement:self atLocation:markLocation attachNow:doAttach]; 
		if( newMark != nil ) {
			[elementBookmarks addObject:newMark];
			[self saveBookmarks];
		}
	}
	
	return newMark;
}

@end		// DACALSlotElement

@implementation DACALSlot

-(void)dealloc
{
	NSLog(@"Dealloc Slot: %@", [self title]);
	
	if( slotDevice )		[slotDevice release];
	if( slotNode )			[slotNode release];
	if( slotElements )		[slotElements release];
	if( slotCheckedOut )	[slotCheckedOut release];
	
	slotDevice = nil;
	slotNode = nil;
	slotElements = nil;
	slotCheckedOut = nil;
	
	[super dealloc];
}

-(DACALDevice*)slotDevice
	{ return slotDevice; }

-(DACALDeviceRef)slotDeviceRef
{ 
	if( slotDevice == nil) return kDACALNullDevice;
	return [slotDevice deviceRef]; 
}

-(DACALSlotNum)slotNumber
	{ return slotNumber; }

-(SimpleTreeNode*)slotNode
	{ return slotNode; }

-(void)setSlotNode:(SimpleTreeNode*)newNode
{ 
	if( !slotNode || slotNode != newNode )
	{
		if( newNode ) [newNode retain];
		if( slotNode ) [slotNode release];
		slotNode = newNode;
	}
}

-(DACVolume*)slotVolume
	{ return slotVolume; }

-(void)setSlotVolume:(DACVolume*)newVolume
{ 
	if( !slotVolume || slotVolume != newVolume )
	{
		if( newVolume ) [newVolume retain];
		if( slotVolume ) [slotVolume release];
		slotVolume = newVolume;
	}
}

-(FSRef*)slotFSRef
	{ return &slotFSRef; }

-(BOOL)setSlotFSRefFromURL:(NSURL*)slotURL
	{ return( (CFURLGetFSRef( (CFURLRef)slotURL, &slotFSRef ) == TRUE) ? YES : NO ); }

-(BOOL)validSlotFSRef
	{ return( BooleanToBOOL(FSIsFSRefValid(&slotFSRef)) ); }

-(BOOL)setSlotLocation:(NSURL*)slotURL
{
	BOOL	goodSet = [self setSlotFSRefFromURL:slotURL];
	
	if( goodSet == YES )
	{		//	Is Checked out?
		
		CFStringRef		checkedOut = NULL;
		CFStringRef		checkedIn = NULL;
		
		if( FSIsFSRefValid( &slotFSRef ) ) {
			checkedOut = FSCopyXattr( kCFAllocatorDefault, &slotFSRef, kDACALCarouselDocumentXAttrSlotCheckout, NULL );
			checkedIn = FSCopyXattr( kCFAllocatorDefault, &slotFSRef, kDACALCarouselDocumentXAttrSlotCheckout, NULL );
			if( checkedIn == NULL )
				checkedIn = FSCopyXattr( kCFAllocatorDefault, &slotFSRef, kDACALCarouselDocumentXAttrSlotAddDate, NULL );
		}
		
		if( checkedOut != NULL ) 
			[self setCheckedOutDate:[[NSDate alloc] initWithString:(NSString*)checkedOut]];
		else
			[self setCheckedOutDate:nil];
		
		if( checkedIn != NULL ) 
			[self setCheckedInDate:[[NSDate alloc] initWithString:(NSString*)checkedIn]];
		else
			[self setCheckedInDate:nil];
	}
	
	return goodSet;
}

-(NSMutableArray*)slotElements
	{ return slotElements; }

-(void)setSlotElements:(NSMutableArray*)newElements
{ 
	if( !slotElements || slotElements != newElements )
	{
		if( newElements ) [newElements retain];
		if( slotElements ) [slotElements release];
		slotElements = newElements;
		
		[slotElements makeObjectsPerformSelector:@selector(setElementSlot:) withObject:self];
	}
}

-(void)addSlotElement:(DACALSlotElement*)newElement
{
	if( [slotElements indexOfObject:newElement] == NSNotFound )
	{
		[slotElements addObject:newElement];
		[newElement retain];
	}
}

-(void)removeSlotElement:(DACALSlotElement*)oldElement
{
	if( [slotElements indexOfObject:oldElement] != NSNotFound )
		[slotElements removeObject:oldElement];
}

-(DACALSlotElement*)elementWithFSRef:(const FSRef*)otherFSRef
{
	DACALSlotElement*		foundElement = nil;
	int						eIndex, eCount = [slotElements count];
	
	for( eIndex=0; eIndex < eCount; eIndex++ )
	{
		foundElement = [slotElements objectAtIndex:eIndex];
		if( [foundElement isElementFSRef:otherFSRef] ) break;
		foundElement = nil;
	}
	return foundElement;
}
	
-(DACALSlotElement*)elementWithURL:(NSURL*)otherURL
{
	DACALSlotElement*		foundElement = nil;
	int						eIndex, eCount = [slotElements count];
	
	for( eIndex=0; eIndex < eCount; eIndex++ )
	{
		foundElement = [slotElements objectAtIndex:eIndex];
		if( [foundElement isElementURL:otherURL] ) break;
		foundElement = nil;
	}
	return foundElement;
}

-(id)initSlotForDevice:(DACALDevice*)newDevice inSlot:(DACALSlotNum)newSlot
{
	if( self = [super init] )
	{
		slotDevice = [newDevice retain];
		slotNumber = newSlot;
		slotCheckedOut = nil;
		
		slotElements = [[NSMutableArray alloc] initWithCapacity:0];
	}
	return self;
}

+(id)slotForDevice:(DACALDevice*)newDevice inSlot:(DACALSlotNum)newSlot
	{ return [[DACALSlot alloc] initSlotForDevice:newDevice inSlot:newSlot]; }

-(NSString*)title 
{
	return [NSString stringWithFormat:NSLocalizedString(@"Slot %i", "DACALSlot Title Format for a specific slot"), [self slotNumber]]; 
}

-(void)swapWithSlot:(DACALSlot*)otherSlot
{
	DACALResult			theErr = kDACALError;
	SimpleTreeNode*		swapNode = nil;
	DACVolume*			swapVolume = nil;
	NSDate*				swapOutDate = nil;
	NSDate*				swapInDate = nil;
	NSMutableArray*		swapElements = nil;
	
	theErr = DACALSlotMove( [[self slotDevice] deviceRef], [self slotNumber], [[otherSlot slotDevice] deviceRef], [otherSlot slotNumber] );
	
	if( theErr == 0 )
	{
		swapNode = [[self slotNode] retain];
		swapVolume = [[self slotVolume] retain];
		swapElements = [[self slotElements] retain];
		
		if( [self isCheckedOut] == YES )
			swapOutDate = [[self checkedOutDate] retain];
		swapInDate = [[self checkedInDate] retain];
		
		[self setSlotNode:[otherSlot slotNode]];
		[self setSlotVolume:[otherSlot slotVolume]];
		[self setSlotElements:[otherSlot slotElements]];
		[self setCheckedOutDate:[otherSlot checkedOutDate]];
		[self setCheckedInDate:[otherSlot checkedInDate]];
		
		[otherSlot setSlotNode:swapNode];
		[otherSlot setSlotVolume:swapVolume];
		[otherSlot setSlotElements:swapElements];
		[otherSlot setCheckedOutDate:swapOutDate];
		[otherSlot setCheckedInDate:swapInDate];
		
		//[swapNode release];
		//[swapElements release];
		
		[self reloadSlot];
		[otherSlot reloadSlot];
	}
	
	if( theErr != 0 )
		NSLog(@"Error:%i Changing Slot", (int)theErr);
	
	[AppController playUISoundForResult:theErr];
}

-(void)reloadSlot
{
	NSURL*		newURL = [self fileURL];
	
	if( newURL )
	{
		// NSLog(@"Reloading Slot: %@", newURL);
		[[slotNode nodeData] setLocation:newURL];
		[slotNode reloadData:nil reloadChildren:NO];
		
		if( (slotElements != nil) && ([slotElements count] > 0) )
		{
			[slotElements makeObjectsPerformSelector:@selector(reloadElement)];
			[[PADSearchService sharedSearch] searchDataChanged:slotElements];
			
			//[[[[AppController shared] dataView] dataSource] sortExpandedChildrenWithCurrentDescriptors:nil];
			//[[[[AppController shared] dataView] outlineView] reloadData];
		}
		//else
			// NSLog(@"Empty Slot Elements: %@", slotElements);
	}
	
}

-(void)reloadElement:(DACALSlotElement*)theElement
{
	if( theElement == nil ) return;
	
	[theElement reloadElement];
	[[PADSearchService sharedSearch] searchDataChanged:[NSArray arrayWithObject:theElement]];
	
	[[[[AppController shared] dataView] dataSource] updateChangesWithAction:YES];
	//[[[[AppController shared] dataView] dataSource] sortExpandedChildrenWithCurrentDescriptors:nil];
	//[[[[AppController shared] dataView] outlineView] reloadData];	
}

-(NSURL*)fileURL
{
	NSURL*		newURL = nil; // (NSURL*)CFURLCreateFromFSRef( kCFAllocatorDefault, [self slotFSRef] );
	if( newURL == nil ) 
	{
		newURL = (NSURL*)CFURLCreateWithFileSystemPathRelativeToBase( kCFAllocatorDefault, (CFStringRef)[self title], kCFURLPOSIXPathStyle, TRUE, (CFURLRef)[slotDevice fileURL] );
		CFURLGetFSRef( (CFURLRef)newURL, &slotFSRef );
	}
	return newURL;	
}

-(NSString*)flavor 
{
	CFStringRef		itemName = NULL;
	
	itemName = FSCopyXattr( kCFAllocatorDefault, &slotFSRef, kDACALCarouselDocumentXAttrSlotKind, NULL );
	if( itemName == NULL ) itemName = (CFStringRef)PADINDEX_FLAVORVALUE_FILES;
	
	return( (NSString*)itemName );
}

-(void)setFlavor:(NSString*)newFlavor
{
	FSSetXattr( &slotFSRef, kDACALCarouselDocumentXAttrSlotKind, (CFStringRef)newFlavor );
	[self reloadSlot];
}

-(DACALResult)moveDeviceToSlotWithOptions:(DACALOptionBits)slotOptions
	{ return DACALCommandMoveToSlotWithOptions( [self slotDeviceRef], [self slotNumber], slotOptions ); }

-(BOOL)isCheckedOut
	{ return (slotCheckedOut != nil); }

-(NSDate*)checkedOutDate
	{ return slotCheckedOut; }

-(void)setCheckedOutDate:(NSDate*)newDate
{ 
	if( !slotCheckedOut || slotCheckedOut != newDate )
	{
		if( newDate ) [newDate retain];
		if( slotCheckedOut ) [slotCheckedOut release];
		slotCheckedOut = newDate;
	}
}

-(NSDate*)checkedInDate
{ return slotCheckedIn; }

-(void)setCheckedInDate:(NSDate*)newDate
{ 
	if( !slotCheckedIn || slotCheckedIn != newDate )
	{
		if( newDate ) [newDate retain];
		if( slotCheckedIn ) [slotCheckedIn release];
		slotCheckedIn = newDate;
	}
}

-(NSDictionary*)currentReservation
{
	NSDictionary*			manifestDict = [self reservationHistory];
	NSDictionary*			thisReservation = nil;
	NSDate*					checkOutDate = [self checkedOutDate];
	NSDate*					checkInDate = [self checkedInDate];
	
	if( manifestDict != nil ) {
		if( checkOutDate != nil )
			thisReservation = [manifestDict objectForKey:[checkOutDate description]];
		else
			thisReservation = [manifestDict objectForKey:[checkInDate description]];
	}
	
	return thisReservation;
}

-(NSDictionary*)reservationHistory
{
	NSURL*					manifestURL = [NSURL URLWithString:kDACSlotReservationFileNameWithExtension relativeToURL:[self fileURL]];
	NSDictionary*			manifestDict = nil;

	if( manifestURL != nil )
		[NSDictionary dictionaryWithContentsOfURL:manifestURL];
	
	return manifestDict;
}

-(BOOL)checkOutForUser:(NSString*)userName onHost:(NSString*)userHost
{
	BOOL					didWork = NO;
	NSURL*					manifestURL = [NSURL URLWithString:kDACSlotReservationFileNameWithExtension relativeToURL:[self fileURL]];
	NSDictionary*			manifestDict = [NSDictionary dictionaryWithContentsOfURL:manifestURL];
	NSMutableDictionary*	newManDict = [NSMutableDictionary dictionaryWithCapacity:0];
	NSMutableDictionary*	newManEntry = [NSMutableDictionary dictionaryWithCapacity:0];
	NSDate*					newDate = [NSDate date];
	NSInteger				newCount = 0;
	
	if( BOOLToBoolean([self isCheckedOut]) ) return didWork;
	
	if( manifestURL != nil )
	{
		if( manifestDict != nil ) {
			[newManDict addEntriesFromDictionary:manifestDict];
			newCount = [[newManDict objectForKey:kDACSlotReservationKeyCountCheckOut] integerValue];
		}
		
		newCount++;
		[newManDict setValue:[NSNumber numberWithInteger:newCount]
					  forKey:kDACSlotReservationKeyCountCheckOut];
		
		[newManEntry setValue:newDate		forKey:kDACSlotReservationKeyTime];
		[newManEntry setValue:userName		forKey:kDACSlotReservationKeyUser];
		[newManEntry setValue:userHost		forKey:kDACSlotReservationKeyHost];
		[newManEntry setValue:kDACSlotReservationTypeCheckOut
					   forKey:kDACSlotReservationKeyType];
		
		[newManDict setValue:newManEntry	forKey:[newDate description]];
		didWork = [newManDict writeToURL:manifestURL atomically:YES];
		
		if( didWork ) {
			FSSetXattr( &slotFSRef, kDACALCarouselDocumentXAttrSlotCheckout, (CFStringRef)[newDate description] );
			[self setCheckedOutDate:newDate];
		}
	}
	
	[self reloadSlot];
	
	// NSLog(@"Slot Checkout:%@\nManifset URL:%@\nManifest Dictionary:%@", self, manifestURL, manifestDict);
	
	return didWork;
}



-(BOOL)checkInForUser:(NSString*)userName onHost:(NSString*)userHost
{
	BOOL					didWork = NO;
//	NSDate*					checkOutDate = [self checkedOutDate];
	NSURL*					manifestURL = [NSURL URLWithString:kDACSlotReservationFileNameWithExtension relativeToURL:[self fileURL]];
	NSDictionary*			manifestDict = [NSDictionary dictionaryWithContentsOfURL:manifestURL];
//	NSDictionary*			checkInEntry = [manifestDict objectForKey:[checkOutDate description]];
	NSMutableDictionary*	newManDict = [NSMutableDictionary dictionaryWithCapacity:0];
	NSMutableDictionary*	newManEntry = [NSMutableDictionary dictionaryWithCapacity:0];
	NSDate*					newDate = [NSDate date];
	
	if( manifestURL == nil ) return didWork;
	
//	if( checkInEntry != nil )
	{
		if( manifestDict != nil )
			[newManDict addEntriesFromDictionary:manifestDict];
		
		[newManEntry setValue:newDate		forKey:kDACSlotReservationKeyTime];
		[newManEntry setValue:userName		forKey:kDACSlotReservationKeyUser];
		[newManEntry setValue:userHost		forKey:kDACSlotReservationKeyHost];
		[newManEntry setValue:kDACSlotReservationTypeCheckIn
					   forKey:kDACSlotReservationKeyType];
		
		[newManDict setValue:newManEntry	forKey:[newDate description]];
		didWork = [newManDict writeToURL:manifestURL atomically:YES];
		
		if( didWork ) {
			FSSetXattr( &slotFSRef, kDACALCarouselDocumentXAttrSlotCheckout, (CFStringRef)NULL );
			FSSetXattr( &slotFSRef, kDACALCarouselDocumentXAttrSlotCheckIn, (CFStringRef)[newDate description] );
			[self setCheckedOutDate:nil];
			[self setCheckedInDate:newDate];
		}
		
		if( [[slotNode nodeData] itemAddDate] == nil ) {
			FSSetXattr( &slotFSRef, kDACALCarouselDocumentXAttrSlotAddDate, (CFStringRef)[newDate description] );
			[[slotNode nodeData] setItemAddDate:newDate];
		}
	}
	
	[self reloadSlot];
	
	// NSLog(@"Slot Check In:%@\nManifset URL:%@\nManifest Dictionary:%@", self, manifestURL, manifestDict);
	
	return didWork;
}

-(BOOL)toggleReservationForUser:(NSString*)userName	onHost:(NSString*)userHost
{
	NSString*		user = (userName == nil) ? NSFullUserName() : userName;
	NSString*		host = (userHost == nil) ? [[NSHost currentHost] name] : userHost;
	BOOL			goodCheck = NO;
	DACALResult		goodMove = kDACALError;
	
	if( [self isCheckedOut] == YES )
		goodCheck = [self checkInForUser:user onHost:host];
	else
		goodCheck = [self checkOutForUser:user onHost:host];
	
	goodMove = [self moveDeviceToSlotWithOptions:kDACALOptionMoveOnce];
	
	[AppController playUISoundForResult: (goodCheck == YES) ? kDACALOK : kDACALError];

	return goodCheck;
}

@end		// DACALSlot


@implementation DACALDevice

-(void)dealloc
{
	if( deviceRef ) CFRelease( (CFTypeRef)deviceRef );
	if( deviceNode ) [deviceNode release];
	if( deviceSlots ) [deviceSlots release];
	
	deviceRef = kDACALNullDevice;
	deviceNode = nil;
	deviceSlots = nil;
	
	[super dealloc];
}

-(DACALDeviceRef)deviceRef
	{ return deviceRef; }

-(void)setDeviceRef:(DACALDeviceRef)newDevice
	{ deviceRef = newDevice; }

-(BOOL)isDeviceRef:(DACALDeviceRef)aDevice
{ 
	if( (aDevice==kDACALNullDevice) || (deviceRef==kDACALNullDevice) ) return NO;
	
	return (CFEqual((CFTypeRef)deviceRef, (CFTypeRef)aDevice )) ? YES : NO;
}

-(SimpleTreeNode*)deviceNode
	{ return deviceNode; }

-(void)setDeviceNode:(SimpleTreeNode*)newNode
{ 
	if( !deviceNode || deviceNode != newNode )
	{
		if( newNode ) [newNode retain];
		if( deviceNode ) [deviceNode release];
		deviceNode = newNode;
	}
}

-(FSRef*)deviceFSRef
	{ return &deviceFSRef; }

-(NSArray*)deviceSlots
	{ return deviceSlots; }

-(DACALSlot*)slotWithNumber:(DACALSlotNum)aSlot
{
	int		slotIndex = aSlot - 1;
	
	if( (slotIndex >= 0) && (slotIndex <= [deviceSlots count]) )
		return [deviceSlots objectAtIndex:slotIndex];
	
	return nil;
}

-(void)loadSlotIndex
{
	DACALSlot*			theSlot = nil;
	SimpleTreeNode*		theChildNode = [self deviceNode];
	SimpleTreeNode*		theSubtreeNode = [[theChildNode nodeData] subTree];
	SimpleTreeNode*		theSubtreeChild;
	NSArray*			slotFolders = nil;
	DACALDeviceRef		theBoxRef = [self deviceRef];
	DACALSlotNum		slotNum;
	CFStringRef			theSlotTitle;
	CFURLRef			slotTopURL;
	NSURL*				slotURL;
	
	int					slotindex, slotcount;
	
	[theChildNode setBusy:YES];
	
	slotFolders = (NSArray*)DACALCommandCopyAllSlotPaths( theBoxRef, NULL );
	slotcount = [slotFolders count];
	for( slotindex = 1; slotindex <= slotcount; slotindex++ )
	{	
		slotNum = CFURLGetSlotNumber( (CFURLRef)[slotFolders objectAtIndex:slotindex-1], FALSE );
		theSlot = [[self slotWithNumber:slotNum] retain];
		
		theSlotTitle = DACALSlotCopyTitle( theBoxRef, slotNum, NULL );
		if( theSlotTitle != NULL ) {															// Create a url to the slot
			slotURL = [slotFolders objectAtIndex:slotindex-1];
			[theSlot setSlotLocation:slotURL];													// Save a FSRef while we know where it slot is			
			
			slotTopURL = CFURLCreateCopyAppendingPathComponent( NULL, (CFURLRef)slotURL, (CFStringRef) theSlotTitle, TRUE );
			
			//theSubtreeChild = [SimpleTreeNode treeOperationFromLocation:(NSURL*)slotURL];
			theSubtreeChild = [SimpleTreeNode treeFromLocation:(NSURL*)slotTopURL];
			[theSlot setSlotNode:theSubtreeChild];
			
			[theSubtreeNode insertChild:theSubtreeChild atIndex:[theSubtreeNode numberOfChildren]];
			
			CFRelease( theSlotTitle );
			//CFRelease( slotTopURL );
			
			slotsUsed++;
		}
	}	
	
	[theSlot retain];
	[theChildNode setBusy:NO];
	
	if( slotFolders ) [slotFolders release];
}

-(id)initDeviceWithDeviceRef:(DACALDeviceRef)newDeviceRef
{
	if( self = [super init] )
	{
		deviceRef = newDeviceRef;
		
		if( !gDACALDevices ) gDACALDevices = [[NSMutableArray alloc] initWithCapacity:0];
		[gDACALDevices addObject:self];
		
		int					tempIndex, tempCount = DACALCommandGetSlotCount( newDeviceRef );
		NSMutableArray*		tempArray = [NSMutableArray arrayWithCapacity:tempCount];
		
		for( tempIndex=0; tempIndex < tempCount; tempIndex++ )
			[tempArray addObject:[DACALSlot slotForDevice:self inSlot:tempIndex+1]];
		
		deviceSlots = [[NSArray alloc] initWithArray:tempArray];
		
		CFURLRef			tempURL = DACALCommandCopyPath( newDeviceRef, NULL );
		CFURLGetFSRef( tempURL, &deviceFSRef );

		SimpleTreeNode*		theWorkNode = [[[[DACALTreeDataSource shared] treeControl] treeRoot] childWithItemType:kPADTypeGroupDevices];
		SimpleTreeNode*		theChildNode;
		SimpleTreeNode*		theSubtreeNode;
		
		NSString*			boxName = (NSString*)DACALCommandCopyName( newDeviceRef, NULL );
		CFURLRef			boxURL = DACALCommandCopyPath( newDeviceRef, NULL );
				
		theChildNode = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData leafDataWithName:boxName] parent:nil children:[[NSArray alloc] init]];
		
		deviceNode = theChildNode;
		
		[[theChildNode nodeData] setLocation: [(NSURL*)boxURL retain]];
		[[theChildNode nodeData] setIconRep:DACALGetIconImageForType( kDACALCarouselsFolderType )];			// Use the box icon		
		[[theChildNode nodeData] setItemType: kPADTypeIndexDevice];											// Set device type
		
		[[theChildNode nodeData] setItemDevice:newDeviceRef];												// Save UUID
		
		// Create subtree root
		theSubtreeNode = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData groupDataWithName:boxName] parent:nil children:[[NSArray alloc] init]];
		[[theSubtreeNode nodeData] setExpanded:YES];														// Root level is always expanded
		[[theSubtreeNode nodeData] setIconRep:DACALGetIconImageForType( kDACALCarouselsFolderType )];		// Put the icon on it for the path control
		[[theChildNode nodeData] setSubTree:theSubtreeNode];
		
		// Hookup and refresh
		[theWorkNode insertChild:theChildNode atIndex:[theWorkNode numberOfChildren]];
		[[DACALTreeDataSource shared] orderForUser:[[[DACALTreeDataSource shared] treeControl] treeRoot]];
		[[[[DACALTreeDataSource shared] treeControl] outlineView] reloadItem:(id)theWorkNode reloadChildren:YES];
		[[DACALTreeDataSource shared] setPrompt:[NSString stringWithFormat:@"%@ attached", boxName]];
		
		if( boxName )	[boxName release];
		if( boxURL )	CFRelease( boxURL );	
	}
	return self;	
}

+(id)deviceWithDeviceRef:(DACALDeviceRef)newDeviceRef
	{ return [[DACALDevice alloc] initDeviceWithDeviceRef:newDeviceRef]; }

-(void)indexDeviceControlFinished:(id)sender
{
	[AppController playUISound: kASSystemSoundSuccess];
}

-(void)indexedNewVolume:(DACVolume*)newVolume forSlot:(DACALSlotNum)newSlot ofType:(NSString*)newType
{
	CFURLRef		slotURL = DACALSlotCopyPath( deviceRef, newSlot, NULL );
	
	if( slotURL ) {
	//	CFURLSetXattr( slotURL, kDACALCarouselDocumentXAttrSlotAddDate, (CFStringRef)[[NSDate date] description] );
		CFURLSetXattr( slotURL, kDACALCarouselDocumentXAttrSlotKind, (CFStringRef)newType );
		
		NSURL*		iconURL = [NSURL URLWithString:@".DACDiscIcon.icns" relativeToURL:(NSURL*)slotURL];
		
		CFDictionaryRef	volumeData = DADiskCopyDescription( [newVolume volumeDiskRef] );
		if( volumeData == NULL ) goto NOVOLUMEDATA;

		//	Aquire the media "type" icon
		CFDictionaryRef	workDict = CFDictionaryGetValue( volumeData, CFSTR("DAMediaIcon") );
		if( workDict )
		{
			CFStringRef			bundleIDString = CFDictionaryGetValue( workDict, CFSTR("CFBundleIdentifier") );
			CFStringRef			iconResFile = CFDictionaryGetValue( workDict, CFSTR("IOBundleResourceFile") );
			NSURL*				iconFileURL = nil;
			if( iconResFile && bundleIDString ) {
				CFBundleRef		theIconBundle = CFBundleGetBundleWithIdentifier( bundleIDString );
				if( theIconBundle ) 
					iconFileURL = (NSURL*)CFBundleCopyResourceURL( theIconBundle, iconResFile, NULL, NULL );
				if( iconFileURL )
					[[NSFileManager defaultManager] copyItemAtPath:[iconFileURL path] toPath:[iconURL path] error:nil];
				//else NSLog( @"Bad Icon File URL: Bundle:%@ ID:%@ Name:%@", theIconBundle, bundleIDString, iconResFile );
			}
		}
		CFRelease( volumeData );
		
	NOVOLUMEDATA:
			
		CFRelease( slotURL );
	}
	
	// Go ahead and check it in
	[[self slotWithNumber:newSlot] checkInForUser:NSFullUserName() onHost:[[NSHost currentHost] name]];
	slotsUsed++;
	
	[[DACALTreeDataSource shared] slotAddedToDevice: deviceRef forSlot: newSlot];
	//[[PADSearchService sharedSearch] searchDataChanged:[NSArray array]];
		
	[PADOperationControlDevice finishIndexingVolume:[newVolume volumePath] forSlot:newSlot onDevice:self forTarget:self];	
}

-(NSString*)title
	{ return( (NSString*)DACALCommandCopyName( deviceRef, NULL ) ); }

-(NSURL*)fileURL
	{ return( (NSURL*)DACALCommandCopyPath( deviceRef, NULL ) ); }

-(void)detachingDevice
{
	SimpleTreeNode*		boxNode = deviceNode;
	//SimpleTreeNode*		boxParent = (SimpleTreeNode*)[boxNode nodeParent];

	[[AppController shared] cancelOperationsForDevice:self];
	
	[boxNode removeFromParent];
	[self setDeviceNode:nil];
	
	[[[[AppController shared] dataView] dataSource] updateChangesWithAction:YES];
	//[[[[DACALTreeDataSource shared] treeControl] outlineView] reloadItem:(id)boxParent reloadChildren:YES];
	//[[DACALTreeDataSource shared] doAction];
	
	NSLog( @"Detached Device: %@", [self title] );
	[self release];
}

-(void)attachedDevice:(DACALDevice*)newBox
{	

	[PADSearchService performSelector:@selector(updateAllSearches) withObject:nil afterDelay:0.42];
	[[DACALTreeDataSource shared] doAction];

	NSLog( @"Attached Device: %@", [self title] );
}
		
-(void)attachingDevice
	{ [PADOperationOpenDevice addDeviceToSourceTree:self]; }


-(void)swapSlotNumber:(DACALSlotNum)fromSlotNum toDevice:(DACALDevice*)toBox toSlotNumber:(DACALSlotNum)toSlotNum
{
	if( toBox == nil ) toBox = self;
	
	DACALSlot*	fromSlot = [self slotWithNumber:fromSlotNum];
	DACALSlot*	destSlot = [toBox slotWithNumber:toSlotNum];
	
	[fromSlot swapWithSlot:destSlot];
	
}

-(NSInteger)slotsUsed
	{ return slotsUsed; }

@end		// DACALDevice

void DACALNotification( void* inData, DACALDeviceRef inBox, CFStringRef inMessage, CFDictionaryRef inParam );
void DACALNotification( void* inData, DACALDeviceRef inBox, CFStringRef inMessage, CFDictionaryRef inParam )
{
	DACALDevice*	inDevice = nil;
	
	//NSLog( @"Client Notification: Device: %@ Message: %@", inBox, inMessage );
	
	if( CFStringHasPrefix( inMessage, kDACALCarouselNoticeDeviceOpen ) )
	{
		inDevice = [DACALDevice deviceWithDeviceRef:inBox];
		[inDevice attachingDevice];
		
		//NSLog(@"isDriverKextLoaded: %@", [DACDriverInstaller versionOfDriverKextLoaded]);
	} 
	else if( CFStringHasPrefix( inMessage, kDACALCarouselNoticeDeviceClose ) )
	{
		inDevice = DACALDeviceForDeviceRef(inBox);
		[inDevice detachingDevice];
	}
}

void DACALSetup( void )
{
	DACALRegisterIconResource( CFSTR("DC300Black"), kDACALCarouselsFolderType );
	DACALRegisterIconResource( CFSTR("CDAudio"), 'cdda' );
	DACALRegisterIconResource( CFSTR("DVD-Video"), 'dvd ' );
	DACALRegisterIconResource( CFSTR("CD-silver"), 'Dcd ' );
	
	DACALRegisterIconResource( CFSTR("Generic_Files"), 'gFil' );
	DACALRegisterIconResource( CFSTR("Generic_Music"), 'gMus' );
	DACALRegisterIconResource( CFSTR("Generic_Movie"), 'gMov' );
	DACALRegisterIconResource( CFSTR("Generic_Image"), 'gImg' );
	
	[DACVolumeService sharedVolumeService];
	
	DACALClientCreate( kCFAllocatorDefault, kPADClientIdentifier, NULL, DACALNotification );
}

void			DACALClientInitialize(void)
{
	gDACALDevices = [[NSMutableArray alloc] initWithCapacity:0];
	DACALDevicesInitialize();
}

DACALDevice*	DACALDeviceForDeviceRef(DACALDeviceRef aBoxRef)
{
	DACALDevice*	foundBox = nil;
	int				boxIndex, boxCount = [gDACALDevices count];

	for( boxIndex=0; boxIndex < boxCount; boxIndex++ )
	{
		foundBox = [gDACALDevices objectAtIndex:boxIndex];
		if( [foundBox isDeviceRef:aBoxRef] ) break;
		foundBox = nil;
	}

	return foundBox;
 }
 
DACALSlot*		DACALDeviceSlotForSlotNumber(DACALDeviceRef aBoxRef, DACALSlotNum aSlotNum)
{
	DACALDevice*	slotBox = DACALDeviceForDeviceRef( aBoxRef );
	DACALSlot*		foundSlot = nil;
	
	if( slotBox )
		foundSlot = [slotBox slotWithNumber:aSlotNum];
	
	return foundSlot;
}

DACALSlotElement*	DACALDeviceSlotElementForURL( CFURLRef itemURL )
{
	DACALDeviceRef		searchDevice = CFURLCopyCarouselUUID( kCFAllocatorDefault, itemURL );
	DACALSlotNum		searchSlotNum = CFURLGetSlotNumber( itemURL, FALSE );
	DACALSlot*			searchSlot = DACALDeviceSlotForSlotNumber( searchDevice, searchSlotNum );
	//	FSRef				searchFSRef;
	//	Boolean				searchFound = FALSE;
	DACALSlotElement*	foundElement = nil;
	
	if(searchSlot != nil )
	{
		foundElement = [searchSlot elementWithURL:(NSURL*)itemURL];
		if( foundElement == nil ) {
			foundElement = [DACALSlotElement slotElementForSlot:searchSlot atLocation:(NSURL*)itemURL];
		}
	}
	
	if( searchDevice ) CFRelease( (CFTypeRef)searchDevice );
	return foundElement;
}

