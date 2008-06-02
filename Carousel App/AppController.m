#import "AppController.h"
#import "davec.h"

@implementation AppController

// explanation string to instruct the user what double-click operation on a path component does:
NSString *const kFinderTitle = @"Double-click a path component to reveal it in the Finder.";
NSString *const kInsertTitle = @"or insert media into drive for processing"; 


// explanation/place holder string to instruct the user on how they can set the path
NSString *const kExplainTitle = @"<html><center>Drag a folder to this area or click the button above'</center></html>";

- (DACALDeviceRef) currentCarousel {
	NSLogFunc;
	int carousel = [carouselNum intValue];
	return (DACALDeviceRef)carousel;
}

+ (void)initialize {
	NSLogFunc;
    if (self == [AppController class]) {    // We want to do this once
	}
}

- (id)init {
	NSLogFunc;
    if (self = [super init]) {
    }
    return self;
}

- (void)dealloc {
	NSLogFunc;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib {
	NSLogFunc;
	[sourcePath setPathStyle: NSPathStyleStandard];
    [sourcePath setTarget:self];
    [sourcePath setDoubleAction:@selector(sourcePathControlDoubleClick:)];
	[sourcePath setDelegate:self];
	
	workSpace = [NSWorkspace sharedWorkspace];
	NSNotificationCenter *notCenter;
	SEL observerMethodSEL;
	
	// Assume -observerMethod:(id)aNotification exists
	observerMethodSEL = @selector(newMediaDetected:);
	notCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[notCenter addObserver:self selector:observerMethodSEL
					  name:@"NSWorkspaceDidMountNotification" object:nil]; // Register for all notifications
	
	DACALResult	dcresult =	DACALDevicesInitialize();
	carouselCount = DACALDevicesGetCount();
	DACALDeviceRef dcDefault = DACALDevicesGetDefaultDevice();
	
	[createButton setEnabled:FALSE];
	[slotCloseButton setEnabled:FALSE];
	[slotGotoButton setEnabled:FALSE];
	
	[carouselStepper setMaxValue:carouselCount];
	[carouselStepper setIntValue:dcDefault];
	
	[autoEjectButton setEnabled:FALSE];
	autoEject = [autoEjectButton intValue];
	noDisc = [noDiscButton intValue];

	[self updateSourceUI:FALSE];
}

- (void) applicationDidFinishLaunching:(NSNotification *) aNotification {	
	NSLogFunc;
	//    deviceList = [[NSMutableArray alloc] initWithCapacity:[[DRDevice devices] count]];
	//    [[DRNotificationCenter currentRunLoopCenter] addObserver:self selector:@selector(deviceDisappeared:) 
	//														name:DRDeviceDisappearedNotification object:nil];
	//    [[DRNotificationCenter currentRunLoopCenter] addObserver:self selector:@selector(deviceAppeared:) 
	//														name:DRDeviceAppearedNotification object:nil];
	
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	NSLogFunc;
	DACALResult	dcresult =	DACALDevicesFinalize();
}

- (void) updateSlotUI:(Boolean)enable {
	NSLogFunc;
	Boolean realEnable = enable;
	NSString *sLabel = @"";
	// If no carousels, disable everything
	if (carouselCount == 0) { 
		[slotLabel setStringValue: sLabel];
		[slotNum setStringValue: sLabel];
		[slotGotoButton	setEnabled:FALSE];
		[slotCloseButton setEnabled:FALSE];
		[createButton setEnabled:FALSE];
		[autoEjectButton setEnabled:FALSE];	
		[slotStepper setEnabled:FALSE];
		realEnable = FALSE;
	} else {
		sLabel = [slotLabel  stringValue];
		if ([sLabel length] == 0) {
			sLabel = @"Slot ";
			NSString *sNum = [slotNum stringValue];
			if ([sNum length] == 0) {
				sNum = @"1";
				[slotNum setStringValue:sNum];
				[slotStepper setIntValue:1];
			}
			sLabel = [sLabel stringByAppendingString: sNum];
			[slotLabel setStringValue: sLabel];
			DACALDeviceRef currentCarousel = [self currentCarousel];
			DACALResult dcResult;
//			CFStringRef dcModel = DACALCommandCopyModel(currentCarousel, &dcResult);
			DACALDeviceRef numSlots = DACALCommandGetSlotCount(currentCarousel);
			[slotStepper setMaxValue:numSlots];
		}
		// if creating a slot with no disc installed, control the carousel title
		if (noDisc == 0) { // normal, see if there is a title in the field
			sLabel = [sourceTitle stringValue];
			if ([sLabel length] == 0) // oops, no title, disable the button
				[createButton setEnabled:FALSE];
			else // looks good, create should work
				[createButton setEnabled:TRUE];
		} else { // trying to create without a disc & a title is defined, so enable the button
			[createButton setEnabled:TRUE];
		}
		// if create button is enable, check the auto eject enable, disable if no disc
		if ([sourceEjectDisc isEnabled])
			[autoEjectButton setEnabled:TRUE];	
		else
			[autoEjectButton setEnabled:FALSE];	
		[slotGotoButton	setEnabled:TRUE];
		[slotCloseButton setEnabled:TRUE];
		[slotStepper setEnabled:TRUE];
	}
}

- (void) updateCarouselUI:(Boolean)enable {
	NSString *cLabel = @"";
	// If no carousels, disable everything
	if (carouselCount == 0) { 
		[carouselLabel setStringValue: cLabel];
		[carouselNum setStringValue: cLabel];
		[carouselResetButton setEnabled:FALSE];
		[carouselStepper setEnabled:FALSE];
		[carouselIDButton setEnabled:FALSE];
		// hide stuuf so notice shows up
		[carouselcon setHidden:TRUE];
		[carouselIconStepper setHidden:TRUE];
		[carouselLabelLabel setHidden:TRUE];
		[carouselStepper setHidden:TRUE];
		[carouselNum setHidden:TRUE];
		[carouselExplainText setHidden:FALSE];
	} else {
		cLabel = [carouselLabel  stringValue];
		if ([cLabel length] == 0) {
			cLabel = @"Carousel ";
			NSString *cNum = [carouselNum stringValue];
			if ([cNum length] == 0) {
				cNum = @"1";
				[carouselNum setStringValue:cNum];
				[carouselStepper setIntValue:1];
			}
			cLabel = [cLabel stringByAppendingString: cNum];
			[carouselLabel setStringValue: cLabel];
		}
		[carouselResetButton setEnabled:TRUE];
		[carouselStepper setEnabled:TRUE];
		[carouselIconStepper setEnabled:TRUE];
		[carouselIDButton setEnabled:TRUE];
		// show stuff 
		[carouselcon setHidden:FALSE];
		[carouselIconStepper setHidden:FALSE];
		[carouselLabelLabel setHidden:FALSE];
		[carouselStepper setHidden:FALSE];
		[carouselNum setHidden:FALSE];
		[carouselExplainText setHidden:TRUE];
	}
	[carouselLabel setEnabled:FALSE];
	if (carouselCount == 1) {
		[carouselNum setEnabled:FALSE];
	} else {
		[carouselNum setEnabled:TRUE];
	}
	[self updateSlotUI:enable];
}

Boolean carouselUIState = FALSE;

- (void) updateSourceUI:(Boolean)enable {
	NSLogFunc;
	if(enable) {
		// update the explanation text to show the user how they can reveal the path component
		[self updateExplainText: sourcePath withTextField: sourceExplainText withText:kFinderTitle];
		NSURL * sourceURL =	[sourcePath URL];
		NSString * sTitle = [sourceURL path];
		NSArray *pathComponents = [sTitle pathComponents];
		NSUInteger pathCount = [pathComponents count];
		sTitle = [pathComponents objectAtIndex:pathCount - 1];
		[sourceTitle setStringValue: sTitle];
	}
	else {
		[sourcePath setURL:nil];
		// make the place holder string
		NSString* myHTMLString = [NSString stringWithString:kExplainTitle];
		NSData* myData = [myHTMLString dataUsingEncoding:NSUTF8StringEncoding];
		NSAttributedString* textToBeInserted = [[[NSAttributedString alloc] initWithHTML:myData documentAttributes:nil] autorelease];
		[[sourcePath cell] setPlaceholderAttributedString: textToBeInserted];
		[self updateExplainText: sourcePath withTextField: sourceExplainText withText:kInsertTitle];
		[sourceTitle setStringValue: @""];
		NSString *cNum = [sourceLevelNum stringValue];
		if ([cNum length] == 0) {
			cNum = @"1";
			[sourceLevelNum setStringValue:cNum];
			[sourceLevelStepper setIntValue:1];
		} else
			[sourceLevelStepper setIntValue:[sourceLevelNum intValue]];
	}
	[sourceLevelNum setEnabled:enable];
	[sourceLevelStepper setEnabled:enable];
	[sourceEjectDisc setEnabled:enable];
	if (noDisc == 1)
		[sourceTitle setEnabled:TRUE];
	else
		[sourceTitle setEnabled:enable];
	[self updateCarouselUI:enable];
	carouselUIState = enable;
}

- (void) deviceAppeared:(NSNotification *) aNotification {
	NSLogFunc;
    DRDevice *newDevice = [aNotification object];
	
    [deviceList addObject:newDevice];
    
    [[DRNotificationCenter currentRunLoopCenter] addObserver:self selector:@selector(deviceStateChanged:) 
														name:DRDeviceStatusChangedNotification object:newDevice];
    
    [self updateSourceUI:TRUE];
}

- (void) deviceDisappeared:(NSNotification *) aNotification {
	NSLogFunc;
    DRDevice *removedDevice = [aNotification object];
	
    [[DRNotificationCenter currentRunLoopCenter] removeObserver:self name:DRDeviceStatusChangedNotification
														 object:removedDevice];
    
    [deviceList removeObject:removedDevice];	
    [self updateSourceUI:FALSE];
}

- (void) deviceStateChanged:(NSNotification *) aNotification {
	NSLogFunc;
    [self updateSourceUI:TRUE];
}

- (void) newMediaDetected:(id)aNotification {
	NSLogFunc;
	NSArray *newMounts = [workSpace mountNewRemovableMedia];
	NSString *lastMount = [newMounts lastObject];	
	NSURL *discURL = [NSURL fileURLWithPath: lastMount];
	[sourcePath setURL: discURL];
	[self updateSourceUI:TRUE];	
	
}

- (IBAction)sourcePathControlDoubleClick:(id)sender {
	NSLogFunc;
    if ([sourcePath clickedPathComponentCell] != nil)
		[[NSWorkspace sharedWorkspace] openURL:[[sourcePath clickedPathComponentCell] URL]];
}

- (IBAction)sourceButtonClicked:(id)sender {
	NSLogFunc;
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	[panel setResolvesAliases:YES];
	[panel setTitle:@"Choose a folder object"];
	[panel setPrompt:@"Choose"];
	
	[panel beginSheetForDirectory:nil file:nil types:nil modalForWindow: appWindow
					modalDelegate:self
				   didEndSelector:@selector(openSourcePanelDidEnd:returnCode:contextInfo:)
					  contextInfo:self];
    
}

// -------------------------------------------------------------------------------
//	updateExplainText:
//
//	This get called whenever we need to update the explanation string that instructs
//	the user how they can reveal the path component (via the Finder or Safari).
// -------------------------------------------------------------------------------
-(void)updateExplainText:(NSPathControl *)pathControl withTextField:(NSTextField *)textField  withText:(NSString *)text {	
	NSLogFunc;
	NSUInteger numItems = [[pathControl pathComponentCells] count];
	
	// if the control has a path (more then 0 components), output the explanatory text
	if (numItems > 0)
	{
		[textField setHidden: NO];
		
		if ([pathControl pathStyle] == NSPathStyleStandard || [pathControl pathStyle] == NSPathStyleNavigationBar) {
			[textField setStringValue:text];
		} else {
			// all other path styles have no explanatory text
			[textField setStringValue:@""];
		}
	}
	else
	{
		// no path components, don't use explanatory text
		[textField setHidden:YES];
	}
	
	[textField setNeedsDisplay: YES];
}

// -------------------------------------------------------------------------------
//	openPanelDidEnd:returnCode:contextInfo:
//
//	Called when the NSOpenPanel (via "Set Path..." button) completes.
// -------------------------------------------------------------------------------
- (void)openSourcePanelDidEnd:(NSOpenPanel*)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	NSLogFunc;
	// hide the open panel
	[panel orderOut:self];
	
	// if the return code wasn't ok, don't do anything.
	if (returnCode != NSOKButton)
		return;
	
	// get the first URL returned from the Open Panel and set it at the first path component of the control
	NSArray* paths = [panel URLs];
	NSURL* url = [paths objectAtIndex: 0];
	[sourcePath setURL: url];
	[self updateSourceUI:TRUE];
}

// -------------------------------------------------------------------------------
//	validateDrop:pinfo
//
//	This method is called when something is dragged over the control.
//	Return NSDragOperationNone to refuse the drop, or anything else to accept it.
// -------------------------------------------------------------------------------
- (NSDragOperation)pathControl:(NSPathControl*)pathControl validateDrop:(id <NSDraggingInfo>)info {
	return NSDragOperationCopy;
}

// -------------------------------------------------------------------------------
//	shouldDragPathComponentCell:pathComponentCell:pasteboard
//
//	This method is called when a drag is about to begin.
//	Is shows how to customize dragging by preventing "volumes" from being dragged.
// -------------------------------------------------------------------------------
- (BOOL)pathControl:(NSPathControl*)pathControl shouldDragPathComponentCell:(NSPathComponentCell*)pathComponentCell withPasteboard:(NSPasteboard*)pasteboard {
	NSLogFunc;
	BOOL result = YES;
	
	NSURL* url = [pathComponentCell URL];
	if (url && ! [url isFileURL])
	{
		NSArray* pathPieces = [[url path] pathComponents];
		if ([pathPieces count] < 4)
			result = NO;	// don't allow dragging volumes
	}
	
	return result;
}

// -------------------------------------------------------------------------------
//	acceptDrop:info
//
//	In order to accept the dropped contents previously accepted from
//	validateDrop:, you must implement this method.  We get the new URL from the
//	pasteboardand set it to the path control, and update the explanatory text if needed. 
// -------------------------------------------------------------------------------
-(BOOL)pathControl:(NSPathControl*)pathControl acceptDrop:(id <NSDraggingInfo>)info {
	NSLogFunc;
	BOOL result = NO;
	
	NSURL* url = [NSURL URLFromPasteboard:[info draggingPasteboard]];
	Boolean isDirectory = CFURLHasDirectoryPath((CFURLRef) url);
	if (isDirectory) {
		[sourcePath setURL: url];
		[self updateExplainText: sourcePath withTextField: sourceExplainText withText:kFinderTitle];	// the user how they can reveal the path component
		result = YES;
	} else {
		NSBeep();
		result = NO;
	}
	return result;
}

// Disc to scan
- (IBAction)scanButtonClicked:(id)sender{
	NSLogFunc;
}

- (IBAction)ejectDiscButtonClicked:(id)sender {
	NSLogFunc;
	NSURL* url = [sourcePath URL];
	[workSpace unmountAndEjectDeviceAtPath: [url path]];
	[self updateSourceUI:FALSE];
	
}
//- (IBAction)sourceButtonClicked:(id)sender {
//		NSURL * sourceURL = NULL;
//		
//		sourceURL = [sourcePath URL];
//		[sourceScanButton setEnabled:TRUE];
//	}	
- (IBAction)scanLevelStepperClicked:(id)sender {
	NSLogFunc;
	int value = [sourceLevelStepper intValue];
	[sourceLevelNum setIntValue:value];
}
// Carousel
- (IBAction)carouselStepperClicked:(id)sender{
	NSLogFunc;
	[carouselNum setIntValue:[carouselStepper intValue]];
}

- (IBAction)carouselResetButtonClicked:(id)sender{
	NSLogFunc;
	DACALDeviceRef deviceId = [self currentCarousel];
	DACALResult dcResult = DACALCommandReset(deviceId);
}

// Slot
- (IBAction)slotStepperClicked:(id)sender{
	[slotNum setIntValue:[slotStepper intValue]];
	NSLogFunc;
}

- (IBAction)slotGotoSlotButtonClicked:(id)sender {
	NSLogFunc;
	int cNum = [carouselNum intValue];
	int sNum = [slotNum intValue];
	[slotStepper setIntValue:sNum];
	DACALDevicesSetDefaultDevice((DACALDeviceRef)cNum);
	DACALResult result = DACALCommandMoveToSlot((DACALDeviceRef)cNum, (DACALDeviceRef)sNum);	
	// !!!:davec:20080531 Need alert here if bad result
}

- (IBAction)slotCloseButtonClicked:(id)sender{
	NSLogFunc;
	int cNum = [carouselNum intValue];
	int sNum = [slotNum intValue];
	DACALDevicesSetDefaultDevice((DACALDeviceRef)cNum);
	DACALCommandCloseDoor((DACALDeviceRef)cNum);	
}

Boolean ledState = FALSE;

- (void) flashLED {
	if (ledState)
		ledState = FALSE;
	else
		ledState = TRUE;
	DACALCommandSetLED(kDACALDefaultDevice, ledState);
}


//NSTimer * idTimer = NULL;
//
- (IBAction)carouselIdButtonClicked:(id)sender{
	NSLogFunc;
//	int cNum = [carouselNum intValue];
//	int sNum = [slotNum intValue];
//	DACALDevicesSetDefaultDevice((DACALDeviceRef)cNum);
//	SEL idTimerSEL;
//	NSArray * idTimerArgs;
//	NSMethodSignature *aSignature;
//	NSInvocation * anInvocation;
//	idTimerSEL = @selector(flashLED);
//	aSignature = [self instanceMethodSignatureForSelector:idTimerSEL];
//	anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
//	[anInvocation setSelector:idTimerSEL];
//	[anInvocation setTarget:self];
//	
//	[anInvocation invoke];
//	[NSTimer scheduledTimerWithInterval:600
//							 invocation:anInvocation
//								repeats:YES];
//	[anInvocation invocationWithMethodSignature: aSignature];
//	if (idTimer == NULL) {
//		NSTimer * idTimer = [idTimer timerWithTimeInterval: 2 invocation: anInvocation repeats: TRUE];
//	}
}

- (IBAction)createButtonClicked:(id)sender{
	NSLogFunc;

	NSString *sTitle = [sourceTitle stringValue];
	NSURL *sourceURL =	[sourcePath URL];
	NSString *sVolume = [sourceURL path];
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *cmdURL = [mainBundle pathForResource:@"carousel" ofType:@"sh"];
	NSString *cNum = [carouselNum stringValue];
	NSString *sNum = [slotNum stringValue];
	NSString *lNum = [sourceLevelNum stringValue];
	NSString *dCmd = [NSString stringWithFormat:@"\"%@\" -x -c %@ -s %@ -t \"%@\" -l %@", cmdURL, cNum, sNum, sTitle, lNum];
	if (noDisc != 0)
		dCmd = [dCmd stringByAppendingString:@" -n"];
	else	
		dCmd = [dCmd stringByAppendingFormat:@" -d \"%@\"", sVolume];
	const char * dacalcmd = [dCmd cStringUsingEncoding:NSASCIIStringEncoding];
	[createProgress setHidden:FALSE];
	[createProgress startAnimation:self];
	int result = system(dacalcmd);
	// !!!:davec:20080531 Need alert here if bad result
	if (result == 0) { 
		[self slotGotoSlotButtonClicked:sender];
		// if auto ejecting, bump slot number
		if (autoEject == 1) {
			[slotNum setIntValue:[slotNum intValue] + 1];
			[slotStepper setIntValue:[slotNum intValue]];
		}
		// make sure there is a disc defined
		if (sourceURL != NULL)
			[self ejectDiscButtonClicked:sender];
	}
	[createProgress setHidden:TRUE];
	[createProgress stopAnimation:self];	
}

//
//- (IBAction)moveToSlotButtonClicked:(id)sender {
//	NSLogFunc;
//}
//
//- (void)textDidEndEditing:(NSNotification *)aNotification {
//	NSLogFunc;
//	int sNum = [slotNum intValue];
//	[slotStepper setIntValue:sNum];
//}

- (IBAction) autoEjectClicked:(id)sender {
	NSLogFunc;
	autoEject = [autoEjectButton intValue];
}

- (IBAction) noDiscClicked:(id)sender {
	NSLogFunc;
	noDisc = (NSInteger)[noDiscButton intValue];
	[self updateSourceUI:carouselUIState];
}

- (IBAction) carouselIconStepperClicked:(id)sender { 
	NSLogFunc;
}


@synthesize _title;
@synthesize _slotNum;

@end





