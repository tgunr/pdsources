//
// Created by davec on 8/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "AppController.h"
#import "DACALSlot.h"
#import "DACALDeviceObjC.h"
#import "SimpleTreeNode.h"
#import "DACVolume.h"
#import "DACALSlotElement.h"
#import "PADSearchRequest.h"
#import "dacalconstants.h"
#import "DACALTreeDataSource.h"

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
		NSLog(@"Mounted %@ As Volume: %@", [self title], [[mountVolume mediaTitle] autorelease]);

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
		NSLog(@"Unmounted %@", [self title]);

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
	NSError*	iconError = nil;

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
					[[NSFileManager defaultManager] copyItemAtPath:[iconFileURL path] toPath:[iconURL path] error:&iconError];
				if( iconError )
					NSLog(@"Copy Icon Error: %@", iconError);
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

-(NSNumber*)volumeSize
{
	CFStringRef		itemName = NULL;
	NSNumber*		outSize = nil;

	itemName = FSCopyXattr( kCFAllocatorDefault, &slotFSRef, kDACALCarouselDocumentXAttrVolumeSize, NULL );

	if( itemName == NULL )
		outSize = [NSNumber zero];
	else
		outSize = [NSNumber numberWithLongLong:[(NSString*)itemName longLongValue]];

	return( outSize );
}


@end		// DACALSlot
