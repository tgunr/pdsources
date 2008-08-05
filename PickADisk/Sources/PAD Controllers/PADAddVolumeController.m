//
//  PADAddVolumeController.m
//  PickADisc
//
//  Created by Jack Small on 7/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PADAddVolumeController.h"

#import "pmsDACALUtility.h"

@implementation PADAddVolumeController

- (id)init {
    if (self = [super init]) {
		//isPending = NO;
		pendingVolumes = [[NSMutableArray arrayWithCapacity:100] retain];
	}
	
    return self; 
}

- (void)dealloc {

    [pendingVolumes release];

    [super dealloc];
}

- (void)awakeFromNib
{
	[[AppController shared] setAddVolumeController:self];
	//pendingVolumes = [NSMutableArray arrayWithCapacity:0];
	pendingVolumes = [[NSMutableArray arrayWithCapacity:100] retain];
	//if( cdIcon ) [cdIcon setAlphaValue: 0.22];
	[self syncMediaTitles];
}

-(NSInteger) pendingCount
{
	NSInteger	theCount = 0;
	
	if( pendingVolumes == NULL ) theCount = 0;					// Paranoid?
	else if( pendingVolumes == nil ) theCount = 0;

	else theCount = [pendingVolumes count];
	
	return theCount;
}	
/*
- (void)pushPending
{
	NSInteger	theCount = [self pendingCount];
	
	if( theCount > 0 ) {
		[self setPendingURL:[pendingVolumes objectAtIndex:0]];
		[self setPendingTitle: (NSString*)CFURLCopyDisplayName( NULL, (CFURLRef)[self pendingURL], NULL)];
		

// DISK ID STUFF
// 
		if( [[self pendingTitle] compare:@"Audio CD"] == NSOrderedSame )
		{
			FSRef			theRef;
			FSCatalogInfo	theInfo;
			FSVolumeRefNum	theVRef;
			CFStringRef		diskIDRef;
			CFStringRef		diskPath;
			const char*		diskIDStr = NULL;
			OSStatus		theErr;
			
			DiscId*			disc = discid_new();
			
			theErr = CFURLGetFSRef((CFURLRef)[self pendingURL], &theRef );
			theErr = FSGetCatalogInfo( &theRef, kFSCatInfoVolume, &theInfo, NULL, NULL, NULL );
			theVRef = theInfo.volume;
					
			theErr = FSCopyDiskIDForVolume( theVRef, &diskIDRef );
			diskPath = CFStringCreateWithFormat( kCFAllocatorDefault, NULL, CFSTR("/dev/r%@"), diskIDRef );
			diskIDStr = CFStringCreateCString( diskPath, kCFStringEncodingUTF8 );
			
			fprintf(stderr, "Default Device: %s\n", discid_get_default_device() );
			
			if ( discid_read(disc, diskIDStr) == 0 ) {
				fprintf(stderr, "Error: %s\n", discid_get_error_msg(disc));
			} else {
				fprintf(stderr, "DiscID        : %s\n", discid_get_id(disc));
				fprintf(stderr, "Submit via    : %s\n", discid_get_submission_url(disc));
			}

			discid_free(disc); 
			free( (void*)diskIDStr );
			CFRelease( diskIDRef );
			CFRelease( diskPath );
		}
//
// END DISK ID STUFF
		
		isPending = YES;
	} else {
		[self setPendingURL: nil];
		[self setPendingTitle: nil];
		isPending = NO;
	}
	[self carouselChanged:self];
}


- (void)popPending
{	
	NSInteger	theCount = [self pendingCount];
		
	if( theCount > 0 ) [pendingVolumes removeObjectAtIndex:0];
	if( theCount <= 1 ) {
		if( pendingVolumes != NULL ) [pendingVolumes release];
		pendingVolumes = NULL;
	}
	[self pushPending];
}
*/

-(IBAction) clickCancel:(id)sender 
{
	[NSApp endSheet:sheetWindow];
}

-(void) indexProgressComplete:(PADIndexProgressController*)progress
{
	int		result = [progress taskResult];
	int		sound = kASSystemSoundSuccess;
	DACALDeviceRef  currentBox= (DACALDeviceRef)DACALCommandCopyUUID( [carouselList indexOfSelectedItem]+1, NULL );
	DACALSlotNum	currentSlot =  (DACALSlotNum)[slotNumber intValue];
	NSURL*			currentVolume = [self pendingURL];
	
	if( result != 0 )
		sound = kASSystemSoundDoink;

	if( result == 0 )
	{
		[[DACALTreeDataSource shared] slotAddedToDevice: currentBox forSlot: currentSlot];

		if( ([[NSUserDefaults standardUserDefaults] boolForKey:@"PADEjectOnIndex"] == YES ) && (currentVolume != nil) )
			[[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath: [currentVolume path]];
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"PADCheckInOnIndex"] == YES )
			DACALCommandMoveToSlotWithOptions( currentBox, currentSlot, kDACALOptionMoveDefault );
	}

	[AppController playUISound: sound];
}

-(void) startIndexProgress:(NSTimer*)timer
{
	NSString*		newTitle = [slotTitle stringValue];
	DACALDeviceRef	deviceID = (DACALDeviceRef)DACALCommandCopyUUID( [carouselList indexOfSelectedItem]+1, NULL );
	DACALSlotNum	nextSlot = (DACALSlotNum)[slotNumber intValue];
	NSURL*			newPath = [self pendingURL];
	
	NSString*		doPath = @"-n";
	NSString*		deviceUUIDString = (NSString*)CFUUIDCreateString( NULL, (CFUUIDRef)deviceID );
	NSString*		doCmd = [[NSBundle mainBundle] pathForResource:@"carousel" ofType:@"sh"];
	NSMutableArray*	doArgs = [NSMutableArray arrayWithCapacity:6];
	
	int				doLevel = 4;													// Should use user defaults!
//	PADIndexProgressController*	progressController = nil;
	
	if( newPath != nil )
		doPath = [NSString stringWithFormat:@"-d%@", [newPath path]];
	
//	if( !([[NSUserDefaults standardUserDefaults] boolForKey:@"PADEjectOnIndex"] == YES ) && !([self pendingURL] != nil) )
		[doArgs addObject:@"-x"];
	[doArgs addObject:[NSString stringWithFormat:@"-c%@", deviceUUIDString]];
	[doArgs addObject:[NSString stringWithFormat:@"-s%i", nextSlot]];
	[doArgs addObject:[NSString stringWithFormat:@"-t%@", newTitle]];
	[doArgs addObject:[NSString stringWithFormat:@"-l%i", doLevel]];
	[doArgs addObject:doPath];
	
//	[doArgs addObject:@"-X"];
	NSLog(@"Task Call: %@\n\t%@", doCmd, [doArgs description]);
	
	progressController = nil;
	[NSBundle loadNibNamed:@"CarouselProgress" owner:self];

	if( progressController != nil )
	{
	[progressController runProgressDialogForCommand:doCmd
										  arguments:doArgs
										  forTarget:self
									 finishSelector:@selector(indexProgressComplete:)
									 modalForWindow:parentWindow];
	
		[progressController setPrimaryPromptString:[NSString stringWithFormat:@"Indexing “%@”...", newTitle]];
		[progressController setSecondaryPromptString:[NSString stringWithFormat:@"Assigning to slot %i", (int)nextSlot]];
	}
}

-(IBAction) clickOK:(id)sender
{
	
	[NSApp endSheet:sheetWindow];
	
	[NSTimer scheduledTimerWithTimeInterval:0.2
									 target:self
								   selector:@selector(startIndexProgress:)
								   userInfo:parentWindow
									repeats:NO];		
		
		
/*		
	// Old Way

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
}

-(IBAction) clickType:(id)sender
{
	NSInteger	theTypeName = [slotTypeList indexOfSelectedItem];
	
	if( theTypeName == 1 )		[cdIcon setImage: DACALGetIconImageForType('cdda')];
	else if( theTypeName == 2 ) [cdIcon setImage: DACALGetIconImageForType('dvd ')];
	else						[cdIcon setImage: DACALGetIconImageForType('Dcd ')];
}

-(void) chooseVolumeCancel
{
	NSLog(@"Cancel Volume");
}

-(void) chooseVolumeAccept:(NSURL*)newVolume
{
	NSLog(@"Got Volume: %@", newVolume);
	//[retain newVolume];
	
	NSArray*	aList = [NSArray arrayWithObject:newVolume];

	[self detectedMounts:aList];
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
-(IBAction) slotChanged:(id)sender 
{
	CFStringRef		existingSlotName = DACALSlotCopyTitle( [carouselList indexOfSelectedItem]+1, [slotNumber intValue], NULL );
	CFStringRef		blankSlotName = (CFStringRef)[self pendingTitle];
	BOOL			isBlankBlank = FALSE;
	
	if( blankSlotName == NULL ) blankSlotName = CFSTR("");
	
	 if( existingSlotName ) [slotTitle setStringValue:(NSString*)existingSlotName];
	 else [slotTitle setStringValue: (NSString*)blankSlotName];
	 
	if( [[slotTitle stringValue] compare:@""] == NSOrderedSame ) isBlankBlank = TRUE;
	 [okButton setEnabled: !isBlankBlank];
	 [slotTitle setEnabled: (!existingSlotName) ? YES : NO];
}

-(IBAction) slotTitleChanged:(id)sender 
{
	[slotDial setIntValue:[slotNumber intValue]];
	[self slotChanged:sender];
}

-(IBAction) slotDialChanged:(id)sender 
{
	[slotNumber setIntValue:[slotDial intValue]];
	[self slotChanged:sender];
}

-(IBAction) slotNameChanged:(id)sender
{
	BOOL			isBlankBlank = FALSE;

	//[self slotChanged:sender];
	
	if( [[slotTitle stringValue] compare:@""] == NSOrderedSame ) isBlankBlank = TRUE;
	[okButton setEnabled: !isBlankBlank];
}

-(IBAction) carouselChanged:(id)sender
{
	DACALDeviceRef	deviceID = (DACALDeviceRef)[carouselList indexOfSelectedItem]+1;
	DACALSlotNum	nextSlot = DACALSlotNextFreeNumber( deviceID, 0, 0, NULL );
	
	if( nextSlot ) {
		[slotNumber setIntValue: nextSlot];
		[self slotChanged: sender];
	}
}

-(NSString*) pendingTitle
{
	NSString*	newTitle = nil;
	NSURL*		theURL = [self pendingURL];
	
	if( theURL != nil )
		newTitle = (NSString*)CFURLCopyDisplayName( NULL, (CFURLRef)theURL, NULL);
	
	return newTitle;
}

/*
-(void)setPendingTitle:(NSString*)inTitle
{
    if (!pendingTitle || ![pendingTitle isEqual:inTitle]) {
		[pendingTitle release];
		pendingTitle = [inTitle retain];
    }
}
*/

-(NSURL*) pendingURL 
{ 
	NSURL*	currentURL = nil;
	int		selectedIndex = [slotTitle indexOfSelectedItem];
	
	if( selectedIndex != -1 )
		currentURL = [pendingVolumes objectAtIndex:selectedIndex];
	
	return currentURL; 
}


/*
 -(void)setPendingURL:(NSURL*)inPath
{
    if (!pendingURL || ![pendingURL isEqual:inPath]) {
		[pendingURL release];
		pendingURL = [inPath retain];
    }
}
*/

- (void)windowWillBeginSheet:(NSNotification *)notification
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	[super windowWillBeginSheet:notification];
}

- (void)deviceSelectionChanged:(NSArray *)newSet
{
	DACALDeviceRef		newBox = (DACALDeviceRef)NULL;
	
	if( [newSet count] > 0 ) newBox = (DACALDeviceRef)[newSet objectAtIndex:0];
	
	if( currentDevice != (DACALDeviceRef)NULL ) CFRelease( (CFTypeRef)currentDevice );
	currentDevice = newBox;
	if( currentDevice != (DACALDeviceRef)NULL ) CFRetain( (CFTypeRef)currentDevice );
}

- (void)assignSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
	[sheet orderOut:self];
}

- (void)syncMediaTitles
{
	NSArray*	mediaPaths = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
	int			mediaCount = [mediaPaths count];
	int			mediaIndex;
	NSString*		selectedMedia = nil;
	int				selectedIndex;
	Boolean		isBlankBlank = FALSE;
	
	//pendingVolumes = [[NSMutableArray arrayWithCapacity:100] retain];
	
	
	
	selectedMedia = (NSString*)[slotTitle objectValueOfSelectedItem];
	selectedIndex = [slotTitle indexOfSelectedItem];
	
	[slotTitle removeAllItems];

	if( mediaCount == 0 ) [pendingVolumes removeAllObjects];
	else {
		//if( pendingVolumes == nil ) pendingVolumes = [NSMutableArray arrayWithCapacity:10];
		for( mediaIndex=0; mediaIndex < mediaCount; mediaIndex++ )	{										// This list should be filtered to remove known discs!
			[pendingVolumes addObject:[NSURL fileURLWithPath:[mediaPaths objectAtIndex:mediaIndex]]];
			[slotTitle addItemWithObjectValue:(id)CFURLCopyDisplayName( kCFAllocatorDefault, (CFURLRef)[pendingVolumes objectAtIndex:mediaIndex], NULL )];
		}
	}
		
	//NSLog(@"index = %i",[slotTitle indexOfItemWithObjectValue:selectedMedia]);
	
	if( selectedMedia != nil ) {
		if( [slotTitle indexOfItemWithObjectValue:selectedMedia] != INT32_MAX )
			[slotTitle selectItemWithObjectValue:selectedMedia];
		else
			[slotTitle setStringValue:@""];
	}
	
	//[self slotChanged:self];
	if( [[slotTitle stringValue] compare:@""] == NSOrderedSame ) isBlankBlank = TRUE;
	[okButton setEnabled: !isBlankBlank];

}

- (void)startSheet:(id)sender
{
//	NSInteger	index;
//	NSInteger	count = DACALDevicesGetCount();
	NSInteger	node = DACALCommandCopyNode( currentDevice, NULL );
	
	// Do Carousels
	
	[carouselList removeAllItems];
	[carouselList addItemsWithTitles:(NSArray*)DACALDevicesCopyAllNames()];
	//for( index=1; index <= count; index++ )
	//	[carouselList addItemWithTitle:(NSString*)DACALCommandCopyName( index, NULL )];
	
	if( node == 0 ) node = 1;
	[carouselList selectItemAtIndex:node-1];
	
	// Do Media
	//[self syncMediaTitles];
	
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

- (void)detectedMounts:(NSArray *)newMounts
{
	int			mediaIndex;
	int			lastIndex = [pendingVolumes count];

	if( [sheetWindow isVisible] == NO ) return;

	[pendingVolumes addObjectsFromArray:newMounts];
	for( mediaIndex=0; mediaIndex < [newMounts count]; mediaIndex++ )											// This list should be filtered to remove known discs!
		[slotTitle addItemWithObjectValue:(id)CFURLCopyDisplayName( kCFAllocatorDefault, (CFURLRef)[newMounts objectAtIndex:mediaIndex], NULL )];
				
	if( [newMounts count] > 0 ) {

		[slotTitle selectItemAtIndex:lastIndex];
		[slotTitle setStringValue:[slotTitle objectValueOfSelectedItem]];
		
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

/*	
	if( pendingVolumes == NULL ) pendingVolumes = [NSMutableArray arrayWithCapacity:[newMounts count]+10];
	[pendingVolumes addObjectsFromArray:newMounts];
	[self pushPending];
*/
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
			if( [slotTitle indexOfSelectedItem] == foundIndex ) {
				[slotTitle deselectItemAtIndex:foundIndex];
				[slotTitle setStringValue:@""];
			}
			[slotTitle removeItemAtIndex:foundIndex];
		}
		
	}
	
	if( [[slotTitle stringValue] compare:@""] == NSOrderedSame ) isBlankBlank = TRUE;
	[okButton setEnabled: !isBlankBlank];

}

@end













