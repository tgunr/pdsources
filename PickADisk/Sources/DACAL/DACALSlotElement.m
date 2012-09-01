//
// Created by davec on 8/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Cocoa/Cocoa.h>
#import <PMUtility/pmUtility.h>
#import "AppController.h"
#import "DACALSlotElement.h"
#import "DACALSlotElementBookmark.h"
#import "DACALTreeDataSource.h"
#import "DACALSlot.h"
#import "TreeController.h"

@implementation DACALSlotElement

- (void)dealloc {
	if (elementSlot)
		[elementSlot removeSlotElement: self];

	if (elementSlot)
		[elementSlot release];
	if (elementNode)
		[elementNode release];
	if (elementURL)
		[elementURL release];

	elementSlot = nil;
	elementNode = nil;
	elementURL  = nil;

	[elementBookmarks release];
	[comments release];
	[tags release];
	[comments release];
	[tags release];
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

-(DACALDevice*)elementDevice
{
	return [[self elementSlot] slotDevice];
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
	NSUInteger markCount = [elementBookmarks count];
	NSUInteger markIndex;
	NSMutableArray*	markNames = [NSMutableArray arrayWithCapacity: markCount];

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
		CFRelease((CFTypeRef)newStars);
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
	self = [super init];
	if(self)
	{
		elementSlot = newSlot;
        Boolean gotSlot = CFURLGetFSRef( (CFURLRef)newLoc, &elementFSRef );

		if( !gotSlot ) {
			NSLog(@"ELement NullRef: %@", self);
			//[self autorelease];
			//return nil;
		}
		elementURL = [newLoc retain];
		elementBookmarks = [[NSMutableArray alloc] initWithCapacity:0];

		[self reloadAttributes];

		if( newSlot )
            [newSlot addSlotElement:self];
	}
	return self;
}

+(id)slotElementForNode:(SimpleTreeNode*)newNode
{
	if( [[newNode nodeData] itemElement] != nil )
		return [[newNode nodeData] itemElement];

	DACALSlotElement*	ourElement = DACALDeviceSlotElementForURL( (CFURLRef)[(SimpleNodeData*)[newNode nodeData] itemURL] );

	if( ourElement != nil ) {
		[ourElement setElementNode:newNode];
		[[newNode nodeData] setItemElement:ourElement];
	}

	return ourElement;
}

+(id)slotElementForSlot:(DACALSlot*)newSlot atLocation:(NSURL*)newLoc
	{ return [[DACALSlotElement alloc] initElementForSlot:newSlot atLocation:newLoc]; }

-(void)updateElementChanges:(BOOL)doAction
	{ [[[[AppController shared] dataView] treeDataSource] updateChangesForItem:elementNode withAction:doAction]; }

-(void)reloadElement
{
	NSURL*		newURL = (NSURL*)CFURLCreateFromFSRef( kCFAllocatorDefault, [self elementFSRef] );

	if( newURL )
	{
		// NSLog(@"Reloading Element: %@", newURL);

		[[elementNode nodeData] setLocation:newURL];
		[elementNode reloadData:nil reloadChildren:NO];
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

-(BOOL)changeElementIconRep:(NSImage*)newIcon
{
//	BOOL didChange =  CFURLSetIconFromNSImage( kCFAllocatorDefault, (CFURLRef)[self elementURL], newIcon );
	BOOL didChange =  TRUE;

	if( didChange )
		[self reloadElement];

	return didChange;
}

@end		// DACALSlotElement
