#import "PADPrefsController.h"
#import <Sparkle/SUUpdater.h>
#import "DACDriverInstaller.h"
#import "LicenseController.h"

@implementation PADPrefsController

- (void) updateLicensePanel {
	BOOL valid = [[LicenseController shared] licenseValid];
	if (valid) {
		[licenseeField setStringValue: [[[LicenseController shared] licenseDict] objectForKey: @"Name"]];
		[licenseMailField setStringValue: [[[LicenseController shared] licenseDict] objectForKey: @"Email"]];
	} else {
		[licenseeField setStringValue: @""];
		[licenseMailField setStringValue: @""];
	}
}

- (void)awakeFromNib {
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.SULastCheckTime" options:0 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.DACALDriverInstalled" options:0 context:NULL];
	
    [licensePathControl setTarget:self];
    [licensePathControl setDoubleAction:@selector(pathControlDoubleClick:)];
	[licensePathControl setDelegate:self];
	
	[self updateLicensePanel];
	
}

- (void)dealloc
{
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.SULastCheckTime"];
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == [NSUserDefaultsController sharedUserDefaultsController] && ([keyPath hasSuffix:@"SULastCheckTime"]))
	{
		[self refreshUpdateDate:self];
	}
	else if (object == [NSUserDefaultsController sharedUserDefaultsController] && ([keyPath hasSuffix:@"DACALDriverInstalled"]))
	{
		[self updateDriverPane];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	
	NSArray* theItems = [toolbar items];
	NSInteger theCount = [theItems count];
	NSInteger index;
	NSMutableArray* theArray = [NSMutableArray arrayWithCapacity:theCount];
	
	for(index=0; index<theCount; index++)
		[theArray addObject:[[theItems objectAtIndex:index] itemIdentifier]];
	
	//	NSLog(@"Selectables: %@", theArray);
	
	return theArray;
}

- (NSToolbarItem*)toolbarItemForIdentifier:(NSString*)id
{
	NSToolbarItem*		outToolbarItem = nil;
	NSArray*			toolbarItems = [tabToolbar visibleItems];
	int					index, count = [toolbarItems count];
	
	for( index=0; index < count; index++ )
	{
		outToolbarItem = [toolbarItems objectAtIndex:index];
		if( [[outToolbarItem itemIdentifier] compare:id] == NSOrderedSame )
			break;
		if( [[outToolbarItem label] compare:id] == NSOrderedSame )
			break;
		outToolbarItem = nil;
	}
	
	return outToolbarItem;
}

- (IBAction)runPreferences:(id)sender
{
	NSString*	startToolID = [[NSUserDefaults standardUserDefaults] objectForKey:@"PADPrefToolSelected"];
	
	if( tabToolbar ) 
		[self clickTool:[self toolbarItemForIdentifier:startToolID]];
	[self refreshUpdateDate:self];
	[self updateDriverPane];
	if( prefsWindow ) 
		[prefsWindow makeKeyAndOrderFront:sender];
}

- (IBAction)clickTool:(NSToolbarItem*)sender
{
	if( tabView ) 
		[tabView selectTabViewItemWithIdentifier: [sender label]];
	if( tabToolbar ) 
		[tabToolbar setSelectedItemIdentifier: [sender itemIdentifier]];
	
	[[NSUserDefaults standardUserDefaults] setObject:[sender itemIdentifier] forKey:@"PADPrefToolSelected"];
	
	NSLog(@"Clicked Tool Label:%@ ID:%@", [sender label], [sender itemIdentifier]);
	
	[self refreshUpdateDate:sender];
	
	NSView*		theTabView = [[tabView selectedTabViewItem] view]; 
	NSRect		theBottomFrame = [[theTabView viewWithTag:13] frame];
	NSRect		theTabFrame = [theTabView frame];
	NSRect		theWindowFrame = [[tabView window] frame];
	NSRect		theContentFrame = [[tabView window] contentRectForFrameRect:theWindowFrame];
	NSPoint		theNewSize; // = theTabFrame.size;
	
	float		theToolbarHeight = -(theWindowFrame.size.height - theContentFrame.size.height);
	float		theNewHeight = (theWindowFrame.size.height - (theTabFrame.size.height - theBottomFrame.origin.y)) + theToolbarHeight;
	float		theDeltaHeight = theWindowFrame.size.height - theNewHeight;
	float		theDeltaOrigin = theWindowFrame.origin.y + theNewHeight;
	
	theNewSize.x = theBottomFrame.size.width;
	theNewSize.y = theTabFrame.size.height - theBottomFrame.origin.y;
	
	theWindowFrame.size.width = theBottomFrame.size.width;
	theWindowFrame.size.height = theDeltaHeight; // theTabFrame.size.height - theBottomFrame.origin.y;
	theWindowFrame.origin.y = theDeltaOrigin;
	
	//[[tabView window] setContentSize:theWindowFrame.size];
	[[tabView window] setFrame:theWindowFrame display:YES animate:YES];
}


- (IBAction)refreshUpdateDate:(id)sender
{
	NSDate*		theDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"SULastCheckTime"];
	NSString*	theLastCheckFormat = NSLocalizedString(@"Last Check: %@", @"Prefs Window Update Tab Last Check Prompt Format for last update check date");
	NSString*	theUpdateString = NSLocalizedString(@"Never checked for an update.", @"Prefs Window Update Tab Last Check Prompt default when no update check date is found");
	
	CFLocaleRef			thisLocale = CFLocaleCopyCurrent();
	CFDateFormatterRef	thisFormat = CFDateFormatterCreate( kCFAllocatorDefault, thisLocale, kCFDateFormatterFullStyle, kCFDateFormatterFullStyle );
	CFStringRef			thisDate = NULL;
	
	if( theDate ) {
		thisDate = CFDateFormatterCreateStringWithDate( kCFAllocatorDefault, thisFormat, (CFDateRef)theDate );
		theUpdateString = [NSString stringWithFormat:theLastCheckFormat, (NSString*)thisDate];
		CFRelease( thisDate );
	}
	
	if( updateText ) [updateText setStringValue:theUpdateString];
	
	CFRelease( thisFormat );
	CFRelease( thisLocale );	
}

/*
 //-(void) refreshUpdateTimer:(NSTimer*)timer
 //	{ [self refreshUpdateDate:[timer userInfo]]; }
 
 
 - (IBAction)checkForUpdatesAndRefreshDate:(id)sender
 {
 [[SUUpdater sharedUpdater] checkForUpdates:sender];
 
 //	[NSTimer scheduledTimerWithTimeInterval:3.0
 //									 target:self
 //								   selector:@selector(refreshUpdateTimer:)
 //								   userInfo:sender
 //									repeats:NO];
 }
 */
- (IBAction)provideFeedback:(id)sender
{
	return [[AppController shared] provideFeedback:sender];
}

- (void)updateDriverPane
{
	BOOL	haveDriver = [DACDriverInstaller isDriverKextInstalled];
	NSDate*	gotDate = [DACDriverInstaller dateDriverKextInstalled];
	NSString*	gotVers = [DACDriverInstaller versionOfDriverKextLoaded];
	NSString*	outPrompt = NSLocalizedString(@"The DACAL Driver is not installed on this machine.", @"Prefs Window Driver Pane Default Prompt when drive is not found");
	
	[installDriver setHidden:haveDriver];
	[removeDriver setHidden:!haveDriver];
	[driverNotImage setHidden:haveDriver];
	
	if( haveDriver )
		outPrompt = [NSString stringWithFormat:NSLocalizedString(@"DACAL Driver v%@\nInstalled %@",@"Prefs Window Drive Pane Format Prompt for driver version on installed date"), gotVers, [gotDate description]];
	
	[driverPrompt setStringValue:outPrompt];
}

- (IBAction)runDriverInstaller:(id)sender
{
	NSString*	startToolID = @"2739036B-2D8A-4A84-9980-6B6D5E658783";	// Driver
	
	if( tabToolbar ) [self clickTool:[self toolbarItemForIdentifier:startToolID]];
	[self refreshUpdateDate:self];
	if( prefsWindow ) [prefsWindow makeKeyAndOrderFront:sender];
	
}


@end
