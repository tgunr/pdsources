//
//  PADAddVolumeController.m
//  PickADisc
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <PMUtility/pmUtility.h>
#import "AppController.h"
#import "PADAddVolumeController.h"
#import "LicenseController.h"
#import "/System/Library/Frameworks/Carbon.framework/Frameworks/NavigationServices.framework/Headers/Navigation.h"
#import "DACALDeviceService.h"
#import "DACALSlot.h"
#import "DACALDevice.h"

@implementation PADAddVolumeController

- (id)init {
	self = [super init];
	if (self) {
		pendingVolumes = [[NSMutableArray alloc] initWithCapacity:0];
		indexProgressTask = nil;
		
		[self setCustomTitle:nil];
		[self setCustomFlavor:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(finishIndexingTask:)
													 name:NSTaskDidTerminateNotification
												   object:nil];
	}
	
    return self; 
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADScanDepthVideo"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADScanDepthAudio"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADScanDepthImage"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PADScanDepthData"];
	
    [pendingVolumes release];
	[self setCustomTitle:nil];
	[self setCustomFlavor:nil];

	[pendingSlot release];
	[super dealloc];
}

- (void)awakeFromNib
{
	[[AppController shared] setAddVolumeController:self];
	
	[self syncMediaTitles];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADScanDepthVideo" options:0 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADScanDepthAudio" options:0 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADScanDepthImage" options:0 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PADScanDepthData" options:0 context:NULL];	
}


#pragma mark ###	Delegate & Notification Methods	###

//	This is called by the alternateTitle NSTextField
//	as the content changes
- (void)controlTextDidChange:(NSNotification *)aNotification
{
	NSString*		existingSlotName =[[self currentSlot] displayTitle];
	NSString*		currentSlotName = [alternateTitle stringValue];
	BOOL			currentSlotBlank = (currentSlotName) ? [currentSlotName isEqual:@""] : YES;
	BOOL			haveCustomName = (![currentSlotName isEqual:existingSlotName] || (!existingSlotName && !currentSlotBlank ));
	
	if( haveCustomName && !currentSlotBlank )
		[self setCustomTitle:currentSlotName];
	
	[self slotNameChanged:self];
}

//	This is called by the slotTypeList NSPopUpButton
//	as the user selects a menu item
-(void)menu:(NSMenu *)menu willHighlightItem:(NSMenuItem *)item
{ if( item ) [self changeToFlavor:[item title]]; }

//	This is called by the sheetWindow NSWindow
//	when it's ready to close
- (void)assignSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
	[sheet orderOut:self];
	[cancelButton setEnabled:YES];
	[self activeItemState:YES];
	[volumeIcon changeCurrentRotation:0.0];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSString*	doType = nil;
	NSString*	workKey = nil;
	BOOL		didType = NO;
	
	if (object == [NSUserDefaultsController sharedUserDefaultsController] )
	{
		if( [keyPath hasSuffix:@"PADScanDepthVideo"] ) {
			doType = PADINDEX_FLAVORTITLE_MOVIE;
			workKey = @"PADScanDepthVideo";
		} else if( [keyPath hasSuffix:@"PADScanDepthAudio"] ) {
			doType = PADINDEX_FLAVORTITLE_MUSIC;
			workKey = @"PADScanDepthAudio";
		} else if( [keyPath hasSuffix:@"PADScanDepthImage"] ) {
			doType = PADINDEX_FLAVORTITLE_IMAGE;
			workKey = @"PADScanDepthImage";
		} else if( [keyPath hasSuffix:@"PADScanDepthData"] ) {
			doType = PADINDEX_FLAVORTITLE_FILES;
			workKey = @"PADScanDepthData";
		}
	}
	
	if( doType != nil )
		if( [[self customFlavor] isEqual:doType] )
		{
			//NSUndoManager*		undo = [self undoManager];
			//NSUserDefaults*		defaults = [NSUserDefaults standardUserDefaults];
			//float				nowLevel = [depthLevel floatValue];
			//NSString*			undoName = [NSString stringWithFormat:@"Change %@ Scan Level", doType];
			
			//[[undo prepareWithInvocationTarget:defaults] setFloat:nowLevel forKey:workKey];
			//[undo setActionName:undoName];
			
			[self setCustomFlavor:nil];
			[self changeToFlavor:doType];

			didType = YES;
		} 
	
	if( !didType ) 
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

//	Not used?
- (void)windowWillBeginSheet:(NSNotification *)notification
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
//	[super windowWillBeginSheet:notification];
}

#pragma mark ###	Index Progress Window (unused)	###

//	This is the old way

-(void) indexProgressComplete:(PADIndexProgressController*)progress
{
	int				result = [progress taskResult];
//	DACALDeviceRef  currentBox= (DACALDeviceRef)DACALCommandCopyUUID( [carouselList indexOfSelectedItem]+1, NULL );
//	DACALDevice*	thisDevice = DACALDeviceForDeviceRef( currentBox );
	DACALDevice*	thisDevice = DACALDeviceForDeviceRef( [carouselList indexOfSelectedItem]+1 );
	
	if( (result == 0) && thisDevice )
		[thisDevice indexedNewVolume:[self pendingVolume] forSlot:[slotNumber intValue] ofType:[slotTypeList titleOfSelectedItem] forTarget:self]; 
		//[thisDevice indexedNewVolume:[self pendingVolume] forSlot:[slotNumber intValue] ofType:[slotTypeList titleOfSelectedItem]]; 
	else
		[AppController playUISound: kASSystemSoundDoink];

//	if( currentBox != kDACALNullDevice ) CFRelease( (CFTypeRef)currentBox );
}

-(void) startIndexProgress:(NSTimer*)timer
{
	NSString*		newTitle = [volumeList stringValue];
	NSString*		deviceTitle = [carouselList stringValue];
	DACALDeviceRef	deviceID = (DACALDeviceRef)DACALCommandCopyUUID( [carouselList indexOfSelectedItem]+1, NULL );
	DACALSlotNum	nextSlot = (DACALSlotNum)[slotNumber intValue];
	NSURL*			newPath = [self pendingURL];
	
	NSString*		doPath = @"-n";
	NSString*		deviceUUIDString = (NSString*)CFUUIDCreateString( NULL, (CFUUIDRef)deviceID );
	NSString*		doCmd = [[NSBundle mainBundle] pathForResource:@"carousel" ofType:@"sh"];
	NSMutableArray*	doArgs = [NSMutableArray arrayWithCapacity:6];
//	NSString*		slotType = [slotTypeList titleOfSelectedItem];
	
	int				doLevel = [depthLevel intValue];												
		
	if( newPath != nil )
		doPath = [NSString stringWithFormat:@"-d%@", [newPath path]];
	
	[doArgs addObject:@"-x"];
	[doArgs addObject:[NSString stringWithFormat:@"-c%@", deviceUUIDString]];
	[doArgs addObject:[NSString stringWithFormat:@"-s%i", nextSlot]];
	[doArgs addObject:[NSString stringWithFormat:@"-t%@", newTitle]];
	[doArgs addObject:[NSString stringWithFormat:@"-l%i", doLevel]];
	[doArgs addObject:doPath];
	
//	[doArgs addObject:@"-X"];
//	NSLog(@"Task Call: %@\n\t%@", doCmd, [doArgs description]);
	
	progressController = nil;
	[NSBundle loadNibNamed:@"CarouselProgress" owner:self];

	if( progressController != nil )
	{
	[progressController runProgressDialogForCommand:doCmd
										  arguments:doArgs
										  forTarget:self
									 finishSelector:@selector(indexProgressComplete:)
									 modalForWindow:parentWindow];
	
		[progressController setPrimaryPromptString:[NSString stringWithFormat:NSLocalizedString(@"Indexing “%@”...", @"Command Progress Window Primpary Prompt Format displaying new slot title name"), newTitle]];
		[progressController setSecondaryPromptString:[NSString stringWithFormat:NSLocalizedString(@"Assigning to slot %i on %@", @"Command Progress Window Secondary Prompt Format displaing target slot and device"), (int)nextSlot, deviceTitle]];
	}
}


#pragma mark ###	Choose Volume Dialog (unused)	###

-(void) chooseVolumeCancel
{
	NSLog(@"Cancel Volume");
}

-(void) chooseVolumeAccept:(NSURL*)newVolume
{
	NSLog(@"Got Volume: %@", newVolume);
	//[retain newVolume];
	
//	NSArray*	aList = [NSArray arrayWithObject:newVolume];
	
//	[self detectedMounts:aList];
}

void MyNavEventProc (NavEventCallbackMessage callBackSelector, NavCBRecPtr callBackParms, void * callBackUD)
{	
	PADAddVolumeController*		me = (PADAddVolumeController*)callBackUD;
	NavReplyRecord				theReply;
	Boolean						fileRefValid = FALSE;
	FSRef						fileRef;
	CFURLRef					fileURL = NULL;
	OSStatus					result;
	
	switch( callBackSelector )
	{
		case kNavCBStart:
			result = NavCustomControl( callBackParms->context, kNavCtlShowDesktop, NULL );
			break;
			
		case kNavCBCancel: 
			[me chooseVolumeCancel];
			break;
			
		case kNavCBAccept:
			NavDialogGetReply( callBackParms->context, &theReply );
			
			if (theReply.validRecord)
			{
				AEKeyword	keyword;
				DescType	type;
				Size		actualSize;
				
				result = AEGetNthPtr(&theReply.selection, 1, typeFSRef, &keyword, &type, &fileRef, sizeof(FSRef), &actualSize);
				if (result == noErr)
				{
					fileRefValid = true;
					fileURL = CFURLCreateFromFSRef( kCFAllocatorDefault, &fileRef );
				}
				else
				{
					bzero(&fileRef, sizeof(FSRef));
				}
			}
			
			if( fileURL != NULL ) [me chooseVolumeAccept:(NSURL*)fileURL];
			if( fileURL != NULL ) CFRelease( fileURL );
			break;
	}
	
	
}


#pragma mark ###	Window Data Access Methods	###

-(NSString*)customTitle
{ return customTitle; }

-(void)setCustomTitle:(NSString*)newTitle
{
	if( !customTitle || ![customTitle isEqual:newTitle] )
	{
		if( newTitle ) [newTitle retain];
		if( customTitle ) [customTitle release];
		customTitle = newTitle;
	}
}

-(NSString*)customFlavor
{ return customFlavor; }

-(void)setCustomFlavor:(NSString*)newFlavor
{
	if( !customFlavor || ![customFlavor isEqual:newFlavor] )
	{
		if( newFlavor ) [newFlavor retain];
		if( customFlavor ) [customFlavor release];
		customFlavor = newFlavor;
	}
}

//	Returns the number of known indexable volumes
-(NSInteger) pendingCount
{
	NSInteger	theCount = 0;
	
	if( pendingVolumes )
		theCount = [pendingVolumes count];
	
	return theCount;
}	

//	Returns the DACVolume that corresponds to the volumeList NSPopUpButton
//	user selection
-(DACVolume*)pendingVolume
{ 
	DACVolume*	currentVolume = nil;
	int			selectedIndex = [volumeList indexOfSelectedItem] - 2;
	
	if( selectedIndex >= 0 )
		currentVolume = [pendingVolumes objectAtIndex:selectedIndex];
	
	return currentVolume; 
}

//	currentDeviceRef returns a copy you should release with DACALDeviceRelease()
-(DACALDeviceRef)currentDeviceRef
{ return DACALDevicesCopyDeviceRefForIndex( [carouselList indexOfSelectedItem]+1, NULL ); }

//	Returns the DACALSlot instance that corresponds to the users selection of a
//	device and slot number - updating if necessary
-(DACALSlot*)currentSlot
{
	if( pendingSlot == nil )
		return [self updatePendingSlot];
	
	return pendingSlot; 
}

-(DACALSlot*)pendingSlot {
    return pendingSlot;
}

-(void)setPendingSlot:(DACALSlot*)newSlot {
	if( !pendingSlot || ![pendingSlot isEqual:newSlot] ) {
		if( newSlot )
            [newSlot retain];
		if( pendingSlot )
            [pendingSlot release];
		pendingSlot = newSlot;
	}
}

//	Returns the name of the volume that corresponds to the users selection
-(NSString*) pendingTitle
{
	NSString*	newTitle = nil;
	DACVolume*	theVolume = [self pendingVolume];
	
	if( theVolume != nil )
		newTitle = [theVolume mediaTitle];
		//newTitle = [NSString stringWithString:[theVolume mediaTitle]];
	
	return newTitle;
}

//	Returns the URL of the volume that corresponds to the users selection
-(NSURL*) pendingURL 
{ 
	NSURL*		currentURL = nil;
	DACVolume*	theVolume = [self pendingVolume];
	
	if( theVolume != nil )
		currentURL = [theVolume volumeURL];
	
	return currentURL; 
}

-(NSUndoManager*)undoManager
	{ return [parentWindow undoManager]; }

#pragma mark ###	Window State Methods	###

-(void)updateEnableStates
{
	BOOL			isBlankBlank = NO;
	BOOL			isExistingVolume = ([volumeList indexOfSelectedItem] - 2 >= 0);
	BOOL			isExistingSlot = [[self currentSlot] isSlotAssigned];
	BOOL			isExistingTitle = NO;
	
	if( [[alternateTitle stringValue] compare:[self pendingTitle]] == NSOrderedSame )
		isExistingTitle = YES;
	
	if( [[alternateTitle stringValue] compare:@""] == NSOrderedSame )
		isBlankBlank = YES;
	
    PMLOG(1, @"isBlankBlank: %u isExistingVolume: %u isExistingSlot: %u isExistingTitle: %u", isBlankBlank, isExistingVolume, isExistingSlot, isExistingTitle );
    BOOL setif = !isBlankBlank && !isExistingSlot;
	[okButton setEnabled: setif];
    setif = !isExistingSlot && isExistingVolume;
	[depthLevel setEnabled: setif];
    setif =  !isExistingSlot;
	[slotTypeList setEnabled: setif];
	[volumeList setEnabled: setif];
	[alternateTitle setEnabled: setif];
    setif = ([volumeList indexOfSelectedItem] < 2);
	[ejectButton setHidden: setif];
	
	if( !isExistingSlot )
		[clearTitleButton setHidden:!(!isBlankBlank && !isExistingTitle)];
	else
		[clearTitleButton setHidden:YES];
	
}

- (void)changeToFlavor:(NSString*)slotType
{
	int			doLevel = 5;
	NSString*		actualFlavor = DACALFlavorToFlavorValue( slotType );
	
	if( slotType && ([slotType isEqual:[self customFlavor]]) )
		return;
	
	[self setCustomFlavor:slotType];
	
	if(	[actualFlavor compare:PADINDEX_FLAVORVALUE_MOVIE] == NSOrderedSame )
		doLevel = [[NSUserDefaults standardUserDefaults] floatForKey:@"PADScanDepthVideo"];
	else if( [actualFlavor compare:PADINDEX_FLAVORVALUE_MUSIC] == NSOrderedSame )
		doLevel = [[NSUserDefaults standardUserDefaults] floatForKey:@"PADScanDepthAudio"];
	else if( [actualFlavor compare:PADINDEX_FLAVORVALUE_IMAGE] == NSOrderedSame )
		doLevel = [[NSUserDefaults standardUserDefaults] floatForKey:@"PADScanDepthImage"];
	else
		doLevel = [[NSUserDefaults standardUserDefaults] floatForKey:@"PADScanDepthData"];
	
	[depthLevel animateToIntValue:doLevel allowsTicksOnly:YES];
	[flavorIcon changeToLibraryFlavor:slotType];
}

-(void)guessSelectedVolumeFlavor
{
	//	NSInteger	actualIndex = [volumeList indexOfItemWithTitle:[volumeList stringValue]]; 
	NSInteger	selectedIndex = [volumeList indexOfSelectedItem] - 2;
	NSString*	guessFlavor = nil;
	BOOL		canEject = NO;
	
	if( selectedIndex >= 0 )
	{
		canEject = YES;
		guessFlavor = DACALFlavorToFlavorTitle( [[pendingVolumes objectAtIndex:selectedIndex] guessPADFlavor] );
		if( guessFlavor ) {
			[slotTypeList selectItemWithTitle:guessFlavor];
			[self changeToFlavor:guessFlavor];
		}
		
		//if( selectedIndex != actualIndex )
		//	[volumeList selectItemAtIndex:actualIndex];
	}
	
	[ejectButton setHidden: !canEject];
}

- (void)syncMediaTitles
{
	NSArray*		mediaVolumes = [[DACVolumeService sharedVolumeService] knownIndexableVolumes:nil];
	NSEnumerator*	mediaEnum = [mediaVolumes objectEnumerator];
	DACVolume*		workVolume = nil;
	
	NSString*		selectedMedia = nil;
	//Boolean			isBlankBlank = FALSE;
	NSMenu*			theMenu = [volumeList menu];
	NSMenuItem*		workItem = nil;
	
	NSFont*				italicFont = [NSFont fontWithName:@"Helvetica-Oblique" size:[NSFont systemFontSize]];
	NSDictionary*		italicDict = [NSDictionary dictionaryWithObject:italicFont forKey:NSFontAttributeName];
	NSAttributedString*	itemNoDisk = [[NSAttributedString alloc] initWithString:@"No Disk" attributes:italicDict];
	
	selectedMedia = (NSString*)[volumeList titleOfSelectedItem];
	
	[volumeList removeAllItems];
	[pendingVolumes removeAllObjects];
	
	workItem = [[NSMenuItem alloc] init];
	[workItem setAttributedTitle:itemNoDisk];
	[theMenu addItem:workItem];
	
	//[volumeList addItemWithTitle:@"No Disk"];
	
	if( [mediaVolumes count] > 0 )
		[theMenu addItem:[NSMenuItem separatorItem]];
	
	while ( workVolume = [mediaEnum nextObject] )
	{
		[pendingVolumes addObject:workVolume];
		[volumeList addItemWithTitle:[workVolume mediaTitle]];
	}
	
	if( selectedMedia != nil )
		if( [volumeList indexOfItemWithTitle:selectedMedia] != NSNotFound ) {
			[volumeList selectItemWithTitle:selectedMedia];
			[self guessSelectedVolumeFlavor];
		} 
	
	[self updateEnableStates];
	
	//if( [[alternateTitle stringValue] compare:@""] == NSOrderedSame ) isBlankBlank = TRUE;
	//[okButton setEnabled: !isBlankBlank];
	//[depthLevel setEnabled: !isBlankBlank];
	//[ejectButton setHidden:([volumeList indexOfSelectedItem] == 0)];
}

- (void)deviceSelectionChanged:(NSArray *)newSet
{
	DACALDeviceRef		newBox = (DACALDeviceRef)NULL;
	
	if( [newSet count] > 0 ) newBox = (DACALDeviceRef)[newSet objectAtIndex:0];
	
	if( currentDevice != (DACALDeviceRef)NULL ) CFRelease( (CFTypeRef)currentDevice );
	currentDevice = newBox;
	if( currentDevice != (DACALDeviceRef)NULL ) CFRetain( (CFTypeRef)currentDevice );
}

-(DACALSlot*)updatePendingSlot;
{ 
	DACALSlot*		newSlot = DACALDeviceSlotForSlotNumber( [carouselList indexOfSelectedItem]+1, [slotNumber intValue] ); 
	
	[self setPendingSlot:newSlot];
	
	return newSlot;
}

- (void)setPrompt:(NSString*)promptString
{
	if( promptString == nil )
		promptString = @"";
	
	[indexProgressPrompt setStringValue:promptString];
}

-(void)activeItemState:(BOOL)dataItemEnabled
{
	BOOL	needProgressSpinner = ([self pendingVolume] != nil);
	
	//	Deactivate everything!
	[okButton			setEnabled: dataItemEnabled];
//	[cancelButton		setEnabled: dataItemEnabled];		//	Cancel is handled manually
	[depthLevel			setEnabled: dataItemEnabled];
	[slotTypeList		setEnabled: dataItemEnabled];
	[volumeList			setEnabled: dataItemEnabled];
	[alternateTitle		setDrawsBackground: dataItemEnabled];
	[alternateTitle		setEditable: dataItemEnabled];
	[alternateTitle		setEnabled: dataItemEnabled];
	[ejectButton		setHidden: !dataItemEnabled];	
	[clearTitleButton	setHidden: !dataItemEnabled];
	[gotoSlotButton		setHidden: !dataItemEnabled];
	
	[carouselList		setEnabled: dataItemEnabled];
	[slotDial			setEnabled: dataItemEnabled];
	[slotNumber			setEnabled: dataItemEnabled];
	[volumeList			setEnabled: dataItemEnabled];
	
	//	Become Busy
	if( dataItemEnabled ) {
		[indexProgressBar stopAnimation:self];
	} else {
		[indexProgressBar startAnimation:self];
		[volumeIcon spinUpInDirection:kPADVIVStateRotateClockwise];		//	Run spin-up effect
	}
	[indexProgressBar	setHidden: dataItemEnabled ? YES : needProgressSpinner];
	
	//	Clean ups for reset
	if( dataItemEnabled ) {
		[self setPrompt:@"Please select a destination device slot\nand a CD or DVD to index."];
		[self setCustomTitle:@""];
		[self setCustomFlavor:@""];
	}
}

#pragma mark ###	Run Index Script Methods	###

- (void)startIndexingTask
{
	[self activeItemState:NO];
	
	DACALDeviceRef		deviceID = [self currentDeviceRef];
	DACALSlotNum		deviceSlot = (DACALSlotNum)[slotNumber intValue];
	NSString*			deviceTitle = [carouselList titleOfSelectedItem];
	NSString*			newTitle = [alternateTitle stringValue];
	NSURL*				newPath = [self pendingURL];
	
	NSString*	primaryPrompt = [NSString stringWithFormat:NSLocalizedString(@"Indexing “%@”...", @"Command Progress Window Primpary Prompt Format displaying new slot title name"), newTitle];
	NSString*	secondaryPrompt = [NSString stringWithFormat:NSLocalizedString(@"Assigning to slot %i on %@", @"Command Progress Window Secondary Prompt Format displaing target slot and device"), (int)deviceSlot, deviceTitle];
	NSString*	promptText = [NSString stringWithFormat:@"%@\n%@", primaryPrompt, secondaryPrompt];
	
	[self setPrompt:promptText];
	
	//	Ready script call
	NSString*		doPath = @"-n";
	NSString*		deviceUUIDString = (NSString*)CFUUIDCreateString( NULL, (CFUUIDRef)deviceID );
	NSString*		doCmd = [[NSBundle mainBundle] pathForResource:@"carousel" ofType:@"sh"];
	NSMutableArray*	doArgs = [NSMutableArray arrayWithCapacity:6];	
	int				doLevel = [depthLevel intValue];
	
	if( doLevel == [depthLevel maxValue] )			// For "max" setting we do "all"
		doLevel = 0;
	
	if( newPath != nil )
		doPath = [NSString stringWithFormat:@"-d%@", [newPath path]];
	
	[doArgs addObject:@"-x"];
	[doArgs addObject:[NSString stringWithFormat:@"-c%@", deviceUUIDString]];
	[doArgs addObject:[NSString stringWithFormat:@"-s%i", deviceSlot]];
	[doArgs addObject:[NSString stringWithFormat:@"-t%@", newTitle]];
	[doArgs addObject:[NSString stringWithFormat:@"-l%i", doLevel]];
	[doArgs addObject:doPath];
	
	NSTask*			doTask = [[[NSTask alloc] init] autorelease];
	
	[doTask setLaunchPath:doCmd];
	[doTask setArguments:doArgs];
	
	indexProgressTask = doTask;
	
	[doTask launch];
}

- (void)finishIndexingTask:(NSNotification*)aNotice
{
	if( [aNotice object] != indexProgressTask ) return;
	
	NSInteger		taskResult = [[aNotice object] terminationStatus];
	DACALDevice*	destDevice = [[self pendingSlot] slotDevice];
	DACVolume*		newVolume = [self pendingVolume];

	[cancelButton setEnabled:NO];
	indexProgressTask = nil;

	if( taskResult == 0 )
		[self setPrompt:@"Indexing complete.\nAdding configuration to carousel."];	
	else
		[self setPrompt:@"Indexing error #%ld.\nCancelling request."]; 
	
	[volumeIcon spinDown];
	[indexProgressBar setHidden:NO];
	
	if( taskResult == 0 ) {
		//[self setPrompt:@"Indexing complete.\nAdding configuration to carousel."];	
		[destDevice indexedNewVolume:newVolume forSlot:[slotNumber intValue] ofType:DACALFlavorToFlavorValue([slotTypeList titleOfSelectedItem]) forTarget:self]; 
	} else {
		//[self setPrompt:@"Indexing error #%ld.\nCancelling request."]; 
		[self indexDeviceControlFinished:self];
	}
}

//	If indexing succedes this is called by the DACALDevice once the slot node is usable
//	otherwise it's called from -finishIndexingTask: directly with self.
-(void)indexDeviceControlFinished:(id)sender
{
	BOOL	goodIndex = NO;
	
	if( sender != self ) {
		goodIndex = YES;
		[self setPrompt:@"Indexing complete."];
	}
	
	[AppController playUISoundForBOOL:goodIndex];

	[indexProgressBar stopAnimation:self];
	
	[NSApp endSheet:sheetWindow];
}


#pragma mark ###	IBAction Methods	###

-(IBAction) clickCancel:(id)sender 
{
	if( indexProgressTask != nil ) {
		[self setPrompt:@"Cancelling request..."];
		[indexProgressTask interrupt];
	} else
		[NSApp endSheet:sheetWindow];
}

-(IBAction) clickOK:(id)sender
{
	[self startIndexingTask];
}
/*
	// Progress Bar Window Way
 
	[NSApp endSheet:sheetWindow];
	
	[NSTimer scheduledTimerWithTimeInterval:0.2
									 target:self
								   selector:@selector(startIndexProgress:)
								   userInfo:parentWindow
									repeats:NO];		
		
*/
	
/*		
	// Old Old Way

	NSString*		newTitle = [slotTitle stringValue];
	DACALDeviceRef	deviceID = (DACALDeviceRef)[carouselList indexOfSelectedItem]+1;
	DACALSlotNum	nextSlot = (DACALSlotNum)[slotNumber intValue];
	NSURL*			newPath = [self pendingURL];
	
	DACALResult theErr = DACALSlotCreateIndex( deviceID, nextSlot, (CFStringRef)newTitle, 0, (CFURLRef)newPath );
	if( theErr == 0 ) {
		[AppController playUISound: kASSystemSoundSuccess];
//		if( isPending && ([self pendingCount] > 1) ) {
//			[self popPending];
//			return;
//		}
		[NSApp endSheet:sheetWindow];
		return;
	}
	[AppController playUISound: kASSystemSoundDoink];
*/


-(IBAction) clickType:(id)sender
{
	//[self changeToFlavor:[slotTypeList titleOfSelectedItem]]; }
	return;
}

// There is no longer a choose button
-(IBAction) clickChoose:(id)sender { 

	NavDialogCreationOptions	theNavOpts;
	NavDialogRef				theNavRef;
	OSStatus					theErr;
	
	theErr = NavGetDefaultDialogCreationOptions( &theNavOpts );

	theNavOpts.windowTitle = CFSTR("PickADisk Choose A Disc");
	
	theErr = NavCreateChooseVolumeDialog( &theNavOpts, &MyNavEventProc, NULL, (void*)self, &theNavRef );
	if( theErr != noErr ) goto NAVERR;
	
	theErr = NavDialogRun( theNavRef );
	
NAVERR:
	
	return;
}

-(IBAction) clickEject:(id)sender
{
	BOOL		goodE = NO;
	DACVolume*	theV = [self pendingVolume];
	
	if( theV )
		goodE = [theV ejectVolume];

	[AppController playUISoundForResult: (goodE == YES) ? kDACALOK : kDACALError];
}

-(IBAction) clickGotoSlot:(id)sender
{
	DACALSlot*	theS = [self currentSlot];
	
	if( theS )
		[theS moveDeviceToSlotWithOptions:kDACALOptionMoveDefault];
}

-(IBAction) clickClearTitle:(id)sender
{
	[self setCustomTitle:nil];
	[alternateTitle setStringValue:@""];
	
	[self slotNameChanged:sender];
}

-(IBAction) slotChanged:(id)sender 
{
	DACALSlot*		thisSlot = [self updatePendingSlot];
	NSString*		existingSlotName =[thisSlot displayTitle];
	NSString*		existingSlotFlavor = [thisSlot flavor];
	NSString*		blankSlotName = [self pendingTitle];
	NSString*		currentSlotName = [alternateTitle stringValue];
	BOOL			currentNameBlank = (currentSlotName) ? [currentSlotName isEqual:@""] : YES;
	BOOL			haveCustomName = ( existingSlotName && ![existingSlotName isEqual:currentSlotName] );
	
	if( haveCustomName || currentNameBlank ) {
		if( customTitle )
			blankSlotName = [customTitle retain];
		//if( existingSlotName )
		//	[self setCustomTitle:currentSlotName];
	}
	
	if( blankSlotName == nil ) {
		blankSlotName = @"";
	}
	
	if( existingSlotName )
		[alternateTitle setStringValue:existingSlotName];
	else
		[alternateTitle setStringValue:blankSlotName];
	 
	if( existingSlotName && existingSlotFlavor )
	{
		[slotTypeList selectItemWithTitle:DACALFlavorToFlavorTitle( existingSlotFlavor )];
		[self changeToFlavor:existingSlotFlavor];
	}
	
	if( haveCustomName )
		[blankSlotName release];
	
	[self updateEnableStates];
}

//	The slot "title" is the slot number

-(IBAction) slotTitleChanged:(id)sender
{
	[slotDial setIntValue:[slotNumber intValue]];
	[alternateTitle setStringValue:@""];
	[self slotChanged:sender];
}

-(IBAction) slotDialChanged:(id)sender 
{
	[slotNumber setIntValue:[slotDial intValue]];
	[alternateTitle setStringValue:@""];
	[self slotChanged:sender];
}

//	The slot "name" is the actual volume selected in the popup

-(IBAction) slotNameChanged:(id)sender
{
	NSInteger		selectedIndex = [volumeList indexOfSelectedItem] - 2;

	//if( [[alternateTitle stringValue] compare:@""] == NSOrderedSame )
	//	[alternateTitle setStringValue:[[self pendingVolume] mediaTitle]];
	
	if( selectedIndex >= 0 ) {
		[self guessSelectedVolumeFlavor];
		if( [[alternateTitle stringValue] compare:@""] == NSOrderedSame )
			[alternateTitle setStringValue:[[self pendingVolume] mediaTitle]];
		[volumeIcon changeToVolumeIcon:[self pendingVolume]];
	} else {
		if( [volumeList indexOfItemWithTitle:[alternateTitle stringValue]] != -1 )
			[alternateTitle setStringValue:@""];
		[volumeIcon changeToNillImage];
	}
	
	[self updateEnableStates];
}

-(IBAction) carouselChanged:(id)sender
{
	DACALDeviceRef	deviceID = (DACALDeviceRef)[carouselList indexOfSelectedItem]+1;
	DACALSlotNum	nextSlot = DACALSlotNextFreeNumber( deviceID, 0, 0, NULL );
	
	if( nextSlot ) {
		[slotNumber setIntValue: nextSlot];
		[slotDial setIntValue:nextSlot];
		[alternateTitle setStringValue:@""];
		[self slotChanged: sender];
	}
}




#pragma mark ###	Sheet Window Entry Point	###

- (void)startSheet:(id)sender
{
//	NSInteger	index;
//	NSInteger	count = DACALDevicesGetCount();
	NSInteger	node = DACALCommandCopyNode( currentDevice, NULL );
	
	if( ![[DACALDeviceService sharedService] countUsedSlots:NULL] )
	{
		[[LicenseController sharedLicenseController] runNotLicensedModalWindow];
		return;
	}
	
	// Do Carousels
	
	[carouselList removeAllItems];
	[carouselList addItemsWithTitles:(NSArray*)DACALDevicesCopyAllNames()];
	//for( index=1; index <= count; index++ )
	//	[carouselList addItemWithTitle:(NSString*)DACALCommandCopyName( index, NULL )];
	
	if( node == 0 )
        node = 1;
	[carouselList selectItemAtIndex:node-1];
	
	// Do Media
	[self syncMediaTitles];
	
	// Set Level
	[self setCustomFlavor:nil];
	[self changeToFlavor:[slotTypeList titleOfSelectedItem]];
	
	// Be Changed
	[self carouselChanged:self];
	
	parentWindow = (NSWindow*)sender;
	
	if( sheetWindow )
		[NSApp	beginSheet: sheetWindow
		   modalForWindow: (NSWindow*)parentWindow
			modalDelegate: self
		   didEndSelector: @selector(assignSheetDidEnd:returnCode:contextInfo:)
			  contextInfo: nil];
}

#pragma mark ###	Device Notifications	###

- (void)carouselListChanged
{
	NSString*		theSel = nil;// [carouselList titleOfSelectedItem];
	NSArray*		newTitles = (NSArray*)DACALDevicesCopyAllNames();
	NSInteger		goneNode = 0;
	
	if( (newTitles == nil) || ([newTitles count] == 0) )
	{
		if( [sheetWindow isVisible] == YES )
			[self clickCancel:self];
		
		return;
	}
	
	if( [sheetWindow isVisible] == NO ) return;
	
	theSel = [carouselList titleOfSelectedItem];
	
	[carouselList removeAllItems];
	[carouselList addItemsWithTitles:newTitles];

	goneNode = [carouselList indexOfItemWithTitle:theSel];
	
	if( (currentDevice == kDACALNullDevice) || (theSel == nil) || (goneNode == NSNotFound) )
		[carouselList selectItemAtIndex:0];
	else
		[carouselList selectItemWithTitle:theSel];
	
	[self carouselChanged:self];
}

- (void)detectedVolumes:(NSArray *)newVolumes
{
	int			mediaIndex;
	int			lastIndex = [pendingVolumes count];
	
	if( [sheetWindow isVisible] == NO )
        return;
	
    // TODO: Add check for mounted volume detection to auto matically set title field if present.ta
	if( lastIndex == 0 ) {
		NSMenu*		theMenu = [volumeList menu];
		[theMenu addItem:[NSMenuItem separatorItem]];
		lastIndex++;
	}
	
	[pendingVolumes addObjectsFromArray:newVolumes];
	for( mediaIndex=0; mediaIndex < [newVolumes count]; mediaIndex++ )
		[volumeList addItemWithTitle:[[newVolumes objectAtIndex:mediaIndex] mediaTitle]];
	
	if( [newVolumes count] > 0 ) {
		
		[volumeList selectItemAtIndex:lastIndex+1];
		//[volumeList setStringValue:[volumeList objectValueOfSelectedItem]];
		[self guessSelectedVolumeFlavor];
		[volumeIcon changeToVolumeIcon:[self pendingVolume]];
		
	} else {

		[self syncMediaTitles];
		
	}

	[self carouselChanged:self];

}

- (void)ejectedVolumes:(NSArray*)oldVolumes;
{
	int				mountIndex;
	NSUInteger		foundIndex;
	int				mountCount = [oldVolumes count];
	Boolean			isBlankBlank = FALSE;
	
	for( mountIndex=0; mountIndex < mountCount; mountIndex++ )
	{
		foundIndex = [pendingVolumes indexOfObject:[oldVolumes objectAtIndex:mountIndex]];
		if( foundIndex != NSNotFound )
		{
			[pendingVolumes removeObjectAtIndex:foundIndex];
			if( [volumeList indexOfSelectedItem]-2 == foundIndex ) {
				[volumeList selectItemAtIndex:0];
				//[volumeList deselectItemAtIndex:foundIndex];
				//[volumeList setStringValue:@""];
				[alternateTitle setStringValue:@""];
			}
			[volumeList removeItemWithTitle:[[oldVolumes objectAtIndex:mountIndex] mediaTitle]];
		}
		
	}

	[self updateEnableStates];
	
	if( [[alternateTitle stringValue] compare:@""] == NSOrderedSame ) isBlankBlank = TRUE;
	[okButton setEnabled: !isBlankBlank];
	[depthLevel setEnabled: !isBlankBlank];
}

/*	old ways

- (void)detectedMounts:(NSArray *)newMounts
{
	int			mediaIndex;
	int			lastIndex = [pendingVolumes count];

	if( [sheetWindow isVisible] == NO ) 
		return;

	[pendingVolumes addObjectsFromArray:newMounts];
	for( mediaIndex=0; mediaIndex < [newMounts count]; mediaIndex++ )
		[volumeList addItemWithTitle:(id)CFURLCopyDisplayName( kCFAllocatorDefault, (CFURLRef)[newMounts objectAtIndex:mediaIndex], NULL )];
				
	if( [newMounts count] > 0 ) {

		[volumeList selectItemAtIndex:lastIndex];
		[volumeList setStringValue:[volumeList titleOfSelectedItem]];
		
		// DO DISK ID HERE!!
		
//		[self setPendingURL:[pendingVolumes objectAtIndex:0]];
//		[self setPendingTitle: (NSString*)CFURLCopyDisplayName( NULL, (CFURLRef)[self pendingURL], NULL)];
//		[self setPendingTitle: (NSString*)CFURLCopyDisplayName( NULL, (CFURLRef)[pendingVolumes objectAtIndex:0], NULL)];
//		isPending = YES;
	} else {
//		[self setPendingURL: nil];
//		[self setPendingTitle: nil];
//		isPending = NO;
		
		[self syncMediaTitles];
		
	}
	[self carouselChanged:self];


//	if( pendingVolumes == NULL ) pendingVolumes = [NSMutableArray arrayWithCapacity:[newMounts count]+10];
//	[pendingVolumes addObjectsFromArray:newMounts];
//	[self pushPending];

 }

- (void)ejectedMounts:(NSArray*)oldMounts
{
	int				mountIndex;
	NSUInteger		foundIndex;
	int				mountCount = [oldMounts count];
	Boolean			isBlankBlank = FALSE;
	
	for( mountIndex=0; mountIndex < mountCount; mountIndex++ )
	{
		foundIndex = [pendingVolumes indexOfObject:[oldMounts objectAtIndex:mountIndex]];
		if( foundIndex != NSNotFound )
		{
			[pendingVolumes removeObjectAtIndex:foundIndex];
			if( [volumeList indexOfSelectedItem] == foundIndex ) {
				[volumeList selectItemAtIndex:0];
				//[volumeList deselectItemAtIndex:foundIndex];
				//[volumeList setStringValue:@""];
			}
			[volumeList removeItemAtIndex:foundIndex];
		}
		
	}
	
	if( [[alternateTitle stringValue] compare:@""] == NSOrderedSame ) isBlankBlank = TRUE;
	[okButton setEnabled: !isBlankBlank];
	[depthLevel setEnabled: !isBlankBlank];

}

*/

@end













