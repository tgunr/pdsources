//
// Created by davec on 8/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <DACAL/dacallib.h>
#import <PMUtility/pmUtility.h>
#import "DACALDevice.h"
#import "SimpleTreeNode.h"
#import "DACALSlot.h"
#import "DACALVolume.h"
#import "DACALViewDataSource.h"
#import "PADOperationControlDevice.h"
#import "DACALDeviceService.h"
#import "PADOperationOpenDevice.h"

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
	NSUInteger slotIndex = aSlot - 1;

	if( (slotIndex > 0) && (slotIndex <= [deviceSlots count]) )
		return [deviceSlots objectAtIndex:slotIndex];

	return nil;
}

-(DACALSlot*)slotWithIdentifier:(NSString*)slotID
{
	NSEnumerator*	slotEnum = [deviceSlots objectEnumerator];
	DACALSlot*		workSlot = nil;
	DACALSlot*		outSlot = nil;

	while ((workSlot = [slotEnum nextObject])) {
		outSlot = [workSlot slotWithIdentifier:slotID];
		if(outSlot)
			break;
	}
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

	NSUInteger			slotindex, slotcount;

	[theChildNode setBusy:YES];

	slotFolders = (NSArray*)DACALCommandCopyAllSlotPaths( theBoxRef, NULL );
	slotcount = [slotFolders count];
    // TODO: Compare slotCount with folder count, should be equal, if not, errors occurred
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

	[theChildNode setBusy:NO];

	if( slotFolders ) [slotFolders release];
}

-(id)initDeviceWithDeviceRef:(DACALDeviceRef)newDeviceRef
{
	self = [super init];
	if(self)
	{
		deviceRef = newDeviceRef;

		//if( !gDACALDevices ) gDACALDevices = [[NSMutableArray alloc] initWithCapacity:0];
		//[gDACALDevices addObject:self];
		[[DACALDeviceService sharedService] addDACALDevice:self];

		int					tempIndex;
		NSUInteger tempCount = DACALCommandGetSlotCount(newDeviceRef);
		NSMutableArray*		tempArray = [NSMutableArray arrayWithCapacity:tempCount];

		for( tempIndex=0; tempIndex < tempCount; tempIndex++ )
			[tempArray addObject:[DACALSlot slotForDevice:self inSlot: (DACALSlotNum)(tempIndex+1)]];

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

-(NSNumber*)totalVolumeSize
{
	NSEnumerator*	slotEnum = [deviceSlots objectEnumerator];
	DACALSlot*		workSlot = nil;
	NSNumber*		workNumber = [NSNumber zero];

	while ((workSlot = [slotEnum nextObject]))
		workNumber = [workNumber addToNumber:[workSlot volumeSize]];

	return workNumber;
}

-(DACALResult)commandCloseDoor
	{ return DACALCommandCloseDoor( deviceRef ); }

@end		// DACALDevice
