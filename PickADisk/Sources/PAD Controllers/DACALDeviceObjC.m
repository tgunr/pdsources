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

NSString*	kDACSlotReservationTime = @"DACResTime";
NSString*	kDACSlotReservationType = @"DACResType";
NSString*	kDACSlotReservationUser = @"DACResUser";
NSString*	kDACSlotReservationHost = @"DACResHost";

NSString*	kDACSlotReservationTypeCheckOut	= @"DACCheckOut";
NSString*	kDACSlotReservationTypeCheckIn	= @"DACCheckIn";

//	Internal constants

NSString*	kDACSlotReservationFileName					= @".reservations";
NSString*	kDACSlotReservationFileNameWithExtension	= @".reservations.plist";

NSMutableArray*		gDACALDevices;

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

-(void)reloadElement
{
	NSURL*		newURL = (NSURL*)CFURLCreateFromFSRef( kCFAllocatorDefault, [self elementFSRef] );
	
	if( newURL )
	{
		NSLog(@"Reloading Element: %@", newURL);
		[[elementNode nodeData] setLocation:newURL];
		[elementNode reloadData:nil reloadChildren:NO];
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

-(FSRef*)slotFSRef
	{ return &slotFSRef; }

-(BOOL)setSlotFSRefFromURL:(NSURL*)slotURL
	{ return( (CFURLGetFSRef( (CFURLRef)slotURL, &slotFSRef ) == TRUE) ? YES : NO ); }

-(BOOL)setSlotLocation:(NSURL*)slotURL
{
	BOOL	goodSet = [self setSlotFSRefFromURL:slotURL];
	
	if( goodSet == YES )
	{		//	Is Checked out?
		
		CFStringRef		checkedOut = NULL;
		
		if( slotCheckedOut != nil ) [slotCheckedOut release];
		if( FSIsFSRefValid( &slotFSRef ) )
			checkedOut = FSCopyXattr( kCFAllocatorDefault, &slotFSRef, kDACALCarouselDocumentXAttrSlotCheckout, NULL );
		if( checkedOut != NULL ) 
			slotCheckedOut = [[NSDate alloc] initWithString:(NSString*)checkedOut];
		else
			slotCheckedOut = nil;
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
	NSDate*				swapDate = nil;
	NSMutableArray*		swapElements = nil;
	
	theErr = DACALSlotMove( [[self slotDevice] deviceRef], [self slotNumber], [[otherSlot slotDevice] deviceRef], [otherSlot slotNumber] );
	
	if( theErr == 0 )
	{
		swapNode = [[self slotNode] retain];
		swapElements = [[self slotElements] retain];
		
		if( [self isCheckedOut] == YES )
			swapDate = [[self checkedOutDate] retain];
		
		[self setSlotNode:[otherSlot slotNode]];
		[self setSlotElements:[otherSlot slotElements]];
		[self setCheckedOutDate:[otherSlot checkedOutDate]];
		
		[otherSlot setSlotNode:swapNode];
		[otherSlot setSlotElements:swapElements];
		[otherSlot setCheckedOutDate:swapDate];
		
		//[swapNode release];
		//[swapElements release];
		
		[self reloadSlot];
		[otherSlot reloadSlot];
	}
	
	if( theErr != 0 ) {
		NSLog(@"Error:%i Changing Slot", (int)theErr);
		[AppController playUISound: kASSystemSoundDoink];
	} else {
		[AppController playUISound: kASSystemSoundSuccess];
	}
	
}

-(void)reloadSlot
{
	NSURL*		newURL = [self fileURL];
	
	if( newURL )
	{
		NSLog(@"Reloading Slot: %@", newURL);
		[[slotNode nodeData] setLocation:newURL];
		[slotNode reloadData:nil reloadChildren:NO];
		
		if( (slotElements != nil) && ([slotElements count] > 0) )
		{
			[slotElements makeObjectsPerformSelector:@selector(reloadElement)];
			[[PADSearchService sharedSearch] searchDataChanged:slotElements];
			
			[[[[AppController shared] dataView] dataSource] sortExpandedChildrenWithCurrentDescriptors:nil];
			[[[[AppController shared] dataView] outlineView] reloadData];
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
	
	[[[[AppController shared] dataView] dataSource] sortExpandedChildrenWithCurrentDescriptors:nil];
	[[[[AppController shared] dataView] outlineView] reloadData];	
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

-(NSDictionary*)currentReservation
{
	NSDictionary*			manifestDict = [self reservationHistory];
	NSDictionary*			thisReservation = nil;
	NSDate*					checkOutDate = [self checkedOutDate];
	
	if( checkOutDate == nil ) return thisReservation;
	
	if( manifestDict != nil )
		thisReservation = [manifestDict objectForKey:[checkOutDate description]];
	
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
	
	if( BOOLToBoolean([self isCheckedOut]) ) return didWork;
	
	if( manifestURL != nil )
	{
		if( manifestDict != nil )
			[newManDict addEntriesFromDictionary:manifestDict];
		
		[newManEntry setValue:newDate		forKey:kDACSlotReservationTime];
		[newManEntry setValue:userName		forKey:kDACSlotReservationUser];
		[newManEntry setValue:userHost		forKey:kDACSlotReservationHost];
		[newManEntry setValue:kDACSlotReservationTypeCheckOut
					   forKey:kDACSlotReservationType];
		
		[newManDict setValue:newManEntry	forKey:[newDate description]];
		didWork = [newManDict writeToURL:manifestURL atomically:YES];
		
		if( didWork ) {
			FSSetXattr( &slotFSRef, kDACALCarouselDocumentXAttrSlotCheckout, (CFStringRef)[newDate description] );
			[self setCheckedOutDate:newDate];
		}
	}
	
	[self reloadSlot];
	
	NSLog(@"Slot Checkout:%@\nManifset URL:%@\nManifest Dictionary:%@", self, manifestURL, manifestDict);
	
	return didWork;
}



-(BOOL)checkInForUser:(NSString*)userName onHost:(NSString*)userHost
{
	BOOL					didWork = NO;
	NSDate*					checkOutDate = [self checkedOutDate];
	NSURL*					manifestURL = [NSURL URLWithString:kDACSlotReservationFileNameWithExtension relativeToURL:[self fileURL]];
	NSDictionary*			manifestDict = [NSDictionary dictionaryWithContentsOfURL:manifestURL];
	NSDictionary*			checkInEntry = [manifestDict objectForKey:[checkOutDate description]];
	NSMutableDictionary*	newManDict = [NSMutableDictionary dictionaryWithCapacity:0];
	NSMutableDictionary*	newManEntry = [NSMutableDictionary dictionaryWithCapacity:0];
	NSDate*					newDate = [NSDate date];
	
	if( manifestURL == nil ) return didWork;
	
	if( checkInEntry != nil )
	{
		if( manifestDict != nil )
			[newManDict addEntriesFromDictionary:manifestDict];
		
		[newManEntry setValue:newDate		forKey:kDACSlotReservationTime];
		[newManEntry setValue:userName		forKey:kDACSlotReservationUser];
		[newManEntry setValue:userHost		forKey:kDACSlotReservationHost];
		[newManEntry setValue:kDACSlotReservationTypeCheckIn
					   forKey:kDACSlotReservationType];
		
		[newManDict setValue:newManEntry	forKey:[newDate description]];
		didWork = [newManDict writeToURL:manifestURL atomically:YES];
		
		if( didWork ) {
			FSSetXattr( &slotFSRef, kDACALCarouselDocumentXAttrSlotCheckout, (CFStringRef)NULL );
			[self setCheckedOutDate:nil];
		}
	}
	
	[self reloadSlot];
	
	NSLog(@"Slot Check In:%@\nManifset URL:%@\nManifest Dictionary:%@", self, manifestURL, manifestDict);
	
	return didWork;
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
		[[theChildNode nodeData] setSubTree:theSubtreeNode];
		
		// Hookup and refresh
		[theWorkNode insertChild:theChildNode atIndex:[theWorkNode numberOfChildren]];
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

-(void)indexedNewVolume:(NSURL*)newVolume forSlot:(DACALSlotNum)newSlot ofType:(NSString*)newType
{
	CFURLRef	slotURL = DACALSlotCopyPath( deviceRef, newSlot, NULL );
	if( slotURL ) CFURLSetXattr( slotURL, kDACALCarouselDocumentXAttrSlotAddDate, (CFStringRef)[[NSDate date] description] );
	if( slotURL ) CFURLSetXattr( slotURL, kDACALCarouselDocumentXAttrSlotKind, (CFStringRef)newType );
	if( slotURL ) CFRelease( slotURL );
	
	
	[[DACALTreeDataSource shared] slotAddedToDevice: deviceRef forSlot: newSlot];
		
	[PADOperationControlDevice finishIndexingVolume:[newVolume path] forSlot:newSlot onDevice:self forTarget:self];	
}

-(NSString*)title
	{ return( (NSString*)DACALCommandCopyName( deviceRef, NULL ) ); }

-(NSURL*)fileURL
	{ return( (NSURL*)DACALCommandCopyPath( deviceRef, NULL ) ); }

-(void)detachingDevice
{
	SimpleTreeNode*		boxNode = deviceNode;
	SimpleTreeNode*		boxParent = (SimpleTreeNode*)[boxNode nodeParent];

	[[AppController shared] cancelOperationsForDevice:self];
	
	[boxNode removeFromParent];
	[self setDeviceNode:nil];
	
	[[[[DACALTreeDataSource shared] treeControl] outlineView] reloadItem:(id)boxParent reloadChildren:YES];
	[[DACALTreeDataSource shared] doAction];
	
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

