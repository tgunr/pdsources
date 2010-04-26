//
//  DACALDeviceNode.m
//  DACALTester
//
//  Created by Dave Carlton on 01/11/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import "DACALDeviceNode.h"
#import "SimpleTreeNode.h"
#import "dacallib.h"
#import "DACALSlot.h"
#import "DACALTreeDataSource.h"
#import "DACALDeviceSerivce.h"
#import "DACALVolume.h"
#import "DACALVolumeService.h"
#import "PADSearchRequest.h"
#import "PADOperationOpenDevice.h"
#import "PADOperationControlDevice.h"

@implementation DACALDeviceNode

@synthesize deviceNode;
@synthesize deviceSlots;
@synthesize slotsUsed;

-(void)dealloc
{
	if (deviceNode) [deviceNode release];
	deviceNode = nil;

	if (deviceSlots) [deviceSlots release];
	deviceSlots = nil;

	[super dealloc];
}

-(id)initDeviceWithDeviceRef: (DACALDeviceRef) newDeviceRef
{
	if (self = [super init]) {
		[super initDeviceWithDeviceRef: newDeviceRef];

		//if( !gDACALDevices ) gDACALDevices = [[NSMutableArray alloc] initWithCapacity:0];
		//[gDACALDevices addObject:self];
		[[DACALDeviceService sharedService] addDACALDevice: self];

		int              tempIndex, tempCount = DACALCommandGetSlotCount(newDeviceRef);
		NSMutableArray * tempArray = [NSMutableArray arrayWithCapacity: tempCount];

		for (tempIndex = 0; tempIndex < tempCount; tempIndex++)
			[tempArray addObject: [DACALSlot createSlotForDevice: self inSlot: tempIndex + 1]];

		deviceSlots = [[NSArray alloc] initWithArray: tempArray];

		//CFURLRef			tempURL = DACALCommandCopyPath( newDeviceRef, NULL );
		//CFURLGetFSRef( tempURL, &deviceFSRef );

		SimpleTreeNode * theWorkNode = [[[[DACALTreeDataSource shared] treeControl] treeRoot] childWithItemType: kPADTypeGroupDevices];
		SimpleTreeNode * theChildNode;
		SimpleTreeNode * theSubtreeNode;

		CFURLGetFSRef(boxURL, &deviceFSRef);
		theChildNode = [[SimpleTreeNode alloc] initWithData: [SimpleNodeData leafDataWithName: boxName] parent: nil children: [[NSArray alloc] init]];

		deviceNode = theChildNode;

		[[theChildNode nodeData] setLocation: [(NSURL *)boxURL retain]];
		[[theChildNode nodeData] setIconRep: DACALGetIconImageForType(kDACALCarouselsFolderType)];          // Use the box icon
		[[theChildNode nodeData] setItemType: kPADTypeIndexDevice];                                         // Set device type

		[[theChildNode nodeData] setItemDevice: newDeviceRef];                                               // Save UUID

		// Create subtree root
		theSubtreeNode = [[SimpleTreeNode alloc] initWithData: [SimpleNodeData groupDataWithName: boxName] parent: nil children: [[NSArray alloc] init]];
		[[theSubtreeNode nodeData] setExpanded: YES];                                                        // Root level is always expanded
		[[theSubtreeNode nodeData] setIconRep: DACALGetIconImageForType(kDACALCarouselsFolderType)];        // Put the icon on it for the path control
		[[theChildNode nodeData] setSubTree: theSubtreeNode];

		// Hookup and refresh
		[theWorkNode insertChild: theChildNode atIndex: [theWorkNode numberOfChildren]];
		[[DACALTreeDataSource shared] orderForUser: [[[DACALTreeDataSource shared] treeControl] treeRoot]];
		[[[[DACALTreeDataSource shared] treeControl] outlineView] reloadItem: (id) theWorkNode reloadChildren: YES];
		[[DACALTreeDataSource shared] setPrompt: [NSString stringWithFormat: @"%@ attached", boxName]];
	}
	return self;
} // initDeviceWithDeviceRef

+(id)deviceWithDeviceRef: (DACALDeviceRef) newDeviceRef
{
	return [[DACALDeviceNode alloc] initDeviceWithDeviceRef: newDeviceRef];
}

-(void)indexUnassignedForSlot: (DACALSlot *) oldSlot
{
	slotsUsed--;
}

-(void)detachingDevice
{
	[deviceNode removeFromParent];
	[self setDeviceNode: nil];
}

-(void)attachingDevice
{
	[PADOperationOpenDevice addDeviceToSourceTree: self];
}

-(DACALSlot *)slotWithNumber: (DACALSlotNum) aSlot
{
	int slotIndex = aSlot - 1;

	if ( (slotIndex >= 0) && (slotIndex <= [deviceSlots count]) )
		return [deviceSlots objectAtIndex: slotIndex];

	return nil;
}

-(DACALSlot *)slotWithIdentifier: (NSString *) slotID
{
	NSEnumerator * slotEnum = [deviceSlots objectEnumerator];
	DACALSlot    * workSlot = nil;
	DACALSlot    * outSlot = nil;

	while (workSlot = [slotEnum nextObject])
		if (outSlot = [workSlot slotWithIdentifier: slotID])
			break;

	return outSlot;
}

-(void)swapSlotNumber: (DACALSlotNum) fromSlotNum toDevice: (DACALDeviceNode *) toBox toSlotNumber: (DACALSlotNum) toSlotNum
{
	if (toBox == nil) toBox = self;

	DACALSlot * fromSlot = [self slotWithNumber: fromSlotNum];
	DACALSlot * destSlot = [toBox slotWithNumber: toSlotNum];

	[fromSlot swapWithSlot: destSlot];
}

-(void)indexedNewVolume: (DACALVolume *) newVolume forSlot: (DACALSlotNum) newSlot ofType: (NSString *) newType forTarget: (id) finishedTarget
{
	DACALSlot * workSlot = [self slotWithNumber: newSlot];
	NSString  * thePath = [newVolume volumePath];

	[workSlot slotAssignedIndexFromVolume: newVolume asType: newType];

	// Notch belt
	slotsUsed++;

	NSLog(@"assigned slot");

	[PADOperationControlDevice finishIndexingVolume: thePath forSlot: newSlot onDevice: (DACALDeviceNode *)self forTarget: finishedTarget];
}

-(void)loadSlotIndex
{
	DACALSlot      * theSlot = nil;
	SimpleTreeNode * theChildNode = [self deviceNode];
	SimpleTreeNode * theSubtreeNode = [[theChildNode nodeData] subTree];
	SimpleTreeNode * theSubtreeChild;
	NSArray        * slotFolders = nil;
	DACALDeviceRef   theBoxRef = [self deviceRef];
	DACALSlotNum     slotNum;
	CFStringRef      theSlotTitle;
	CFURLRef         slotTopURL;
	NSURL          * slotURL;

	int slotindex, slotcount;

	[theChildNode setBusy: YES];

	slotFolders = (NSArray *)DACALCommandCopyAllSlotPaths(theBoxRef, NULL);
	slotcount = [slotFolders count];
	for (slotindex = 1; slotindex <= slotcount; slotindex++) {
		slotNum = CFURLGetSlotNumber( (CFURLRef)[slotFolders objectAtIndex : slotindex - 1], FALSE );
		theSlot = [[self slotWithNumber: slotNum] retain];

		theSlotTitle = DACALSlotCopyTitle(theBoxRef, slotNum, NULL);
		if (theSlotTitle != NULL) {                                                             // Create a url to the slot
			slotURL = [slotFolders objectAtIndex: slotindex - 1];
			[theSlot setSlotLocation: slotURL];                                                  // Save a FSRef while we know where it slot is

			slotTopURL = CFURLCreateCopyAppendingPathComponent(NULL, (CFURLRef)slotURL, (CFStringRef)theSlotTitle, TRUE);

			//theSubtreeChild = [SimpleTreeNode treeOperationFromLocation:(NSURL*)slotURL];
			//theSubtreeChild = [SimpleTreeNode treeFromLocation:(NSURL*)slotTopURL];
			theSubtreeChild = [SimpleTreeNode treeOperationFromLocation: (NSURL *)slotTopURL forUI: NO];
			[theSlot setSlotNode: theSubtreeChild];

			[theSubtreeNode insertChild: theSubtreeChild atIndex: [theSubtreeNode numberOfChildren]];

			CFRelease(theSlotTitle);
			//CFRelease( slotTopURL );

			[[VolumeService sharedVolumeService] carouselDeviceSlotAttached: theSlot];

			if (fmodf( (float)slotindex, 5.0f ) == 0.0)
				[[DACALTreeDataSource shared] updatePrompt];

			slotsUsed++;
		}
	}

	[theSlot retain];
	[theChildNode setBusy: NO];

	if (slotFolders) [slotFolders release];
} // loadSlotIndex

-(void)attachedDevice: (DACALDeviceNode *) newBox
{
	//[[VolumeService sharedVolumeService] carouselDeviceAttached:self];

	[PADSearchService performSelector: @selector(updateAllSearches)withObject: nil afterDelay: 0.42];
	[[DACALTreeDataSource shared] doAction];

	NSLog(@"Attached Device: %@", [self title]);
}

-(NSNumber *)totalVolumeSize
{
	NSEnumerator * slotEnum = [deviceSlots objectEnumerator];
	DACALSlot    * workSlot = nil;
	NSNumber     * workNumber = [NSNumber zero];

	while (workSlot = [slotEnum nextObject])
		workNumber = [workNumber addToNumber: [workSlot volumeSize]];

	return workNumber;
}

@end

void
DACALNotification(void * inData, DACALDeviceRef inBox, CFStringRef inMessage, CFDictionaryRef inParam)
{
	DACALDeviceService * deviceService = (DACALDeviceService *)inData;

	//NSLog( @"Client Notification: Device: %@ Message: %@", inBox, inMessage );

	if ( CFStringHasPrefix(inMessage, kDACALCarouselNoticeDeviceOpen) )
		[deviceService notificationDeviceAttached: inBox];
	else if ( CFStringHasPrefix(inMessage, kDACALCarouselNoticeDeviceClose) )
		[deviceService notificationDeviceDetached: inBox];
}

DACALDeviceNode *
DACALDeviceNodeForDeviceRef(DACALDeviceRef aBoxRef)
{
	return [[DACALDeviceService sharedService] DACALDeviceNodeForDeviceRef: aBoxRef];
}

DACALSlot *
DACALDeviceSlotForSlotNumber(DACALDeviceRef aBoxRef, DACALSlotNum aSlotNum)
{
	return [[DACALDeviceService sharedService] DACALDeviceSlotForDeviceRef: aBoxRef andSlotNum: aSlotNum];
}

DACALSlot *
DACALDeviceSlotForSlotIdentifier(CFStringRef findID)
{
	return [[DACALDeviceService sharedService] DACALDeviceSlotForSlotIdentifier: (NSString *)findID];
}

DACALSlotElement *
DACALDeviceSlotElementForURL(CFURLRef itemURL)
{
	return [[DACALDeviceService sharedService] DACALDeviceSlotElementForURL: (NSURL *)itemURL];
}