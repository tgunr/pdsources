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
#import "LicenseService.h"

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

//	Discovery Keys

NSString*	kDACDiscKeyCheckIn					= @"PADCheckInEject";
NSString*	kDACDiscKeyCheckOut					= @"PADCheckOutMount";
NSString*	kDACDiscKeyRecognized				= @"PADKnownDiscEject";
NSString*	kDACDiscKeyUnrecognized				= @"PADNewDiscMounted";

//	Discovery Values

NSInteger	kDACDVCheckInOpenToSlot				= 0;
NSInteger	kDACDVCheckInDisplayDetails			= 1;
NSInteger	kDACDVCheckInOpenAndDisplay			= 2;
NSInteger	kDACDVCheckInDoNothing				= 4;

NSInteger	kDACDVCheckOutAutoMatch				= 0;
NSInteger	kDACDVCheckOutCloseDoor				= 1;
NSInteger	kDACDVCheckOutMatchAndCloseDoor		= 2;
NSInteger	kDACDVCheckOutDoNothing				= 4;

NSInteger	kDACDVKnownIDAutoCheckIn			= 0;
NSInteger	kDACDVKnownIDDoNothing				= 2;

NSInteger	kDACDVUnknownIDDisplayAddWindow		= 0;
NSInteger	kDACDVUnknownIDAutoAssignToNextSlot	= 1;
NSInteger	kDACDVUnknownIDBeginBatchMode		= 2;
NSInteger	kDACDVUnknownIDDoNothing			= 4;

//	Slot Files

NSString*	kDACSlotReservationFileName					= @".reservations";
NSString*	kDACSlotReservationFileNameWithExtension	= @".reservations.plist";

NSString*	kDACSlotIconFileNameWithExtension			= @".DACDiscIcon.icns";

//	Device Array

//NSMutableArray*		gDACALDevices;

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

-(NSUndoManager*)undoMananger
{
//	SimpleTreeNode*		ourNode = [self elementNode];
	NSUndoManager*		ourUndo = nil;
	
//	if( ourNode )
//		ourUndo = [ourNode undoManager];		// theNode does not have an undoManager!
	
	return ourUndo;
}

-(FSRef*)elementFSRef
	{ return &elementFSRef; }

-(NSURL*)elementURL
	{ return elementURL; }

-(BOOL)isElementFSRef:(const FSRef*)otherFSRef
	{ return( (FSCompareFSRefs( (const FSRef*)&elementFSRef, otherFSRef ) == 0) ? YES : NO ); }

-(BOOL)isElementURL:(NSURL*)otherURL
{
	return [elementURL isEqual:otherURL];
	
	FSRef	thisFS;
	FSRef	thatFS;
	
	CFURLGetFSRef( (CFURLRef)elementURL, &thisFS );
	CFURLGetFSRef( (CFURLRef)otherURL, &thatFS );
	
	return( (FSCompareFSRefs( (const FSRef*)&thisFS, (const FSRef*)&thatFS ) == 0) ? YES : NO ); 
}

-(NSURL*)mountedURL
{
	NSURL*		outURL = nil;
	DACVolume*	ourVolume = [[self elementSlot] slotVolume];
	NSString*	relPathStr = [elementNode absolutePathString];
	NSString*	wholePath = nil;
	
	if( ourVolume && relPathStr ) {
		wholePath = [NSString stringWithFormat:@"%@/%@", [ourVolume volumePath], relPathStr];
		outURL = [NSURL fileURLWithPath:wholePath];
	}
	
	return outURL;
}

-(BOOL)openMountedElement
{
	BOOL		outGoodMount = NO;
	NSURL*		mountURL = [self mountedURL];
	
//	NSLog(@"URL: %@", mountURL);
	
	if( mountURL )
		outGoodMount = (LSOpenCFURLRef( (CFURLRef)mountURL, NULL ) == 0);
	
	return outGoodMount;
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
	if( slotVolume )		[slotVolume release];
	if( slotIdentifier )	[slotIdentifier release];
	if( slotCheckedOut )	[slotCheckedOut release];
	if( slotCheckedIn )		[slotCheckedIn release];

	if( slotElements )		[slotElements release];

	slotDevice			= nil;
	slotNode			= nil;
	slotVolume			= nil;
	slotIdentifier		= nil;
	slotCheckedOut		= nil;
	slotCheckedIn		= nil;
	slotElements		= nil;
	slotIsCheckedOut	= NO;
	
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
	
	[self setIsCheckedOut:NO];
	
	if( goodSet == YES )
	{		//	Is Checked out?
		
		CFStringRef		checkedOut = NULL;
		CFStringRef		isCheckedOut = NULL;
		CFStringRef		checkedIn = NULL;
		CFStringRef		slotID = NULL;
		
		if( FSIsFSRefValid( &slotFSRef ) )
		{
			isCheckedOut = FSCopyXattr( kCFAllocatorDefault, &slotFSRef, kDACALCarouselDocumentXAttrSlotIsOut, NULL );
			if( isCheckedOut != NULL ) {
				[self setIsCheckedOut:YES];
				CFRelease( isCheckedOut );
			}
			
			checkedOut = FSCopyXattr( kCFAllocatorDefault, &slotFSRef, kDACALCarouselDocumentXAttrSlotCheckout, NULL );
			checkedIn = FSCopyXattr( kCFAllocatorDefault, &slotFSRef, kDACALCarouselDocumentXAttrSlotCheckIn, NULL );
			if( checkedIn == NULL )
				checkedIn = FSCopyXattr( kCFAllocatorDefault, &slotFSRef, kDACALCarouselDocumentXAttrSlotAddDate, NULL );
			
			slotID = FSCopyXattr( kCFAllocatorDefault, &slotFSRef, kDACALCarouselDocumentXAttrSlotID, NULL );
			if( slotID != NULL ) {
				[self setSlotIdentifier:[[NSString alloc] initWithString:(NSString*)slotID]];
				NSLog(@"%@ has ID: %@", [self title], [self slotIdentifier]);
				CFRelease( slotID );
			}
		}
		
		if( checkedOut != NULL ) {
			[self setCheckedOutDate:[[NSDate alloc] initWithString:(NSString*)checkedOut]];
			CFRelease( checkedOut );
		} else
			[self setCheckedOutDate:nil];
		
		if( checkedIn != NULL ) {
			[self setCheckedInDate:[[NSDate alloc] initWithString:(NSString*)checkedIn]];
			CFRelease( checkedIn );
		} else
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

-(NSString*)slotIdentifier
	{ return slotIdentifier; }

-(void)setSlotIdentifier:(NSString*)newID
{ 
	if( !slotIdentifier || ![slotIdentifier isEqual:newID] )
	{
		if( newID ) [newID retain];
		if( slotIdentifier ) [slotIdentifier release];
		slotIdentifier = newID;
	}
}

-(DACALSlot*)slotWithIdentifier:(NSString*)slotID
{
	DACALSlot*	outSlot = nil;
	
	if( slotIdentifier && ([slotIdentifier compare:slotID] == NSOrderedSame) )
		outSlot = self;
		
	return outSlot;
}

-(id)initSlotForDevice:(DACALDevice*)newDevice inSlot:(DACALSlotNum)newSlot
{
	if( self = [super init] )
	{
		slotDevice = [newDevice retain];
		slotNumber = newSlot;
		
		slotNode = nil;
		slotVolume = nil;
		slotIdentifier = nil;
		slotCheckedOut = nil;
		slotCheckedIn = nil;
		slotIsCheckedOut = NO;
		
		slotElements = [[NSMutableArray alloc] initWithCapacity:0];
		
		[self fileURL];
	}
	return self;
}

+(id)slotForDevice:(DACALDevice*)newDevice inSlot:(DACALSlotNum)newSlot
	{ return [[DACALSlot alloc] initSlotForDevice:newDevice inSlot:newSlot]; }

//	This is "Slot #"
-(NSString*)title 
{
	return [NSString stringWithFormat:NSLocalizedString(@"Slot %i", "DACALSlot Title Format for a specific slot"), [self slotNumber]]; 
}

//	This is the user settable value
-(NSString*)displayTitle
	{ return (NSString*)DACALSlotCopyTitle( [self slotDeviceRef], [self slotNumber], NULL ); }

-(void)swapWithSlot:(DACALSlot*)otherSlot
{
	DACALResult			theErr = kDACALError;
	SimpleTreeNode*		swapNode = nil;
	DACVolume*			swapVolume = nil;
	BOOL				swapIsOut = NO;
	NSDate*				swapOutDate = nil;
	NSDate*				swapInDate = nil;
	NSString*			swapIdentifier = nil;
	NSMutableArray*		swapElements = nil;
	
	theErr = DACALSlotMove( [[self slotDevice] deviceRef], [self slotNumber], [[otherSlot slotDevice] deviceRef], [otherSlot slotNumber] );
	
	if( theErr == 0 )
	{
		swapNode = [[self slotNode] retain];
		swapVolume = [[self slotVolume] retain];
		swapIdentifier = [[self slotIdentifier] retain];
		swapElements = [[self slotElements] retain];
		
		swapIsOut = [self isCheckedOut];
		swapOutDate = [[self checkedOutDate] retain];
		swapInDate = [[self checkedInDate] retain];
		
		[self setSlotNode:[otherSlot slotNode]];
		[self setSlotVolume:[otherSlot slotVolume]];
		[self setSlotIdentifier:[otherSlot slotIdentifier]];
		[self setSlotElements:[otherSlot slotElements]];
		[self setIsCheckedOut:[otherSlot isCheckedOut]];
		[self setCheckedOutDate:[otherSlot checkedOutDate]];
		[self setCheckedInDate:[otherSlot checkedInDate]];
		
		[otherSlot setSlotNode:swapNode];
		[otherSlot setSlotVolume:swapVolume];
		[otherSlot setSlotIdentifier:swapIdentifier];
		[otherSlot setSlotElements:swapElements];
		[otherSlot setIsCheckedOut:swapIsOut];
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

	//newURL = [NSURL URLWithString:[self title] relativeToURL:[slotDevice fileURL]];
	newURL = (NSURL*)CFURLCreateWithFileSystemPathRelativeToBase( kCFAllocatorDefault, (CFStringRef)[self title], kCFURLPOSIXPathStyle, TRUE, (CFURLRef)[slotDevice fileURL] );
	//newURL = (NSURL*)DACALSlotCopyPath( [self slotDeviceRef], [self slotNumber], NULL );
	if( newURL != nil )
		CFURLGetFSRef( (CFURLRef)newURL, &slotFSRef );		// not sure why this happens here
	
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

+(BOOL)moveDevicesToSlotsOfNodes:(NSArray*)theTreeNodes
{
	BOOL				outDidMove = NO;
	NSEnumerator*		nodeEnum = [theTreeNodes objectEnumerator];
	SimpleTreeNode*		workNode = nil;
	DACALSlot*			workSlot = nil;
	DACALSlot*			lastSlot = nil;
	NSMutableArray*		slotArray = [NSMutableArray arrayWithCapacity:0];
	NSEnumerator*		slotEnum = nil;
	BOOL				slotOne = YES;
	
	while ( workNode = [nodeEnum nextObject] ) {
		workSlot = [[[workNode nodeData] itemElement] elementSlot];
		if( [slotArray indexOfObject:workSlot] == NSNotFound )
			[slotArray addObject:workSlot];
	}
	
	slotEnum = [slotArray objectEnumerator];
	
	while ( workSlot = [slotEnum nextObject] ) {
		outDidMove = ([workSlot moveDeviceToSlotWithOptions:kDACALOptionMoveDefault] == kDACALOK);
		if( slotOne )
			slotOne = NO;
		else
			if( lastSlot && [[lastSlot slotDevice] isDeviceRef:[workSlot slotDeviceRef]] )
				sleep( 7.0 );
	
		lastSlot = workSlot;
	}
	
	return outDidMove;
}

+(BOOL)ejectSlotVolumesOfNodes:(NSArray*)theTreeNodes
{
	BOOL				outDidEject = NO;
	NSEnumerator*		nodeEnum = [theTreeNodes objectEnumerator];
	SimpleTreeNode*		workNode = nil;
	DACALSlot*			workSlot = nil;
	NSMutableArray*		slotArray = [NSMutableArray arrayWithCapacity:0];
	NSEnumerator*		slotEnum = nil;
	
	while ( workNode = [nodeEnum nextObject] ) {
		workSlot = [[[workNode nodeData] itemElement] elementSlot];
		if( [slotArray indexOfObject:workSlot] == NSNotFound )
			[slotArray addObject:workSlot];
	}
	
	slotEnum = [slotArray objectEnumerator];
	
	while ( workSlot = [slotEnum nextObject] )
		if( [workSlot slotVolume] )
			outDidEject = [[workSlot slotVolume] ejectVolume];
	
	return outDidEject;
}

-(BOOL)isCheckedOut
	{ return slotIsCheckedOut; }

-(void)setIsCheckedOut:(BOOL)isOut
	{ slotIsCheckedOut = isOut; }

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

-(BOOL)checkOutForUser:(NSString*)userName onHost:(NSString*)userHost withUI:(BOOL)doUI
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
			FSSetXattr( &slotFSRef, kDACALCarouselDocumentXAttrSlotIsOut, (CFStringRef)@"YES" );
			[self setCheckedOutDate:newDate];
			[self setIsCheckedOut:YES];
		}
	}
	
	[self reloadSlot];
	
	// NSLog(@"Slot Checkout:%@\nManifset URL:%@\nManifest Dictionary:%@", self, manifestURL, manifestDict);
	
	if( doUI )
		if( didWork && ([self slotVolume] == nil) )
			didWork = ([self moveDeviceToSlotWithOptions:kDACALOptionMoveDefault] == kDACALOK);
	
	return didWork;
}



-(BOOL)checkInForUser:(NSString*)userName onHost:(NSString*)userHost withUI:(BOOL)doUI
{
	BOOL					didWork = NO;
//	NSDate*					checkOutDate = [self checkedOutDate];
	NSURL*					manifestURL = [NSURL URLWithString:kDACSlotReservationFileNameWithExtension relativeToURL:[self fileURL]];
	NSDictionary*			manifestDict = [NSDictionary dictionaryWithContentsOfURL:manifestURL];
//	NSDictionary*			checkInEntry = [manifestDict objectForKey:[checkOutDate description]];
	NSMutableDictionary*	newManDict = [NSMutableDictionary dictionaryWithCapacity:0];
	NSMutableDictionary*	newManEntry = [NSMutableDictionary dictionaryWithCapacity:0];
	NSDate*					newDate = [NSDate date];
	NSInteger				checkInAction = [[NSUserDefaults standardUserDefaults] integerForKey:kDACDiscKeyCheckIn];
	
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
			FSSetXattr( &slotFSRef, kDACALCarouselDocumentXAttrSlotIsOut, (CFStringRef)NULL );
			FSSetXattr( &slotFSRef, kDACALCarouselDocumentXAttrSlotCheckIn, (CFStringRef)[newDate description] );
			[self setIsCheckedOut:NO];
			[self setCheckedInDate:newDate];
				
			if( [[slotNode nodeData] itemAddDate] == nil ) {
				FSSetXattr( &slotFSRef, kDACALCarouselDocumentXAttrSlotAddDate, (CFStringRef)[newDate description] );
				[[slotNode nodeData] setItemAddDate:newDate];
			}
			
			if( doUI && [self slotVolume] ) 
				[[self slotVolume] ejectVolume];
		}
	}	
	
	[self reloadSlot];
	
	if( doUI && didWork )
		if( (checkInAction == kDACDVCheckInOpenToSlot) || (checkInAction == kDACDVCheckInOpenAndDisplay) )
			didWork = ([self moveDeviceToSlotWithOptions:kDACALOptionMoveDefault] == kDACALOK);

	// NSLog(@"Slot Check In:%@\nManifset URL:%@\nManifest Dictionary:%@", self, manifestURL, manifestDict);

	return didWork;
}

-(BOOL)toggleReservationForUser:(NSString*)userName	onHost:(NSString*)userHost withUI:(BOOL)doUI
{
	NSString*		user = (userName == nil) ? NSFullUserName() : userName;
	NSString*		host = (userHost == nil) ? [[NSHost currentHost] name] : userHost;
	BOOL			alreadyOut = [self isCheckedOut];
	BOOL			goodCheck = NO;
	
	if( alreadyOut == YES )
		goodCheck = [self checkInForUser:user onHost:host withUI:doUI];
	else
		goodCheck = [self checkOutForUser:user onHost:host withUI:doUI];
	
	if( doUI )
		[AppController playUISoundForBOOL:goodCheck];
	
	return goodCheck;
}

-(BOOL)isSlotMounted
	{ return (slotVolume != nil); }

-(NSString*)slotHost
{
	NSString*		outHostName = nil;
	DACVolume*		thisVolume = slotVolume;
	
	if( thisVolume )
		outHostName = [NSString stringWithString:[thisVolume padKnownHost]];
	
	return outHostName;
}

-(BOOL)slotMountedAsVolume:(DACVolume*)mountVolume
{
	BOOL		outClaimedSlot = NO;
	BOOL		wasCheckedIn = ![self isCheckedOut];
	BOOL		wasOurRequest = [[DACVolumeService sharedVolumeService] isPendingMount:[mountVolume padIdentifier]];
	NSInteger	checkOutAction = [[NSUserDefaults standardUserDefaults] integerForKey:kDACDiscKeyCheckOut];

	if( wasOurRequest || ((checkOutAction == kDACDVCheckOutAutoMatch ) || (checkOutAction == kDACDVCheckOutMatchAndCloseDoor)) )
	{
		outClaimedSlot = YES;
		[self setSlotVolume:mountVolume];
		
		if( wasCheckedIn )
			[self toggleReservationForUser:nil onHost:nil withUI:NO];
		else
			[self reloadSlot];

		if( !wasOurRequest )
			[AppController playUISoundForBOOL:[self isCheckedOut]];
	}
	
	if( !wasOurRequest )
		if( (checkOutAction == kDACDVCheckOutCloseDoor ) || (checkOutAction == kDACDVCheckOutMatchAndCloseDoor) )
			[[self slotDevice] commandCloseDoor];
	
	if( outClaimedSlot )
		NSLog(@"Mounted Slot (%@)\nAs Volume: %@", self, mountVolume);
	
	return outClaimedSlot;
}

-(BOOL)slotUnmounted
{
	BOOL	outReleasedSlot = YES;
	BOOL	stillCheckedOut = [self isCheckedOut];
	BOOL	wasOurRequest = [[DACVolumeService sharedVolumeService] isPendingUnmount:[self slotIdentifier]];
	
	[self setSlotVolume:nil];
	
	//	if( user wants to auto checkin & not already handled )
	if( stillCheckedOut )
	{
		if( !wasOurRequest )
			[self moveDeviceToSlotWithOptions:kDACALOptionMoveDefault];
		
		[self toggleReservationForUser:nil onHost:nil withUI:NO];
	}
	[self reloadSlot];

	if( outReleasedSlot )
		NSLog(@"Unmounted Slot (%@)", self);
	
	return outReleasedSlot;
}

-(BOOL)isSlotAssigned
	{ return( slotNode != nil ); }

- (BOOL)slotAssignedIndexFromVolume:(DACVolume*)indexVolume asType:(NSString*)newType
{
	BOOL			outWasAssigned = NO;
	CFURLRef		slotURL = (CFURLRef)[self fileURL];
	
	if( !slotURL ) return outWasAssigned;
	
	CFURLSetXattr( slotURL, kDACALCarouselDocumentXAttrSlotKind, (CFStringRef)newType );
	CFURLSetXattr( slotURL, kDACALCarouselDocumentXAttrSlotID, (CFStringRef)[indexVolume padIdentifier] );
	CFURLSetXattr( slotURL, kDACALCarouselDocumentXAttrVolumeSize, (CFStringRef)[[indexVolume mediaSize] stringValue] );
	
	[self setSlotIdentifier:[indexVolume padIdentifier]];
	
	NSURL*		iconURL = [NSURL URLWithString:kDACSlotIconFileNameWithExtension relativeToURL:(NSURL*)slotURL];
	
	CFDictionaryRef	volumeData = DADiskCopyDescription( [indexVolume volumeDiskRef] );
	if( volumeData != NULL ) {
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
	}
	NSLog(@"Did Icon");

	// Go ahead and check in
	[self checkInForUser:NSFullUserName() onHost:[[NSHost currentHost] name] withUI:NO];
	
	NSLog(@"Checked in");
	
	//	Configure Slot Subtree
	
	NSString*			theSlotTitle = (NSString*)DACALSlotCopyTitle( [self slotDeviceRef], [self slotNumber], NULL );
	NSURL*				theSlotContentPath = (NSURL*)CFURLCreateCopyAppendingPathComponent( NULL, (CFURLRef)slotURL, (CFStringRef)theSlotTitle, TRUE );
	SimpleTreeNode*		theSubtreeNode = nil;
	SimpleTreeNode*		theBoxTreeNode = [[[[self slotDevice] deviceNode] nodeData] subTree]; //[[[self findTreeNodeForDevice:theBoxRef] nodeData] subTree];
	SimpleTreeNode*		theSubtreeChild = nil;
	
	theSubtreeNode = [[[AppController shared] dataView] treeRoot];
	//theSubtreeNode = [[[[AppController shared] dataView] dataSource] treeRoot];
	
	if( theSlotContentPath != nil )
	{
		// Transfer kind xattr to top
		CFURLSetItemFlavor( (CFURLRef)theSlotContentPath, (CFStringRef)newType );
		
		theSubtreeChild = [SimpleTreeNode treeOperationFromLocation:(NSURL*)theSlotContentPath forUI:NO];
		
		[(SimpleNodeData*)[theSubtreeChild nodeData] setName: theSlotTitle];
		[(SimpleNodeData*)[theSubtreeChild nodeData] setItemSlot: [self slotNumber]];
		[(SimpleNodeData*)[theSubtreeChild nodeData] setItemDevice: [self slotDeviceRef]];
		
		NSLog(@"Node established");
		
		[theBoxTreeNode insertChild:theSubtreeChild atIndex:[theBoxTreeNode numberOfChildren]];
		
		[[PADSearchService sharedSearch] searchDataChanged:[NSArray arrayWithObject:theSubtreeChild]];
	}
	
	//[[[[AppController shared] dataView] dataSource] updateChangesWithAction:YES];
	[[[[DACALTreeDataSource shared] secondaryController] dataSource] updateChangesWithAction:YES];
	
	if( theSubtreeChild )
		[[[[DACALTreeDataSource shared] secondaryController] outlineView] performSelector:@selector(selectItems:)
																			   withObject:[NSArray arrayWithObject:theSubtreeChild]
																			   afterDelay:0.2];
	
//		[[[[DACALTreeDataSource shared] secondaryController] outlineView] selectItems:[NSArray arrayWithObject:theSubtreeChild] byExtendingSelection:NO];
	NSLog(@"Updated and selected");
	
	outWasAssigned = YES;
	
	return outWasAssigned;
}

-(BOOL)unassignSlotIndex
{
	BOOL			goodBye = NO;
	DACALResult		workErr = 0;
	
	workErr = DACALSlotDeleteIndex( [self slotDeviceRef], [self slotNumber] );
	if( workErr == kDACALOK )
	{
		[slotNode removeFromParent];
		[slotElements removeAllObjects];
		if( slotVolume )
			[slotVolume setPadKnownSlot:nil];

		[self setSlotNode:nil];	
		[self setSlotVolume:nil];
		[self setSlotIdentifier:nil];
		[self setCheckedInDate:nil];
		[self setCheckedOutDate:nil];		
		slotIsCheckedOut = NO;
		
		[[self slotDevice] indexUnassignedForSlot:self];
		
		goodBye = YES;
	}
	
	return goodBye;
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

-(DACALSlot*)slotWithIdentifier:(NSString*)slotID
{
	NSEnumerator*	slotEnum = [deviceSlots objectEnumerator];
	DACALSlot*		workSlot = nil;
	DACALSlot*		outSlot = nil;
	
	while ( workSlot = [slotEnum nextObject] ) 
		if( outSlot = [workSlot slotWithIdentifier:slotID] )
			break;
	
	return outSlot;
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
			//theSubtreeChild = [SimpleTreeNode treeFromLocation:(NSURL*)slotTopURL];
			theSubtreeChild = [SimpleTreeNode treeOperationFromLocation:(NSURL*)slotTopURL forUI:NO];
			[theSlot setSlotNode:theSubtreeChild];
			
			[theSubtreeNode insertChild:theSubtreeChild atIndex:[theSubtreeNode numberOfChildren]];
			
			CFRelease( theSlotTitle );
			//CFRelease( slotTopURL );
			
			[[DACVolumeService sharedVolumeService] carouselDeviceSlotAttached:theSlot];
			
			if( fmodf( (float)slotindex, 5.0f ) == 0.0 )
				[[DACALTreeDataSource shared] updatePrompt];
			
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
		
		//if( !gDACALDevices ) gDACALDevices = [[NSMutableArray alloc] initWithCapacity:0];
		//[gDACALDevices addObject:self];
		[[DACALDeviceService sharedService] addDACALDevice:self];
		
		int					tempIndex, tempCount = DACALCommandGetSlotCount( newDeviceRef );
		NSMutableArray*		tempArray = [NSMutableArray arrayWithCapacity:tempCount];
		
		for( tempIndex=0; tempIndex < tempCount; tempIndex++ )
			[tempArray addObject:[DACALSlot slotForDevice:self inSlot:tempIndex+1]];
		
		deviceSlots = [[NSArray alloc] initWithArray:tempArray];
		
		//CFURLRef			tempURL = DACALCommandCopyPath( newDeviceRef, NULL );
		//CFURLGetFSRef( tempURL, &deviceFSRef );

		SimpleTreeNode*		theWorkNode = [[[[DACALTreeDataSource shared] treeControl] treeRoot] childWithItemType:kPADTypeGroupDevices];
		SimpleTreeNode*		theChildNode;
		SimpleTreeNode*		theSubtreeNode;
		
		NSString*			boxName = (NSString*)DACALCommandCopyName( newDeviceRef, NULL );
		CFURLRef			boxURL = DACALCommandCopyPath( newDeviceRef, NULL );
				
		CFURLGetFSRef( boxURL, &deviceFSRef );
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

-(void)indexedNewVolume:(DACVolume*)newVolume forSlot:(DACALSlotNum)newSlot ofType:(NSString*)newType forTarget:(id)finishedTarget
{
	DACALSlot*		workSlot = [self slotWithNumber:newSlot];
	NSString*		thePath = [newVolume volumePath];
	
	[workSlot slotAssignedIndexFromVolume:newVolume asType:newType];
	
	// Notch belt
	slotsUsed++;
	
	NSLog(@"assigned slot");
	
	[PADOperationControlDevice finishIndexingVolume:thePath forSlot:newSlot onDevice:self forTarget:finishedTarget];	
}

-(void)indexUnassignedForSlot:(DACALSlot*)oldSlot
{
	slotsUsed--;
}

-(NSString*)title
	{ return( (NSString*)DACALCommandCopyName( deviceRef, NULL ) ); }

-(NSURL*)fileURL
	{ return( (NSURL*)DACALCommandCopyPath( deviceRef, NULL ) ); }

-(void)detachingDevice
{
	[[AppController shared] cancelOperationsForDevice:self];
	[[DACVolumeService sharedVolumeService] carouselDeviceDetached:self];
	
	[deviceNode removeFromParent];
	[self setDeviceNode:nil];
	
	[[[[AppController shared] dataView] dataSource] updateChangesWithAction:YES];
	//[[[[DACALTreeDataSource shared] treeControl] outlineView] reloadItem:(id)boxParent reloadChildren:YES];
	//[[DACALTreeDataSource shared] doAction];
	
	NSLog( @"Detached Device: %@", [self title] );
	[self release];
}

-(void)attachedDevice:(DACALDevice*)newBox
{	
	//[[DACVolumeService sharedVolumeService] carouselDeviceAttached:self];
	
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

-(DACALResult)commandCloseDoor
	{ return DACALCommandCloseDoor( deviceRef ); }

@end		// DACALDevice

@implementation DACALDeviceService

-(NSMutableArray*)deviceList
	{ return deviceList; }

-(NSInteger)deviceCount
	{ return [deviceList count]; }

-(void)dealloc
{
	[deviceList release];
	[super dealloc];
}

-(void)initSelf
{
//	gDACALDevices = [[NSMutableArray alloc] initWithCapacity:0];
	deviceList = [[NSMutableArray alloc] initWithCapacity:0];
}

-(id)initializeService
{
	PADBOX_VALID_BEGIN

	DACALRegisterIconResource( CFSTR("DC300Black"), kDACALCarouselsFolderType );
	DACALRegisterIconResource( CFSTR("CDAudio"), 'cdda' );
	DACALRegisterIconResource( CFSTR("DVD-Video"), 'dvd ' );
	DACALRegisterIconResource( CFSTR("CD-silver"), 'Dcd ' );
	
	DACALRegisterIconResource( CFSTR("Generic_Files"), 'gFil' );
	DACALRegisterIconResource( CFSTR("Generic_Music"), 'gMus' );
	DACALRegisterIconResource( CFSTR("Generic_Movie"), 'gMov' );
	DACALRegisterIconResource( CFSTR("Generic_Image"), 'gImg' );
		
	DACALClientCreate( kCFAllocatorDefault, kPADClientIdentifier, (void*)self, DACALNotification );	

	PADBOX_VALID_END
	
	return self;
}

-(void)openService
{
	PADBOX_VALID_BEGIN
	
	DACALDevicesInitialize();

	PADBOX_VALID_END
}

-(void)addDACALDevice:(DACALDevice*)newDevice
	{ [deviceList addObject:newDevice]; }

-(DACALDevice*)DACALDeviceForDeviceRef:(DACALDeviceRef)aBoxRef
{
	DACALDevice*	foundBox = nil;
	int				boxIndex, boxCount = [deviceList count];
	
	if( aBoxRef < kDACALIllegalDevice )
		aBoxRef = DACALDevicesCopyDeviceRefForIndex( aBoxRef, NULL );
	else
		DACALDeviceRetain( aBoxRef );
	
	for( boxIndex=0; boxIndex < boxCount; boxIndex++ )
	{
		foundBox = [deviceList objectAtIndex:boxIndex];
		if( [foundBox isDeviceRef:aBoxRef] ) break;
		foundBox = nil;
	}
	
	DACALDeviceRelease( aBoxRef );
	
	return foundBox;
}

-(DACALSlot*)DACALDeviceSlotForDeviceRef:(DACALDeviceRef)aBoxRef andSlotNum:(DACALSlotNum)aSlotNum
{
	DACALDevice*	slotBox = [self DACALDeviceForDeviceRef:aBoxRef];
	DACALSlot*		foundSlot = nil;
	
	if( slotBox )
		foundSlot = [slotBox slotWithNumber:aSlotNum];
	
	return foundSlot;
}

-(DACALSlot*)DACALDeviceSlotForSlotIdentifier:(NSString*)findID
{
	DACALSlot*		foundSlot = nil;
	DACALDevice*	workBox = nil;
	NSEnumerator*	boxEnum = [deviceList objectEnumerator];
	
	while ( workBox = [boxEnum nextObject] )
		if( foundSlot = [workBox slotWithIdentifier:findID] )
			break;
	
	return foundSlot;
}

-(DACALSlotElement*)DACALDeviceSlotElementForURL:(NSURL*)itemURL
{
	DACALDeviceRef		searchDevice = CFURLCopyCarouselUUID( kCFAllocatorDefault, (CFURLRef)itemURL );
	DACALSlotNum		searchSlotNum = CFURLGetSlotNumber( (CFURLRef)itemURL, FALSE );
	DACALSlot*			searchSlot = [self DACALDeviceSlotForDeviceRef:searchDevice andSlotNum:searchSlotNum];
	DACALSlotElement*	foundElement = nil;
	
	if(searchSlot != nil )
	{
		foundElement = [searchSlot elementWithURL:itemURL];
		if( foundElement == nil ) {
			foundElement = [DACALSlotElement slotElementForSlot:searchSlot atLocation:itemURL];
		}
	}
	
	if( searchDevice ) CFRelease( (CFTypeRef)searchDevice );
	return foundElement;
}

-(BOOL)countUsedSlots:(NSInteger*)outUsedSlotCount
{
	BOOL				freeSlot = NO;
	NSInteger			outCount = 0;
	NSEnumerator*		deviceEnum = [deviceList objectEnumerator];
	DACALDevice*		workDevice = nil;
	
	while ( workDevice = [deviceEnum nextObject] ) 
		outCount += [workDevice slotsUsed];
	
	if( [[PADLicenseService sharedLicenseService] licenseValid] != YES )
		freeSlot = ([[PADLicenseService sharedLicenseService] licenseLimit] <= outCount);
	else
		freeSlot = ([deviceList count] > 0);
	
	if( outUsedSlotCount != NULL )
		*outUsedSlotCount = outCount;
	
	return freeSlot;
}

-(void)notificationDeviceAttached:(DACALDeviceRef)inBoxRef
{
	[[DACALDevice deviceWithDeviceRef:inBoxRef] attachingDevice];

	//NSLog(@"isDriverKextLoaded: %@", [DACDriverInstaller versionOfDriverKextLoaded]);
}

-(void)notificationDeviceDetached:(DACALDeviceRef)inBoxRef
{
	[[self DACALDeviceForDeviceRef:inBoxRef] detachingDevice];
}


@end	//	DACALDeviceService


void DACALNotification( void* inData, DACALDeviceRef inBox, CFStringRef inMessage, CFDictionaryRef inParam )
{
	DACALDeviceService*	deviceService = (DACALDeviceService*)inData;
	
	//NSLog( @"Client Notification: Device: %@ Message: %@", inBox, inMessage );
	
	if( CFStringHasPrefix( inMessage, kDACALCarouselNoticeDeviceOpen ) )
		[deviceService notificationDeviceAttached:inBox];
	else if( CFStringHasPrefix( inMessage, kDACALCarouselNoticeDeviceClose ) )
		[deviceService notificationDeviceDetached:inBox];
}

DACALDevice*	DACALDeviceForDeviceRef(DACALDeviceRef aBoxRef)
	{ return [[DACALDeviceService sharedService] DACALDeviceForDeviceRef:aBoxRef]; }
 
DACALSlot*		DACALDeviceSlotForSlotNumber(DACALDeviceRef aBoxRef, DACALSlotNum aSlotNum)
	{ return [[DACALDeviceService sharedService] DACALDeviceSlotForDeviceRef:aBoxRef andSlotNum:aSlotNum]; }

DACALSlot*		DACALDeviceSlotForSlotIdentifier( CFStringRef findID )
	{ return [[DACALDeviceService sharedService] DACALDeviceSlotForSlotIdentifier:(NSString*)findID]; }

DACALSlotElement*	DACALDeviceSlotElementForURL( CFURLRef itemURL )
	{ return [[DACALDeviceService sharedService] DACALDeviceSlotElementForURL:(NSURL*)itemURL]; }


