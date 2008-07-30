//
//  DACALTreeDataSource.m
//  DragNDropOutlineView
//
//  Created by Jack Small on 7/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DACALTreeDataSource.h"
#import "pmsDACALUtility.h"

// Index group names

#define		PADINDEX_GROUPTITLE_LIBRARY		@"LIBRARY"
#define		PADINDEX_GROUPTITLE_DEVICES		@"CAROUSELS"
#define		PADINDEX_GROUPTITLE_FAVORITES	@"DISCMARKS"
#define		PADINDEX_GROUPTITLE_SEARHCES	@"SEARCH FOR"

@implementation DACALTreeDataSource
static DACALTreeDataSource *DACALTreeDataSource_shared;

- (id)init
{
    if (DACALTreeDataSource_shared) 
	{
        [self autorelease];
        return DACALTreeDataSource_shared;
    }
	if (![super init]) return nil;
	
	DACALTreeDataSource_shared = self;
	return self;
}

- (SimpleTreeNode*)createInitialTree:(id)tree
{
	SimpleTreeNode*		theOutputTree = nil;
	SimpleTreeNode*		theWorkNode = nil;
	SimpleTreeNode*		theChildNode = nil;
	SimpleTreeNode*		theSubtreeNode = nil;
	SimpleTreeNode*		theSubtreeChild = nil;
	int					index, slotindex, slotcount;
	int					count = DACALDevicesGetCount();
	NSString*			boxName;
//	NSString*			boxDirName;
	CFStringRef			theSlotTitle;
//	CFStringRef			theSlotName;
	CFURLRef			dataURL = NULL; 
	CFURLRef			boxURL = NULL;
	CFURLRef			slotURL = NULL;
	NSArray*			slotFolders = nil;
	DACALDeviceRef		theBoxRef = (DACALDeviceRef)NULL;
	DACALDeviceNode		theBoxNode = 0;
	DACALSlotNum		slotNum = 0;
	OSType				slotIconType = kGenericCDROMIcon;
	OSType				compareIconType = 0;

	FSRef		userLibraryFolder;
	OSErr		theErr;
	
	[tree setAllowGroupRowLook:YES];
	[tree setAllowBetweenDrop:YES];

	theErr = FSFindFolder( kUserDomain, kDACALCarouselsFolderType, TRUE, &userLibraryFolder );
	if( theErr != 0 ) printf( "Could not find user library! Error:%i\n", theErr );
	else dataURL = CFURLCreateFromFSRef(NULL, &userLibraryFolder);

	
	// Load our initial outline view data from the "InitInfo" dictionary.
	NSDictionary *initData = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"InitInfo" ofType: @"dict"]];
	if( initData != nil ) theOutputTree = [SimpleTreeNode treeFromDictionary: initData];	
	
//	#warning Index 1 should not be hard coded!
//	theWorkNode = (SimpleTreeNode*)[theOutputTree childAtIndex:1];											
	theWorkNode = (SimpleTreeNode*)[theOutputTree childWithName:PADINDEX_GROUPTITLE_DEVICES];											
	[[theWorkNode nodeData] setItemType: kPADTypeGroupDevices];

	for( index=0; index < count; index++ )
	{
		theBoxNode = index+1;
		boxName = (NSString*)DACALCommandCopyName( theBoxNode, NULL );										// Create a leaf in the Carousels group for the device
		if( boxName == NULL ) boxName = [NSString stringWithFormat:@"Carousel %i", theBoxNode];				// This should not ever happen anymore.
		theChildNode = [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData leafDataWithName:boxName] parent:nil children:[NSArray array]] autorelease];

		//boxDirName = [NSString stringWithFormat:@"Carousel %i.carousel", theBoxNode];						// Create a url to the device folder
		//if( dataURL ) boxURL = CFURLCreateCopyAppendingPathComponent(NULL, dataURL, (CFStringRef) boxDirName, TRUE);
		boxURL = DACALCommandCopyPath( theBoxNode, NULL );
		if( boxURL ) [[theChildNode nodeData] setLocation: (NSURL*)boxURL];

		[[theChildNode nodeData] setIconRep:DACALGetIconImageForType( kDACALCarouselsFolderType )];			// Use the box icon		
		[[theChildNode nodeData] setItemType: kPADTypeIndexDevice];											// Set device type
		theBoxRef = (DACALDeviceRef)DACALCommandCopyUUID( theBoxNode, NULL );								// Save UUID
		[[theChildNode nodeData] setItemDevice:theBoxRef];

		//Create subtree root
		theSubtreeNode = [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData groupDataWithName:boxName] parent:nil children:[NSArray array]] autorelease];
		slotFolders = (NSArray*)DACALCommandCopyAllSlotPaths( theBoxRef, NULL );
		//		slotcount = DACALCommandGetSlotCount( theBoxRef );
		slotcount = [slotFolders count];
		for( slotindex = 1; slotindex <= slotcount; slotindex++ ) {	
			slotNum = CFURLGetSlotNumber( (CFURLRef)[slotFolders objectAtIndex:slotindex-1], FALSE );
			theSlotTitle = DACALSlotCopyTitle( theBoxRef, slotNum, NULL );
			if( theSlotTitle != NULL ) {																	// Create a url to the slot
				//theSlotName		= CFStringCreateWithFormat( NULL, NULL, CFSTR("Slot %i/%@"), slotNum, theSlotTitle );
				//slotURL = CFURLCreateCopyAppendingPathComponent( NULL, boxURL, (CFStringRef) theSlotName, TRUE );
				//slotURL = (CFURLRef)[slotFolders objectAtIndex:slotindex-1];
				slotURL = CFURLCreateCopyAppendingPathComponent( NULL, (CFURLRef)[slotFolders objectAtIndex:slotindex-1], (CFStringRef) theSlotTitle, TRUE );
				
				theSubtreeChild = [SimpleTreeNode treeOperationFromLocation:(NSURL*)slotURL];
				// [theSubtreeChild setDataDevice:theBoxRef slot:slotNum];
				compareIconType = [[theSubtreeChild nodeData] itemType];
				if		( compareIconType == kPADTypeDataMuisc ) slotIconType = 'cdda';				// CDAudioVolume
				else if	( compareIconType == kPADTypeDataMovie ) slotIconType = 'dvd ';				// public.dvd-media
				else											 slotIconType = kGenericCDROMIcon;  // public.cd-media
				[[theSubtreeChild nodeData] setIconRep:DACALGetIconImageForType(slotIconType)];
				
				[theSubtreeNode insertChild:theSubtreeChild atIndex:[theSubtreeNode numberOfChildren]];
				
				CFRelease( theSlotTitle );
				CFRelease( slotURL );
				//[theSLotName release];
			}
		}
		
		[[theChildNode nodeData] setSubTree:theSubtreeNode];

		[theWorkNode insertChild:theChildNode atIndex:index];
	}
	
//	#warning Index 2 should not be hard coded!	
//	[[[theOutputTree childAtIndex:2] nodeData] setItemType: kPADTypeGroupFavorites];
	[[[theOutputTree childWithName:PADINDEX_GROUPTITLE_FAVORITES] nodeData] setItemType: kPADTypeGroupFavorites];

/*
	theErr = FSFindFolder( kUserDomain, kDACALCarouselsFolderType, TRUE, &userLibraryFolder );
	if( theErr != 0 ) printf( "Could not find user library! Error:%i\n", theErr );
	else 
	{		
		CFURLRef	dataURL = CFURLCreateFromFSRef(NULL, &userLibraryFolder);
		int			index;
		CFShow( dataURL );
	
		theChildNode = [SimpleTreeNode treeFromLocation: (NSURL*)dataURL];	
		[theWorkNode insertChildren: [theChildNode children] atIndex: 0];
		
		for(index=0; index<[theWorkNode numberOfChildren]; index++)
			[[[theWorkNode childAtIndex:index] nodeData] setIsLeaf: YES];
	}
*/

	return theOutputTree;
}

- (void)outlineViewAction:(id)tree
{
	NSArray *selectedNodes = [tree selectedNodes];
	NSMutableArray *selectedBoxes = [NSMutableArray arrayWithCapacity:0];
	SimpleNodeData *data;
	SimpleTreeNode *subTree;
	int		index;
//	NSURL*	theURL;
	DACALDeviceRef theDevice;
	PADIndexToolbarController* toolControl = (PADIndexToolbarController*)[self toolbarControl];
	
	[secondaryController setTreeRoot:nil];
	
	for( index=0; index<[selectedNodes count]; index++ )
	{
		data = [[selectedNodes objectAtIndex:index] nodeData];
		subTree = [data subTree];
		if( subTree != nil) [secondaryController addTreeRoot:subTree];

		//if( [data location] != nil) 
		//{
			//if( index != 0 ) theURL = (NSURL*)CFURLCreateCopyDeletingLastPathComponent(NULL, (CFURLRef)[data location]);
			//else theURL = (NSURL*)[data location];
			//NSLog(@"The URL: %@\n", theURL );
			//theURL = (NSURL*)[data location];
			//[secondaryController addTreeRoot:  [SimpleTreeNode treeFromLocation: theURL]];
		//}
		
		theDevice = [data itemDevice];
		if( theDevice != (DACALDeviceRef)NULL )
			if(![selectedBoxes containsObject:(id)theDevice])
				[selectedBoxes addObject:(id)theDevice];
    }
	[secondaryController outlineViewAction:secondaryController];

	if( toolControl ) [toolControl setSelectedDevices:(NSArray*)selectedBoxes];
	
//	[selectedBoxes release];	
	return;
}

- (void)nodeNameChanged:(SimpleTreeNode*)theNode toName:(NSString*)theName
{
	SimpleNodeData*		theData = [theNode nodeData];
	DACALDeviceRef		theDevice = [theData itemDevice];
	NSInteger			theType = [theData itemType];

	[theData setName:theName];
	
	if( (theType == kPADTypeIndexDevice) & (theDevice != (DACALDeviceRef)NULL) )
		DACALCommandSetName( theDevice, (CFStringRef)theName );
	return;
}

- (NSInteger)shouldEditTableColumn:(NSTableColumn *)tc item:(id)item
{
	if( [[item nodeData] itemType] == kPADTypeIndexDevice ) return YES;

	return NO;
}


- (SimpleTreeNode*)findTreeNodeForDevice:(DACALDeviceRef)theBoxRef
	{ return [[[[self treeControl] treeRoot] childWithItemType:kPADTypeGroupDevices] childWithDevice:theBoxRef]; }


- (void)slotAddedToDevice:(DACALDeviceRef)theBoxRef forSlot:(DACALSlotNum)newSlot
{
	NSURL*				theSlotPath = (NSURL*)DACALSlotCopyPath( theBoxRef, newSlot, NULL );
	NSString*			theSlotTitle = (NSString*)DACALSlotCopyTitle( theBoxRef, newSlot, NULL );
	NSURL*				theSlotContentPath = (NSURL*)CFURLCreateCopyAppendingPathComponent( NULL, (CFURLRef)theSlotPath, (CFStringRef)theSlotTitle, TRUE );
	SimpleTreeNode*		theSubtreeNode = nil;
//	SimpleTreeNode*		theOthertTreeNode = [[secondaryController treeControl] treeRoot];
	SimpleTreeNode*		theSubtreeChild = nil;
	OSType				slotIconType = kGenericCDROMIcon;
	OSType				compareIconType = 0;
	
	// Find box
	
	theSubtreeNode = [[[self findTreeNodeForDevice:theBoxRef] nodeData] subTree];
	
	if( theSlotContentPath != nil )
	{
		theSubtreeChild = [SimpleTreeNode treeOperationFromLocation:(NSURL*)theSlotContentPath];

		[(SimpleNodeData*)[theSubtreeChild nodeData] setName: theSlotTitle];
		//[[theSubtreeChild nodeData] setLocation:theSlotContentPath];

		compareIconType = [[theSubtreeChild nodeData] itemType];
		if		( compareIconType == kPADTypeDataMuisc ) slotIconType = 'cdda';				// CDAudioVolume
		else if	( compareIconType == kPADTypeDataMovie ) slotIconType = 'dvd ';				// public.dvd-media
		else											 slotIconType = kGenericCDROMIcon;  // public.cd-media
		[[theSubtreeChild nodeData] setIconRep:DACALGetIconImageForType(slotIconType)];
		
		[theSubtreeNode insertChild:theSubtreeChild atIndex:[theSubtreeNode numberOfChildren]];
		//[theOthertTreeNode insertChild:theSubtreeChild atIndex:[theOthertTreeNode numberOfChildren]];

		//CFRelease( theSlotContentPath );
		//CFRelease( theSlotTitle );
		//CFRelease( theSlotPath );
	}
	
	[self outlineViewAction:[[self treeControl] outlineView]];
	[[secondaryController treeControl] reloadData];
}


+ (id)shared;
{
    if (!DACALTreeDataSource_shared) {
        [[DACALTreeDataSource alloc] init];
    }
    return DACALTreeDataSource_shared;
}


@end	// DACALTreeDataSource


@implementation DACALViewDataSource

- (void)awakeFromNib 
{
	[[AppController shared] setDataView: treeControl];
}

- (SimpleTreeNode*)createInitialTree:(id)tree
{
	SimpleTreeNode*		theOutputTree = nil;	
	return theOutputTree;
}

- (void)updatePrompt
{
	NSArray *selectedNodes = [treeControl selectedNodes];

	int			index = 0;
	int			count = [selectedNodes count];
	NSString*	promptData;
	
	index = [[treeControl outlineView] numberOfRows];
		
	if( count ) promptData = [NSString stringWithFormat:@"%i of %i selected", (int)count, (int)index];
	else		promptData = [NSString stringWithFormat:@"%i item%@", (int)index, ((index==1) ? @"" : @"s")];

	[promptText setStringValue: promptData];
}

- (void)outlineViewAction:(id)tree
{
	NSArray *selectedNodes = [treeControl selectedNodes];
	NSMutableArray *selectedSlots = [NSMutableArray arrayWithCapacity:0];
	SimpleNodeData *data;
	int		index = 0;
	int		count = [selectedNodes count];

	//	NSURL*	theURL;
	DACALSlotNum theSlot;
	PADIndexToolbarController* toolControl = (PADIndexToolbarController*)[self toolbarControl];
	NSNumber*	slotNumber;
	
	
	for( index=0; index<count; index++ )
	{
		data = [[selectedNodes objectAtIndex:index] nodeData];
		theSlot = [data itemSlot];
		if( theSlot != 0 ) {
			slotNumber = [NSNumber numberWithInteger:(NSInteger)theSlot];
			if( ![selectedSlots containsObject:slotNumber] )
				[selectedSlots addObject:slotNumber];
		}
    }
	if( toolControl ) [toolControl setSelectedSlots:(NSArray*)selectedSlots];

	[self updatePrompt];

	return;
}

- (NSInteger)shouldEditTableColumn:(NSTableColumn *)tc item:(id)item
{
	return NO;
}

@end	// DACALViewDataSource

