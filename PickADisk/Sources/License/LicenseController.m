//
//  LicenseController.m
//  PickADisk
//
//  Created by Dave Carlton on 09/30/08.
//  Copyright 2008 Polymicro Systems. All rights reserved.
//

#import "LicenseController.h"
#import "LicenseService.h"
#import "DACALTreeDataSource.h"

//	License Controller State values

NSString*		kPADLicenseStateLaunching		= @"Init";
NSString*		kPADLicenseStateFirstAnnounce	= @"DemoAnnounce";
NSString*		kPADLicenseStateRunningDemo		= @"Demo";
NSString*		kPADLicenseStateEnterLicense	= @"DemoLicense";
NSString*		kPADLicenseStateRequestLicense	= @"RequestLicense";
NSString*		kPADLicenseStateShowLicense		= @"ShowLicense";


@implementation LicenseController
static LicenseController*	shared_LicenseController = nil;
//static BOOL	shared_LicenseControllerB = false;

- (void)dealloc
{
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.licenseDict"];
	
	[super dealloc];
}

+ (id)sharedLicenseController
{
    if (!shared_LicenseController)
        [[LicenseController alloc] init];
    return shared_LicenseController;
}


-(id)init {
	if (shared_LicenseController)
		return (id)shared_LicenseController;
	
	if( (self = [super init]) ) {
		//NSLog(@"LicenseController Created");
		shared_LicenseController = (LicenseController*)self;
		controllerState = kPADLicenseStateLaunching;
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.licenseDict" options:0 context:NULL];

	}
	
	return self;
}

- (void)awakeFromNib {	
    [licensePathControl setTarget:self];
    [licensePathControl setDoubleAction:@selector(pathControlDoubleClick:)];
	[licensePathControl setDelegate:self];

    if (![[PADLicenseService sharedLicenseService] licenseValid]) {
        BOOL haveFirstRun = [[NSUserDefaults standardUserDefaults] boolForKey:kPADLicenseFirstRunPrefKey];

        if (!haveFirstRun) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPADLicenseFirstRunPrefKey];
            //[self runNotLicensedModalWindow];
            [self performSelectorOnMainThread:@selector(runNotLicensedModalWindow) withObject:nil waitUntilDone:NO];
        }

    }
}

- (void)closeNotLicensedWindow
{
	[notLicensedWindow close];
	[NSApp stopModal]; 
}

- (void)closeStateWindow
{
	if( controllerState ) {
		if( [controllerState isEqual:kPADLicenseStateFirstAnnounce] )
			[self closeNotLicensedWindow];
        else if( [controllerState isEqual:kPADLicenseStateEnterLicense] )
            [enterLicenseWindow performClose:self];
        else if( [controllerState isEqual:kPADLicenseStateRequestLicense] )
            [requestLicenseWindow performClose:self];
        else if( [controllerState isEqual:kPADLicenseStateShowLicense] )
            [licenseWindow performClose:self];
    }

	// Note this leaves the state unchanged so the caller is responsible for updating it
}

- (void)runNotLicensedModalWindow
{
	NSModalSession	demoSession;

	controllerState = kPADLicenseStateFirstAnnounce;
	if( (demoSession = [[NSApplication sharedApplication] beginModalSessionForWindow:notLicensedWindow]) )
	{
		while ([NSApp runModalSession:demoSession] == NSRunContinuesResponse) {
			;
			// Tight loop
		}
		[[NSApplication sharedApplication] endModalSession:demoSession];
	}
}

- (void)runChooseLicenseWindow
{
	controllerState = kPADLicenseStateEnterLicense;
	[enterLicenseWindow makeKeyAndOrderFront:self];
}

- (void)runRequestLicenseWindow
{
	controllerState = kPADLicenseStateRequestLicense;

	NSString*	userName = [[PADLicenseService sharedLicenseService] stringForLicenseKey:kPADLicenseDictKeyUserName];
	NSString*	userMail = [[PADLicenseService sharedLicenseService] stringForLicenseKey:kPADLicenseDictKeyUserEmail];
	NSString*	invoiceN = [[PADLicenseService sharedLicenseService] stringForLicenseKey:kPADLicenseDictKeyInvoiceNum];

	if( userName )
		[licenseeField setStringValue:userName];
	if( userMail )
		[licenseMailField setStringValue:userMail];
	if( invoiceN )
		[licenseInvoiceCode setStringValue:invoiceN];
	
	[requestLicenseWindow makeKeyAndOrderFront:self];
}

- (void)runHaveLicenseWindow
{
	controllerState = kPADLicenseStateShowLicense;

	NSString*	userName = [[PADLicenseService sharedLicenseService] stringForLicenseKey:kPADLicenseDictKeyUserName];
	NSString*	userMail = [[PADLicenseService sharedLicenseService] stringForLicenseKey:kPADLicenseDictKeyUserEmail];
	NSString*	userNote = [[PADLicenseService sharedLicenseService] stringForLicenseKey:kPADLicenseDictKeyComment];
	
	if( userNote == nil )
		userNote = @"";
	
	[validUserName setStringValue:userName];
	[validUserMail setStringValue:userMail];
	[validUserMessage setStringValue:userNote];
	
	[licenseWindow center];
	[licenseWindow makeKeyAndOrderFront:self];
}

- (IBAction)chooseAppLicensedMenu:(id)sender
{
	if( [[PADLicenseService sharedLicenseService] licenseValid] )
		[self runHaveLicenseWindow];
	else
		[self runChooseLicenseWindow];
}

- (IBAction)chooseRequestLicenseMenu:(id)sender
{
	[self closeStateWindow];
	[self runRequestLicenseWindow];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == [NSUserDefaultsController sharedUserDefaultsController] )
	{
		if( [keyPath hasSuffix:kPADLicenseDataPrefKey] )
		{
			[self closeStateWindow];
			
			if( [[PADLicenseService sharedLicenseService] licenseValid] )
			{
				[self runHaveLicenseWindow];
				[[DACALTreeDataSource shared] updatePrompt];
			}
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

/*

- (void)didEndLicensedSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

- (IBAction)closeLicensedSheet: (id)sender {
    [NSApp endSheet:licenseWindow];
	[NSApp stopModal];
}
*/

// -------------------------------------------------------------------------------
//	pathControlDoubleClick:sender:
//
//  This method is the "double-click" action for the control.
//	Since we are a standard or navigation style we ask for the control's path component.
// -------------------------------------------------------------------------------
- (void)pathControlDoubleClick:(id)sender {
    if ([licensePathControl clickedPathComponentCell] != nil)
		[[NSWorkspace sharedWorkspace] openURL:[[licensePathControl clickedPathComponentCell] URL]];
}

// -------------------------------------------------------------------------------
//	willDisplayOpenPanel:openPanel:
//
//	Delegate method to NSPathControl to determine how the NSOpenPanel will look/behave.
// -------------------------------------------------------------------------------
- (void)pathControl:(NSPathControl*)pathControl willDisplayOpenPanel:(NSOpenPanel*)openPanel {	
	// change the wind title and choose buttons titles
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setResolvesAliases:YES];
	[openPanel setTitle:@"Choose PickADisk License"];
	[openPanel setMessage:@"Please locate your PickADisk license document."];
	[openPanel setPrompt:@"Register"];
}

// -------------------------------------------------------------------------------
//	willPopUpMenu:menu:
//
//	Delegate method on NSPathControl (as NSPathStylePopUp) that determines what popup menus 
//	will look like.  In our case we add "Reveal in Finder".
// -------------------------------------------------------------------------------
- (void)pathControl:(NSPathControl*)pathControl willPopUpMenu:(NSMenu*)menu {
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
	NSDragOperation		doOp = NSDragOperationNone;
	NSURL*				url = [NSURL URLFromPasteboard:[info draggingPasteboard]];
	NSString*			licenseUTI = @"com.polymicrosystems.pickadisk.documents.license";

	if( url != nil )
		if( CFURLConfromsToUTIs( kCFAllocatorDefault, (CFURLRef)url, (CFArrayRef)[NSArray arrayWithObject:licenseUTI], NULL ) )
			doOp = NSDragOperationCopy;
	
	return doOp;
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
		result = [[PADLicenseService sharedLicenseService] registerLicenseFromFileURL:url];
		if( result )
			[licensePathControl setURL: url];
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
	[panel setCanChooseDirectories:NO];
	[panel setCanChooseFiles:YES];
	[panel setResolvesAliases:YES];
	[panel setTitle:@"Choose PickADisk License"];
	[panel setMessage:@"Please locate your PickADisk license document."];
	[panel setPrompt:@"Register"];
	
	NSArray * licenseFiles;
	NSURL * url;
	NSArray *fileTypes = [NSArray arrayWithObject:@"padlicense"];
	NSInteger result = [panel runModalForTypes:fileTypes];
	if (result) {
		licenseFiles = [panel filenames];
		url = [NSURL fileURLWithPath: [licenseFiles objectAtIndex: 0]];
		[licensePathControl setURL: url];
		[[PADLicenseService sharedLicenseService] registerLicenseFromFileURL:url];
	}
	
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

- (IBAction)cancelLicenseBtn:(id)sender {
	
	[enterLicenseWindow performClose: self];
	controllerState = @"Demo";
}

- (IBAction)requestLicensePressed:(id)sender
{
	[enterLicenseWindow performClose:self];
	[self runRequestLicenseWindow];
}

- (IBAction)submitBtnPressed:(id)sender {

	NSString*	requestUser = [licenseeField stringValue];
	NSString*	requestEmail = [licenseMailField stringValue];
	NSString*	requestCode = [licenseInvoiceCode stringValue];
	
	if( ([requestUser isEqual:@""]) || ([requestEmail isEqual:@""]) ) {
		AudioServicesPlayAlertSound( kUserPreferredAlert );
		return;
	} else
		[requestLicenseWindow orderOut:self];
	
	if( [requestCode isEqual:@""] )
		requestCode = @"<none>";
	
	NSString*	bodyText = [[NSString stringWithFormat:@"Please send a replacement license for\n\nLicensed Name: %@\nLicensed Email: %@\nLicensed Invoice: %@\n\nThanks!\n\n\n", requestUser, requestEmail, requestCode] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString*	urlString = [NSString stringWithFormat:@"mailto:license.request@pickadisk.com?subject=Request%%20License&body=%@", bodyText];
	
	NSURL*		buyPADURL = [NSURL URLWithString:urlString];
	
	LSOpenCFURLRef( (CFURLRef)buyPADURL, NULL );
	
}

- (IBAction)visitLicenseBtn:(id)sender {
	
	NSURL*		buyPADURL = [NSURL URLWithString:NSLocalizedString(@"http://pickadisk.com/purchase/", @"License Controller Literal URL String when user clicks Purchase")];
	
	LSOpenCFURLRef( (CFURLRef)buyPADURL, NULL );
	
	if( [controllerState isEqual:kPADLicenseStateFirstAnnounce] )
		controllerState = kPADLicenseStateRunningDemo;
	[self closeStateWindow];
}

- (IBAction)demoLicenseBtn:(id)sender {
	
	controllerState = kPADLicenseStateRunningDemo;
	[self closeNotLicensedWindow];
}

- (IBAction)enterLicenseBtn:(id)sender {
	[self closeNotLicensedWindow];
	controllerState = kPADLicenseStateEnterLicense;
	[enterLicenseWindow performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.42];
}

- (IBAction)requestLicenseBtn:(id)sender {

	
}

@end


