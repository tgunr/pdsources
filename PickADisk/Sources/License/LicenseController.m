//
//  LicenseController.m
//  PickADisk
//
//  Created by Dave Carlton on 09/30/08.
//  Copyright 2008 Polymicro Systems. All rights reserved.
//

#import "PADPrefsController.h"
#import "LicenseController.h"

@implementation LicenseController
static LicenseController*	shared_LicenseController = nil;
static BOOL	shared_LicenseControllerB = false;

+ (id)shared {
    if (!shared_LicenseController)
        [[LicenseController alloc] init];
    return shared_LicenseController;
}


-(id)init {
	if (shared_LicenseController)
		return (id)shared_LicenseController;
	
	if( self = [super init] ) {
		NSLog(@"LicenseController Created");
		shared_LicenseController = (LicenseController*)self;
	}
	
	return self;
}

- (void)awakeFromNib {	
    [licensePathControl setTarget:self];
    [licensePathControl setDoubleAction:@selector(pathControlDoubleClick:)];
	[licensePathControl setDelegate:self];
}

- (void) updateLicensePanel {
	BOOL *valid = [[License shared] licenseValid];
	if (valid) {
		[licenseeField setStringValue: [[[License shared] licenseDict] objectForKey: @"Name"]];
		[licenseMailField setStringValue: [[[License shared] licenseDict] objectForKey: @"Email"]];
	} else {
		[licenseeField setStringValue: @""];
		[licenseMailField setStringValue: @""];
	}
}

// -------------------------------------------------------------------------------
//	pathControlDoubleClick:sender:
//
//  This method is the "double-click" action for the control.
//	Since we are a standard or navigation style we ask for the control's path component.
// -------------------------------------------------------------------------------
- (void)pathControlDoubleClick:(id)sender
{
    if ([licensePathControl clickedPathComponentCell] != nil)
		[[NSWorkspace sharedWorkspace] openURL:[[licensePathControl clickedPathComponentCell] URL]];
}

// -------------------------------------------------------------------------------
//	willDisplayOpenPanel:openPanel:
//
//	Delegate method to NSPathControl to determine how the NSOpenPanel will look/behave.
// -------------------------------------------------------------------------------
- (void)pathControl:(NSPathControl*)pathControl willDisplayOpenPanel:(NSOpenPanel*)openPanel
{	
	// change the wind title and choose buttons titles
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:YES];
	[openPanel setResolvesAliases:YES];
	[openPanel setTitle:@"Choose a license file"];
	[openPanel setPrompt:@"Choose"];
}

// -------------------------------------------------------------------------------
//	willPopUpMenu:menu:
//
//	Delegate method on NSPathControl (as NSPathStylePopUp) that determines what popup menus 
//	will look like.  In our case we add "Reveal in Finder".
// -------------------------------------------------------------------------------
- (void)pathControl:(NSPathControl*)pathControl willPopUpMenu:(NSMenu*)menu
{
	if (true)
	{
		// add the "Reveal in Finder" menu item (but only for file system paths, not our custom path);
		NSMenuItem* newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Reveal in Finder" action:@selector(menuItemAction:) keyEquivalent:@""];
		[newItem setTarget:self];
		
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItem:newItem];
		[newItem release];
	}
	else
	{
		// remove the "Choose..." and separator menu items since we have a custom path
		[menu removeItemAtIndex:0];
		[menu removeItemAtIndex:0];
	}
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
//	pasteboardand set it to the path control
// -------------------------------------------------------------------------------
-(BOOL)pathControl:(NSPathControl*)pathControl acceptDrop:(id <NSDraggingInfo>)info
{
	BOOL result = NO;
	
	NSURL* url = [NSURL URLFromPasteboard:[info draggingPasteboard]];
	if (url != nil)
	{
		[licensePathControl setURL: url];
		result = YES;
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
//	getPath:sender:
//
//	User clicked "Set Path..." button to pick a file system object.
// -------------------------------------------------------------------------------
- (IBAction)selectLicenseFileBtn:(id)sender
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:YES];
	[panel setResolvesAliases:YES];
	[panel setTitle:@"Choose a file object"];
	[panel setPrompt:@"Choose"];
	
	NSArray * licenseFiles;
	NSURL * url;
	NSArray *fileTypes = [NSArray arrayWithObject:@"padlicense"];
	NSInteger result = [panel runModalForTypes:fileTypes];
	if (result) {
		licenseFiles = [panel filenames];
		url = [NSURL fileURLWithPath: [licenseFiles objectAtIndex: 0]];
		[licensePathControl setURL: url];
		License *validator =  [License shared];
		NSDictionary *licenseDict = [validator checkLicenseFile: [url path]];
		if (licenseDict) {
			NSString *licenseName = [licenseDict objectForKey:@"Name"];
			[licenseeField setStringValue: licenseName];
			NSString *licenseEmail = [licenseDict objectForKey:@"Email"];
			[licenseMailField setStringValue: licenseEmail];
			NSData * licenseData = [NSData dataWithContentsOfFile:[url path]];
			NSString * licenseSignature = [licenseDict objectForKey: @"Signature"];
			const void * data = [licenseData bytes];
			[[NSUserDefaults standardUserDefaults] setObject: licenseData forKey:@"licenseDict"];
			[validator setLicenseData: licenseData];
			[self updateLicensePanel];
		}
	}
	
	//	[panel beginSheetForDirectory:nil file:nil types:nil modalForWindow:[self window]
	//					modalDelegate:self
	//				   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
	//					  contextInfo:self];
}

// -------------------------------------------------------------------------------
//	openPanelDidEnd:returnCode:contextInfo:
//
//	Called when the NSOpenPanel (via "Set Path..." button) completes.
// -------------------------------------------------------------------------------
- (void)openPanelDidEnd:(NSOpenPanel*)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	// hide the open panel
	[panel orderOut:self];
	
	// if the return code wasn't ok, don't do anything.
	if (returnCode != NSOKButton)
		return;
	
	// get the first URL returned from the Open Panel and set it at the first path component of the control
	NSArray* paths = [panel URLs];
	NSURL* url = [paths objectAtIndex: 0];
	[licensePathControl setURL: url];
}

- (IBAction)submitLicense:(id)sender {
}

- (IBAction)lostLicenseBtn:(id)sender {
}

- (IBAction)submitRequestBtn:(id)sender {
}

- (IBAction)visitLicenseBtn:(id)sender {
}

- (IBAction)cancelLicenseBtn:(id)sender {
}

- (IBAction)enterLicenseBtn:(id)sender {
}

- (IBAction)requestLicenseBtn:(id)sender {
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
    }
}

- (void)showNotLicensed {
	return;
//	[notLicensedWindow makeKeyAndOrderFront: self];
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"View Site"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert addButtonWithTitle:@"Enter License"];
	[alert setMessageText:@"PickADisk Not Licensed"];
	[alert setInformativeText:@"You may use PickADisk without a license but are limited to 50 disks. To purchase a license for PickADisk, click the Visit Site button where you may make a purchase.erscore "];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:[[[[AppController shared] dataView] outlineView] window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];

}

@end

@implementation License

static License*	shared_License = nil;
static BOOL	shared_LicenseB = false;
static BOOL *PADCS[5];

+ (id)shared {
    if (!shared_License)
        [[License alloc] init];
    return shared_License;
}


-(id)init {
	if (shared_License)
		return (id)shared_License;
	
	if( self = [super init] ) {
		NSLog(@"License Created");
		shared_License = (License*)self;
	}
	
	// This string is specially constructed to prevent key replacement 	
	// *** Begin Public Key ***
	licenseKey = [NSMutableString string];
	[licenseKey appendString:@"0x9F7B984C1758F45A31E162D27B76"];
	[licenseKey appendString:@"A2460DE570C1F2C6C51080707FC5C5"];
	[licenseKey appendString:@"2D480EDCF54F57B54BA5"];
	[licenseKey appendString:@"7"];
	[licenseKey appendString:@"7"];
	[licenseKey appendString:@"A28908DD"];
	[licenseKey appendString:@"ABE26C974C2436053483"];
	[licenseKey appendString:@"6"];
	[licenseKey appendString:@"6"];
	[licenseKey appendString:@"C649C455"];
	[licenseKey appendString:@"D10B4EB382C36763A60F8C"];
	[licenseKey appendString:@"E"];
	[licenseKey appendString:@"E"];
	[licenseKey appendString:@"C24AE5"];
	[licenseKey appendString:@"4035C4CEA0108B31"];
	[licenseKey appendString:@"D"];
	[licenseKey appendString:@"D"];
	[licenseKey appendString:@"1D9915450B96"];
	[licenseKey appendString:@"7B510B07379"];
	[licenseKey appendString:@"33"];
	[licenseKey appendString:@"CA428780D997E6DB3"];
	[licenseKey appendString:@"94238E65A53919B127A76B9FEB6184"];
	[licenseKey appendString:@"11A5B211A3FA6B87"];
	// Last byte of public key in in AquaticPrime.m -setKey
	// *** End Public Key *** 
	
	PADCS[0] = &shared_LicenseB;
	PADCS[1] = &shared_LicenseControllerB;
	PADCS[2] = &shared_LicenseB;
	PADCS[3] = &shared_LicenseControllerB;
	PADCS[4] = (BOOL *)1;
	
	// Instantiate AquaticPrime
	[self setLicenseValidator: [AquaticPrime aquaticPrimeWithKey:licenseKey]];
	
	// Blacklist bad licenses
	[licenseValidator setBlacklist:[NSArray arrayWithObject:@"56237cb06e032ba9d7ed5c4b5f5f89790493386e"]];
	// init from prefs if possible
	licenseData  = [[NSUserDefaults standardUserDefaults] objectForKey:@"licenseDict"];
	NSUInteger len = [licenseData length];
	const void * data = [licenseData bytes];
	licenseDict = [licenseValidator dictionaryForLicenseData: licenseData];
	
	if (!licenseDict)
		return self;
	return self;
}

- (AquaticPrime *)licenseValidator { return licenseValidator; }
- (NSDictionary *)licenseDict { return licenseDict; }

- (void)setLicenseValidator:(AquaticPrime *)newValidator {
	if( !licenseValidator || licenseValidator != newValidator ) {
		if( licenseValidator ) 
			[licenseValidator release];
		if( newValidator ) 
			[newValidator retain];
		licenseValidator = newValidator;
	}
}

- (void)setLicenseData:(NSData *)data {
	licenseData = data; 
}

static BOOL isValid = false;

- (BOOL*) licenseValid {
//	[self limit];
	isValid = false;
	*PADCS[(int)PADCS[4]] = false;
	long r = random();
	r = r % 4;
	PADCS[4]= (BOOL *)r;
	if (licenseDict)
		if( [licenseValidator verifyLicenseData: licenseData] ) {
			*PADCS[r] = true;
			return PADCS[r];
		}
	else
		return &isValid;
}

- (NSDictionary*)checkLicenseFile:(NSString*)licensePath {
    // Get the dictionary from the license file
    // If the license is invalid, we get nil back instead of a dictionary
    licenseDict = [licenseValidator dictionaryForLicenseFile:licensePath];
	return licenseDict;
}

- (BOOL)checkLicenseData:(NSData*)data {
    // Get the dictionary from the license file
    // If the license is invalid, we get nil back instead of a dictionary
    return [licenseValidator verifyLicenseData:data];
}

- (BOOL) openLicenseFile:(NSString*)licensePath {
	NSDictionary *theDict = [self checkLicenseFile: licensePath];
	if (!theDict)
		return true;
	return false;
}

- (int)limit {
	NSString * pkey = [licenseValidator key];
	NSUInteger index = [pkey lengthOfBytesUsingEncoding: NSASCIIStringEncoding];
	NSString * string = [NSString string];
	unichar l =	[pkey characterAtIndex: 254] << 8;
}

// Check the boolean pointers, only 1 can be on
- (BOOL *)checkV {
	int i, n;
	isValid = false;
	for(i=0; i<4; i++)
		isValid += *PADCS[i];
	isValid = isValid < 2;
	return &isValid;
}

- (BOOL)registerLicenseFromFile:(NSString*)licensePath {
}

@end



