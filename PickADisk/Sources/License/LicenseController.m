//
//  LicenseController.m
//  PickADisk
//
//  Created by Dave Carlton on 09/30/08.
//  Copyright 2008 Polymicro Systems. All rights reserved.
//

#import "LicenseController.h"
#import "AquaticPrime.h"

@implementation PADPrefsController(LicenseExtension)

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
- (IBAction)selectLicenseFile:(id)sender
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
	NSArray *fileTypes = [NSArray arrayWithObject:@"plist"];
	NSInteger result = [panel runModalForTypes:fileTypes];
	if (result) {
		licenseFiles = [panel filenames];
		url = [NSURL fileURLWithPath: [licenseFiles objectAtIndex: 0]];
		[licensePathControl setURL: url];
		LicenseController *validator =  [LicenseController shared];
		NSDictionary *licenseDict = [validator checkLicense: [url path]];
		if (licenseDict) {
			NSString *licenseName = [licenseDict objectForKey:@"Name"];
			[licenseeField setStringValue: licenseName];
			NSString *licenseEmail = [licenseDict objectForKey:@"Email"];
			[licenseMailField setStringValue: licenseEmail];
			[[NSUserDefaults standardUserDefaults] setObject: licenseDict forKey:@"licenseDict"];
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


@end

@implementation LicenseController

static LicenseController*	shared = nil;

+ (id)shared {
    if (!shared)
        [[LicenseController alloc] init];
    return shared;
}


-(id)init {
	if (shared)
		return (id)shared;
	
	if( self = [super init] ) {
		NSLog(@"LicenseController Created");
		shared = (LicenseController*)self;
	}
	
	// This string is specially constructed to prevent key replacement 	// *** Begin Public Key ***
	NSMutableString *key = [NSMutableString string];
	[key appendString:@"0x9F7B984C1758F45A31E162D27B76"];
	[key appendString:@"A2460DE570C1F2C6C51080707FC5C5"];
	[key appendString:@"2D480EDCF54F57B54BA5"];
	[key appendString:@"7"];
	[key appendString:@"7"];
	[key appendString:@"A28908DD"];
	[key appendString:@"ABE26C974C2436053483"];
	[key appendString:@"6"];
	[key appendString:@"6"];
	[key appendString:@"C649C455"];
	[key appendString:@"D10B4EB382C36763A60F8C"];
	[key appendString:@"E"];
	[key appendString:@"E"];
	[key appendString:@"C24AE5"];
	[key appendString:@"4035C4CEA0108B31"];
	[key appendString:@"D"];
	[key appendString:@"D"];
	[key appendString:@"1D9915450B96"];
	[key appendString:@"7B510B07379"];
	[key appendString:@"3"];
	[key appendString:@"3"];
	[key appendString:@"CA428780D997E6DB3"];
	[key appendString:@"94238E65A53919B127A76B9FEB6184"];
	[key appendString:@"11A5B211A3FA6B873F"];
	// *** End Public Key *** 
	
	// Instantiate AquaticPrime
	licenseValidator = [AquaticPrime aquaticPrimeWithKey:key];

	// Blacklist bad licenses
	[licenseValidator setBlacklist:[NSArray arrayWithObject:@"94f93b1db282f562d7ff846f1dc31e2f9ed39862"]];
	licenseDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"licenseDict"];
	NSData * licenseData;
	if (licenseDict)
		licenseData = [licenseDict objectForKey: @"Signature"];
	return self;
}

- (AquaticPrime *)licenseValidator { return licenseValidator; }
- (NSDictionary *)licenseDict { return licenseDict; }

- (BOOL) dataValid {
	if (licenseDict)
		return [licenseValidator verifyLicenseData: [licenseDict objectForKey: @"Signature"]];
	else
		return false;
}

- (NSDictionary*)checkLicense:(NSString*)licensePath {
    // Get the dictionary from the license file
    // If the license is invalid, we get nil back instead of a dictionary
    licenseDict = [licenseValidator dictionaryForLicenseFile:licensePath];
	NSString *aKey;
	aKey = [licenseValidator key];
	aKey = [licenseValidator privateKey];
	aKey = [licenseValidator getLastError];
	return licenseDict;
}

- (BOOL) fileValid:(NSString*)licensePath {
	NSDictionary *theDict = [self checkLicense: licensePath];
	if (!theDict)
		return true;
	return false;
}

@end


