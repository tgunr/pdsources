#import "StorageWindowController.h"

@implementation StorageWindowController
// explanation string to instruct the user what double-click operation on a path component does:
NSString *const kFinderTitle = @"Double-click a path component to reveal it in the Finder.";
NSString *const kBatchTitle = @"Insert media into drive for processing"; 

// explanation/place holder string to instruct the user on how they can set the path
NSString *const kExplainTitle = @"<html><center>Drag a folder to this area or click the button above'</center></html>";

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
-(void)dealloc
{
	[super dealloc];
}

- (void) setDelegate:(id)sender {
	appDelegate = sender;
}

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	myApp = [NSApplication sharedApplication];
	
	[sourcePath setPathStyle: NSPathStyleStandard];
	[storePath setPathStyle: NSPathStyleStandard];
	
	// make the place holder string
	NSString* myHTMLString = [NSString stringWithString:kExplainTitle];
	NSData* myData = [myHTMLString dataUsingEncoding:NSUTF8StringEncoding];
	NSAttributedString* textToBeInserted = [[[NSAttributedString alloc] initWithHTML:myData documentAttributes:nil] autorelease];
	[[sourcePath cell] setPlaceholderAttributedString: textToBeInserted];
	[[storePath cell] setPlaceholderAttributedString: textToBeInserted];
	
    [sourcePath setTarget:self];
    [storePath setTarget:self];
	
    [sourcePath setDoubleAction:@selector(sourcePathControlDoubleClick:)];
	[sourcePath setDelegate:self];
	
    [storePath setDoubleAction:@selector(storePathControlDoubleClick:)];
	[storePath setDelegate:self];
	
	[sourceExplainText setHidden: YES];
	[storeExplainText setHidden: YES];
	
	[carouselButton setEnabled:FALSE];
}


- (IBAction)getSource:(id)sender {
}

- (IBAction)sourcePathClicked:(id)sender {
}

- (IBAction)storePathClicked:(id)sender {
}

- (IBAction)sourcePathControlDoubleClick:(id)sender {
    if ([sourcePath clickedPathComponentCell] != nil)
		[[NSWorkspace sharedWorkspace] openURL:[[sourcePath clickedPathComponentCell] URL]];
}

- (IBAction)storePathControlDoubleClick:(id)sender {
    if ([storePath clickedPathComponentCell] != nil)
		[[NSWorkspace sharedWorkspace] openURL:[[storePath clickedPathComponentCell] URL]];
}

- (IBAction)carouselButtonClicked:(id)sender {
	NSLog(@"Processsing");
}

- (void)enableProcessButton {
	NSURL * sourceURL = NULL;
	NSURL * storeURL = NULL;
	
	sourceURL = [sourcePath URL];
	storeURL = [storePath URL];
	
	[carouselButton setEnabled:TRUE];
}

- (IBAction)storeButtonClicked:(id)sender {
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	[panel setResolvesAliases:YES];
	[panel setTitle:@"Choose a folder object"];
	[panel setPrompt:@"Choose"];
	
	[panel beginSheetForDirectory:nil file:nil types:nil modalForWindow: [self window]	
					modalDelegate:self
				   didEndSelector:@selector(openStorePanelDidEnd:returnCode:contextInfo:)
					  contextInfo:self];
}

- (IBAction)sourceButtonClicked:(id)sender {
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	[panel setResolvesAliases:YES];
	[panel setTitle:@"Choose a folder object"];
	[panel setPrompt:@"Choose"];
	
	[panel beginSheetForDirectory:nil file:nil types:nil modalForWindow: [self window]	
					modalDelegate:self
				   didEndSelector:@selector(openSourcePanelDidEnd:returnCode:contextInfo:)
					  contextInfo:self];
    
}

- (IBAction)batchModeButtonClicked:(id)sender {
	[self updateExplainText: storePath withTextField: storeExplainText withText:kBatchTitle];	// update the explanation text to show the user how they can reveal the path component
}

// -------------------------------------------------------------------------------
//	openPanelDidEnd:returnCode:contextInfo:
//
//	Called when the NSOpenPanel (via "Set Path..." button) completes.
// -------------------------------------------------------------------------------
- (void)openSourcePanelDidEnd:(NSOpenPanel*)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	// hide the open panel
	[panel orderOut:self];
	
	// if the return code wasn't ok, don't do anything.
	if (returnCode != NSOKButton)
		return;
	
	// get the first URL returned from the Open Panel and set it at the first path component of the control
	NSArray* paths = [panel URLs];
	NSURL* url = [paths objectAtIndex: 0];
	[sourcePath setURL: url];
	
	[self updateExplainText: sourcePath withTextField: sourceExplainText withText:kFinderTitle];	// update the explanation text to show the user how they can reveal the path component
//    [self enableProcessButton];
}

- (void)openStorePanelDidEnd:(NSOpenPanel*)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	// hide the open panel
	[panel orderOut:self];
	
	// if the return code wasn't ok, don't do anything.
	if (returnCode != NSOKButton)
		return;
	
	// get the first URL returned from the Open Panel and set it at the first path component of the control
	NSArray* paths = [panel URLs];
	NSURL* url = [paths objectAtIndex: 0];
	[storePath setURL: url];
	
	[self updateExplainText: storePath withTextField: storeExplainText withText:kFinderTitle];	// update the explanation text to show the user how they can reveal the path component
//    [self enableProcessButton];
//	[appDelegate mountLoopbackFS];
	
}

// -------------------------------------------------------------------------------
//	validateDrop:pinfo
//
//	This method is called when something is dragged over the control.
//	Return NSDragOperationNone to refuse the drop, or anything else to accept it.
// -------------------------------------------------------------------------------
- (NSDragOperation)pathControl:(NSPathControl*)pathControl validateDrop:(id <NSDraggingInfo>)info
{
	return NSDragOperationCopy;
}

// -------------------------------------------------------------------------------
//	acceptDrop:info
//
//	In order to accept the dropped contents previously accepted from
//	validateDrop:, you must implement this method.  We get the new URL from the
//	pasteboardand set it to the path control, and update the explanatory text if needed. 
// -------------------------------------------------------------------------------
-(BOOL)pathControl:(NSPathControl*)pathControl acceptDrop:(id <NSDraggingInfo>)info
{
	BOOL result = NO;
	
	NSURL* url = [NSURL URLFromPasteboard:[info draggingPasteboard]];
	Boolean isDirectory = CFURLHasDirectoryPath((CFURLRef) url);
	if (isDirectory) {
		[storePath setURL: url];
		[self updateExplainText: storePath withTextField: storeExplainText withText:kFinderTitle];	// the user how they can reveal the path component
		result = YES;
	} else {
		NSBeep();
		result = NO;
	}
	return result;
}

// -------------------------------------------------------------------------------
//	shouldDragPathComponentCell:pathComponentCell:pasteboard
//
//	This method is called when a drag is about to begin.
//	Is shows how to customize dragging by preventing "volumes" from being dragged.
// -------------------------------------------------------------------------------
- (BOOL)pathControl:(NSPathControl*)pathControl shouldDragPathComponentCell:(NSPathComponentCell*)pathComponentCell withPasteboard:(NSPasteboard*)pasteboard
{
	BOOL result = YES;
	
	NSURL* url = [pathComponentCell URL];
	if (url && [url isFileURL])
	{
		NSArray* pathPieces = [[url path] pathComponents];
		if ([pathPieces count] < 4)
			result = NO;	// don't allow dragging volumes
	}
	
	return result;
}

// -------------------------------------------------------------------------------
//	updateExplainText:
//
//	This get called whenever we need to update the explanation string that instructs
//	the user how they can reveal the path component (via the Finder or Safari).
// -------------------------------------------------------------------------------
-(void)updateExplainText:(NSPathControl *)pathControl withTextField:(NSTextField *)textField  withText:(NSString *)text
{	
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


@end
