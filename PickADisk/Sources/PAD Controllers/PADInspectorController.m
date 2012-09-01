//
//  PADInspectorController.m
//  PickADisk
//
//  Copyright 2009 PolyMicro Systems. All rights reserved.
//

#import <PMUtility/pmUtility.h>
#import "PADInspectorController.h"
#import "DACALViewDataSource.h"
#import "DACALSlotElement.h"
#import "DACALDevice.h"
#import "DACALSlot.h"

@implementation PADInspectorController

static	PADInspectorController*		PADInspectorController_shared = nil;

+ (id)sharedInspector
{
    if (!PADInspectorController_shared) {
        [[PADInspectorController alloc] init];
    }
    return PADInspectorController_shared;
}

- (id)init
{
    if (PADInspectorController_shared) 
	{
        [self autorelease];
        return PADInspectorController_shared;
    }
	self = [super initWithWindowNibName:@"PADInspector"];
	if(self)
	{
		PADInspectorController_shared = self;
		
		selectedRecords = [[NSMutableArray alloc] init];
		[selectedRecords addObject:[NSNull null]];			//	This is a fake entry so that whatever shows up as a selection change will be different
	}
	return self;
}

- (void)dealloc
{
	[selectedRecords release];
	selectedRecords = nil;
	
//	[[[AppController shared] toolbarController] setInspectorController:nil];
	[[PADSearchService sharedSearch] removeActiveWatcher:self];

	[super dealloc];
}

- (void)awakeFromNib
{
//	[[[AppController shared] toolbarController] setInspectorController:self];
	[[PADSearchService sharedSearch] addActiveWatcher:self];
	[self adoptInspectorSelection:nil];
}


- (NSUndoManager*)windowWillReturnUndoManager:(NSWindow*)window
{
	return [[[AppController shared] dataView] undoManager];
}

- (NSUndoManager*)undoManager
	{	return [[[AppController shared] dataView] undoManager];	}
	
// Menu Selection Delegate

//	This is called by the slotTypeList NSPopUpButton
//	as the user selects a menu item
-(void)menu:(NSMenu *)menu willHighlightItem:(NSMenuItem *)item
{ if( item ) [generalTypeIcon changeToLibraryFlavor:[item title]]; }

// Search Watcher Protocol
- (void)searchStarted:(PADSearchRequest*)newSearch
	{	return;	}
- (void)searchFinished:(PADSearchRequest*)newSearch
	{	return; }
- (void)searchDataChanged:(NSArray*)theItems
{
	NSEnumerator*		dataEnum = [selectedRecords objectEnumerator];
	SimpleTreeNode*		dataItem = nil;

	if( theItems == nil ) return;
	if( [theItems count] == 0 ) return;
	
	while( dataItem = [dataEnum nextObject] )
	{
		if( [theItems indexOfObject:[dataItem matchActual]] != NSNotFound )
			[self installSelectionData];
	}
	
}

- (void)activeDocumentChanged
{
/*
    id mainDocument = [[[NSApp mainWindow] windowController] document];
    if (mainDocument != inspectedDocument)
	{
		if (inspectedDocument)
		{
			[documentObjectController commitEditing];
		}
		self.inspectedDocument = (mainDocument && [mainDocument isKindOfClass:[MyDocument class]]) ? mainDocument : nil;   
    }
*/
}


/*
 We don't want to do any observing until the properties panel is brought up.
 */
- (void)windowDidLoad
{
    // Once the UI is loaded, we start observing the panel itself to commit editing when it becomes inactive (loses key state)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inspectorPanelDidResignKey:) name:NSWindowDidResignKeyNotification object:[self window]];
	
    // Make sure we start inspecting the document that is currently active, and start observing changes
    [self activeDocumentChanged];
 //   [NSApp addObserver:self forKeyPath:@"mainWindow.windowController.document" options:0 context:[InspectorPanelController class]];
	
//	[[[AppController shared] toolbarController] setInspectorController:self];
//	[[PADSearchService sharedSearch] addActiveWatcher:self];
	
//	DACALViewDataSource*	dataController = (DACALViewDataSource*)[[[DACALTreeDataSource shared] secondaryController] treeDataSource];
//	[[self window] setUndoManager:[dataController undoManager]];

    [super windowDidLoad];  // It's documented to do nothing, but still a good idea to invoke...
}

/*
 Whenever the properties panel loses key status, we want to commit editing.
 */
- (void)inspectorPanelDidResignKey:(NSNotification *)notification
{
//    [documentObjectController commitEditing];
	[self adoptInspectorSelection:[[[AppController shared] toolbarController] selectedNodes]];
}

- (IBAction)clickGeneralType:(id)sender
{
	DACALViewDataSource*	dataController = (DACALViewDataSource*)[[[DACALTreeDataSource shared] secondaryController] dataSource];
	SimpleTreeNode*			nodeActual = [[selectedRecords objectAtIndex:0] matchActual];
	NSString*				newType = DACALFlavorToFlavorValue([sender titleOfSelectedItem]);
	
	if( [newType isEqual:[(SimpleNodeData*)[nodeActual nodeData] itemFlavor]] == YES ) return;
	
	[dataController nodeTypeChanged:nodeActual toType:newType];
}

- (IBAction)clickGeneralWhere:(id)sender
{
	
	
}

- (IBAction)clickGeneralRating:(id)sender
{
	DACALViewDataSource*	dataController = (DACALViewDataSource*)[[[DACALTreeDataSource shared] secondaryController] dataSource];
	SimpleTreeNode*			nodeActual = [[selectedRecords objectAtIndex:0] matchActual];
	
	if( [sender intValue] == [(SimpleNodeData*)[nodeActual nodeData] keyStars] ) return;
	
	[dataController nodeStarsChanged:nodeActual toStars:sender];
}

- (IBAction)exitImage:(id)sender
{
//	DACALViewDataSource*	dataController = (DACALViewDataSource*)[[[DACALTreeDataSource shared] secondaryController] treeDataSource];
	SimpleTreeNode*			nodeActual = [[selectedRecords objectAtIndex:0] matchActual];
	
	if( [sender objectValue] == [(SimpleNodeData*)[nodeActual nodeData] iconRep] ) return;
	
	[self nodeImageChanged:nodeActual toImage:[sender objectValue]];	
}

- (IBAction)exitComment:(id)sender
{
	NSString*			theValue = [sender stringValue];
	
	DACALViewDataSource*	dataController = (DACALViewDataSource*)[[[DACALTreeDataSource shared] secondaryController] dataSource];
	SimpleTreeNode*			nodeActual = [[selectedRecords objectAtIndex:0] matchActual];
	
	if( [theValue isEqual:[[[nodeActual nodeData] itemElement] comments]] == YES ) return;
	[dataController nodeCommentChanged:nodeActual toComment:theValue];
}

- (IBAction)exitTags:(id)sender
{
	NSArray*			theValue = [sender objectValue];
	
	DACALViewDataSource*	dataController = (DACALViewDataSource*)[[[DACALTreeDataSource shared] secondaryController] dataSource];
	SimpleTreeNode*			nodeActual = [[selectedRecords objectAtIndex:0] matchActual];

	if( [theValue isEqual:[[[nodeActual nodeData] itemElement] tags]] == YES ) return;
	[dataController nodeTagsChanged:nodeActual toTags:theValue];
}

- (IBAction)exitTitle:(id)sender
{
	NSString*			theValue = [sender stringValue];
	
	DACALViewDataSource*	dataController = (DACALViewDataSource*)[[[DACALTreeDataSource shared] secondaryController] dataSource];
	SimpleTreeNode*			nodeActual = [[selectedRecords objectAtIndex:0] matchActual];
	
	if( [theValue isEqual:[[[nodeActual nodeData] itemElement] title]] == YES ) return;
	[dataController nodeNameChanged:nodeActual toName:theValue];
}

- (IBAction)clickTopButton:(id)sender
{
	NSLog(@"Button Pushed");
}


- (void)dispatchInspectorPanelTo:(NSString*)doWhat withSelection:(NSArray*)theNodes
{
    NSWindow *window = [self window];

	if( [doWhat isEqual:@"Hide Inspector"] ) {
		[window orderOut:self];
		[self adoptInspectorSelection:nil];
	} else {
		[self adoptInspectorSelection:theNodes];
		[window makeKeyAndOrderFront:self];
	}	
}

/*
 Since we want the panel to toggle...
 Note that if the window is visible and key, we order it out; otherwise we make it key.
 */
- (void)toggleInspectorPanel:(id)sender
{
    NSWindow *window = [self window];

	if ([window isVisible])
	{
		[window orderOut:sender];
		[self adoptInspectorSelection:nil];
    }
	else
	{
		[self adoptInspectorSelection:[[[AppController shared] toolbarController] selectedNodes]];
		[window makeKeyAndOrderFront:sender];
    }
}

/*
 validateMenuItem: is used to dynamically set attributes of menu items.
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	
    if ( ([menuItem action] == @selector(toggleInspectorPanel:)) || ([menuItem action] == @selector(ctmInspector:)) )
	{  
		// Correctly toggle the menu item for showing/hiding document properties
		// We call [self isWindowLoaded] first since it prevents [self window] from loading the nib
				
		NSString *menuTitle = nil;
		
//		if (![self isWindowLoaded] || ![[self window] isVisible] || ![[self window] isKeyWindow])
		if (![self isWindowLoaded] || ![[self window] isVisible] )
		{
			// the panel is not loaded, not visible, or not key
			menuTitle = NSLocalizedString(@"Show Inspector",
										  @"Title for menu item to show the document properties panel (should be the same as the initial menu item in the nib).");
 		}
		else
		{
			menuTitle = NSLocalizedString(@"Hide Inspector",
										  @"Title for menu item to hide the Inspector panel.");
		}
		[menuItem setTitleWithMnemonic:menuTitle];
		//NSLog(@"Menu Toggled To: %@", menuTitle);
    }
    return YES;
}

- (BOOL)validateContextualMenuItem:(NSMenuItem *)menuItem withSelection:(NSArray*)newNodes
{
	NSString *menuTitle = nil;

	if ( ![self isWindowLoaded] || ![[self window] isVisible] || ![selectedRecords isEqual:newNodes] ) 
	{
		// the panel is not loaded, not visible, or the selection is different
		menuTitle = NSLocalizedString(@"Show Inspector",
									  @"Title for menu item to show the document properties panel (should be the same as the initial menu item in the nib).");
	}
	else
	{
		menuTitle = NSLocalizedString(@"Hide Inspector",
									  @"Title for menu item to hide the Inspector panel.");
	}
	[menuItem setTitleWithMnemonic:menuTitle];
	//NSLog(@"Menu Toggled To: %@", menuTitle);

	return YES;
}

- (void)nodeImageChanged:(SimpleTreeNode*)theNode toImage:(NSImage*)theImage
{
	NSUndoManager*	undo = [self undoManager];
	SimpleNodeData*	data = [theNode nodeData];
	NSImage*		nowActual = [data iconRep];
	NSImage*		nowImage = (nowActual != nil) ? [nowActual copy] : nil;
	
	NSLog(@"Node Image Chagnged?!");
	return;
	
	[[undo prepareWithInvocationTarget:self] nodeImageChanged:theNode toImage:nowImage];
	[undo setActionName:NSLocalizedString(@"Change Image", @"Undo Action when node image is changed")];
	
	[[data itemElement] changeElementIconRep:theImage];
	[data setIconRep:theImage];
	
	[[PADSearchService sharedSearch] searchDataChanged:[NSArray arrayWithObject:theNode]];
}


- (void)extractSelectionDataAndClear:(BOOL)doClear
{
	//	Extract?
	
	if( doClear == YES )
		[selectedRecords removeAllObjects];
}

- (void)installSelectionData
{
	SimpleTreeNode*		item = nil;
	SimpleNodeData*		data = nil;
	id					element = nil;
	NSString*			workString = nil;
	NSString*			statusString = nil;
	NSString*			buttonTitle = nil;
	NSString*			windowTitle = nil;
	NSNumber*			workSize = nil;
	NSImage*			workImage = nil;
	NSDate*				workDate = nil;
	
	if( [selectedRecords count] == 1 )
		item = [[selectedRecords objectAtIndex:0] matchActual];
	
	if( item != nil )
	{
		data = [item nodeData];
		element = [data itemElement];
		
		if( [element isCheckedOut] == YES )
		{
			statusString = @"◎ Checked Out";
			buttonTitle = @"◉";
		} else {
			statusString = @"◉ Checked In";
			buttonTitle = @"◎";
		}
		
		windowTitle = [NSString stringWithFormat:@"%@ Info", [element title]];
		
		//workImage = CFURLGetIconAsNSImageAtSize( kCFAllocatorDefault, (CFURLRef)[element elementURL], (NSSize*)NULL, (OSStatus*)NULL );
		workImage = [data iconRep];
		
		[topTitle setStringValue:[element title]];
		[topIcon setImage:workImage];
		[topIcon setEnabled:YES];
		[topButton setTitle:buttonTitle];
		[topButton setEnabled:YES];
		
		if( [element isCheckedOut] == YES )
			workDate = [element checkedOutDate];
		else
			workDate = [element checkedInDate];
		
		[topStatus setStringValue:[NSString stringWithFormat:@"%@: %@", statusString, [workDate shorterDateString]]];
		
		workString = [element comments];
		if( workString == nil ) workString = @"";
		[commentsText setStringValue:workString];
		[commentsText setEnabled:YES];
		
		[tagsTokens setObjectValue:[element tags]];
		[tagsTokens setEnabled:YES];
		
		[generalTypeIcon changeToLibraryFlavor:[element flavor]];
		[generalTypeIcon changeCurrentAlpha:0.22f];
		[generalType selectItemWithTitle:DACALFlavorToFlavorTitle([element flavor])];
		[generalType setEnabled:YES];
		[generalDeviceIcon setHidden:NO];
		[generalDeviceName setStringValue:[[element elementDevice] title]];
		[generalDeviceName setEnabled:YES];
		[generalDeviceSlot setStringValue:[NSString stringWithFormat:@"%i", [[element elementSlot] slotNumber]]];
		[generalDeviceSlot setEnabled:YES];
		[generalPath setStringValue:[item localPathString]];
		[generalPath setEnabled:YES];
		
		workSize = [[element elementSlot] volumeSize];
		if( [workSize intValue] == 0 ) workString = @"";
		else workString = [NSString stringFromByteCount:workSize];
		[generalSize setStringValue:workString];
		
		if( [element isCheckedOut] == YES )
			workString = [NSString stringWithFormat:@"%@\n%@", statusString, [[element checkedOutDate] longerDateString]];
		else
			workString = [NSString stringWithFormat:@"%@\n%@", statusString, [[element checkedInDate] longerDateString]];
		
		[generalStatus setStringValue:workString];
		
		[generalAdded setStringValue:[[data itemAddDate] longerDateString]];
		[generalRating setIntValue:[element stars]];
		[generalRating setEnabled:YES];
		
		[titleText setStringValue:[element title]];
		[titleText setEnabled:YES];
	} else {
		
		if( !selectedRecords | ([selectedRecords count] == 0) ) {
			workString = @"No Selection";
			windowTitle = @"No Selection";
		} else {
			workString = [NSString stringWithFormat:@"%i Items Selected", [selectedRecords count]];
			windowTitle = @"Multiple Selection";
		}
		
		[topTitle setStringValue:workString];
		[topIcon setImage:nil];
		[topIcon setEnabled:NO];
		[topButton setEnabled:NO];
		[topStatus setStringValue:@""];
		
		[commentsText setStringValue:@""];
		[commentsText setEnabled:NO];
		
		[tagsTokens setStringValue:@""];
		[tagsTokens setEnabled:NO];
		
//		[generalTypeIcon changeToLibraryFlavor:@"Movie"];
		[generalTypeIcon changeToNillImage];
//		[generalTypeIcon changeCurrentAlpha:0.42f];
		[generalType selectItemWithTitle:@"Movie"];
		[generalType setEnabled:NO];
		[generalDeviceIcon setHidden:YES];
		[generalDeviceName setStringValue:@""];
		[generalDeviceName setEnabled:NO];
		[generalDeviceSlot setStringValue:@""];
		[generalDeviceSlot setEnabled:NO];
		[generalPath setStringValue:@""];
		[generalPath setEnabled:NO];
		[generalSize setStringValue:@""];
		[generalStatus setStringValue:@""];
		[generalAdded setStringValue:@""];
		[generalRating setIntValue:0];
		[generalRating setEnabled:NO];
		
		[titleText setStringValue:@""];
		[titleText setEnabled:NO];
		
	}
	
	if( [self isWindowLoaded] == YES )
		[[self window] setTitle:windowTitle];
}

- (void)adoptInspectorSelection:(NSArray*)newSelection
{
	if( [selectedRecords isEqualToArray:newSelection] == YES ) return;
	
	[self extractSelectionDataAndClear:YES];
	[selectedRecords addObjectsFromArray:newSelection];
	[self installSelectionData];
}

@end		//	PADInspectorController

@implementation PADInspectorControllerPanel

-(NSUndoManager*)undoManager
{	return [(PADInspectorController*)[self windowController] undoManager];	}

@end		//	PADInspectorControllerPanel



