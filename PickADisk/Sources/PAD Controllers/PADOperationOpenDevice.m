//
//  PADOperationOpenDevice.m
//  PickADisk
//
//  Created by Jack Small on 8/16/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "PADOperationOpenDevice.h"


@implementation PADOperationOpenDevice

-(SimpleTreeNode*)theDeviceNode
{ return theDeviceNode; }
-(void)setTheDeviceNode:(SimpleTreeNode*)newNode
{ theDeviceNode = newNode; }

-(void)dealloc
{
	[self setTheDeviceNode:nil];
	[self setTheBoxRef:kDACALNullDevice];
	
	[super dealloc];
}

-(id)endTaskForOperation:(PADCarouselOperation*)ownerOp
{ return (id)theBoxRef; }


+(BOOL)addDeviceToSourceTree:(DACALDeviceRef)newBox forTarget:(id)theTarget endSelector:(SEL)theSelector
{
	PADOperationOpenDevice*	newSelf = [[PADOperationOpenDevice alloc] init];
	
	SimpleTreeNode*		theWorkNode = [[[[DACALTreeDataSource shared] treeControl] treeRoot] childWithItemType:kPADTypeGroupDevices];
	SimpleTreeNode*		theChildNode;
	SimpleTreeNode*		theSubtreeNode;
	
	NSString*			boxName = (NSString*)DACALCommandCopyName( newBox, NULL );
	CFURLRef			boxURL = DACALCommandCopyPath( newBox, NULL );
	
	[newSelf setTheBoxRef:newBox];
	
	theChildNode = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData leafDataWithName:boxName] parent:nil children:[NSArray array]];
	if( boxURL ) [[theChildNode nodeData] setLocation: (NSURL*)boxURL];
	[[theChildNode nodeData] setIconRep:DACALGetIconImageForType( kDACALCarouselsFolderType )];			// Use the box icon		
	[[theChildNode nodeData] setItemType: kPADTypeIndexDevice];											// Set device type

	[[theChildNode nodeData] setItemDevice:newBox];														// Save UUID
														
	
	// Create subtree root
	theSubtreeNode = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData groupDataWithName:boxName] parent:nil children:[NSArray array]];
	[[theSubtreeNode nodeData] setExpanded:YES];														// Root level is always expanded
	[[theChildNode nodeData] setSubTree:theSubtreeNode];
	
	[newSelf setTheDeviceNode:theChildNode];
	
	// Hookup and refresh
	[theWorkNode insertChild:theChildNode atIndex:[theWorkNode numberOfChildren]];
	[[[[DACALTreeDataSource shared] treeControl] outlineView] reloadItem:(id)theWorkNode reloadChildren:YES];
	[[DACALTreeDataSource shared] setPrompt:[NSString stringWithFormat:@"%@ attached", boxName]];

	[newSelf startNewOperationForTarget:theTarget endSelector:theSelector];
	
	if( boxName )	[boxName release];
	if( boxURL )	CFRelease( boxURL );
	
	return YES; 
	
}

-(BOOL)runTaskForOperation:(PADCarouselOperation*)ownerOp
{
	SimpleTreeNode*		theChildNode = [self theDeviceNode];
	SimpleTreeNode*		theSubtreeNode = [[theChildNode nodeData] subTree];
	SimpleTreeNode*		theSubtreeChild;
	NSArray*			slotFolders = nil;
	DACALSlotNum		slotNum;
	CFStringRef			theSlotTitle;
	CFURLRef			slotURL;

	int					slotindex, slotcount;
	OSType				slotIconType = kGenericCDROMIcon;
	OSType				compareIconType = 0;

	[theChildNode setBusy:YES];

	slotFolders = (NSArray*)DACALCommandCopyAllSlotPaths( theBoxRef, NULL );
	slotcount = [slotFolders count];
	for( slotindex = 1; slotindex <= slotcount; slotindex++ ) {	
		slotNum = CFURLGetSlotNumber( (CFURLRef)[slotFolders objectAtIndex:slotindex-1], FALSE );
		theSlotTitle = DACALSlotCopyTitle( theBoxRef, slotNum, NULL );
		if( theSlotTitle != NULL ) {															// Create a url to the slot
			slotURL = CFURLCreateCopyAppendingPathComponent( NULL, (CFURLRef)[slotFolders objectAtIndex:slotindex-1], (CFStringRef) theSlotTitle, TRUE );			
			theSubtreeChild = [SimpleTreeNode treeOperationFromLocation:(NSURL*)slotURL];

			compareIconType = [[theSubtreeChild nodeData] itemType];
			if		( compareIconType == kPADTypeDataMuisc ) slotIconType = 'cdda';				// CDAudioVolume
			else if	( compareIconType == kPADTypeDataMovie ) slotIconType = 'dvd ';				// public.dvd-media
			else											 slotIconType = kGenericCDROMIcon;  // public.cd-media
			//[[theSubtreeChild nodeData] setIconRep:DACALGetIconImageForType(slotIconType)];
			
			[theSubtreeNode insertChild:theSubtreeChild atIndex:[theSubtreeNode numberOfChildren]];
			
			CFRelease( theSlotTitle );
			CFRelease( slotURL );
		}
	}	

//	[theSubtreeNode recursiveSortChildren];						// Sort by slot!
	
	[theChildNode setBusy:NO];
	
	if( slotFolders ) [slotFolders release];
	
	return YES; 
}

@end
