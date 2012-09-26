//
//  AppDelegate.m
//  Async Downloader
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import "AppController.h"
#import <AudioToolbox/AudioToolbox.h>

//#import <CoreFoundation/CoreFoundation.h>
#import "PADOperationOpenDevice.h"

//#import <ILCrashReporter/ILCrashReporter.h>
//#import "JSTestService.h"

//#import "DACDriverInstaller.h"
//#import "DACVolume.h"
#import "LicenseController.h"
#import "LicenseService.h"
#import "PADLifecycleController.h"
#import "DACALTreeDataSource.h"
#import "PADIndexToolbarController.h"
#import "PADOutlineView.h"

#define PAD_BUSYBODY_DELAY	0.1
#define PAD_PREFS_VERSION	(const char*)"0.6"

@implementation AppController
static AppController *sharedAppController;

- (id)init
{
    if (sharedAppController)
	{
        [self autorelease];
        return sharedAppController;
    }
	self = [super init];
	if (self)
	{	
		//	Initializtion 
		sharedAppController = self;

		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:6];
		
		queueSearch = [[NSOperationQueue alloc] init];
		[queueSearch setMaxConcurrentOperationCount:2];
		
		queueUI = [[NSOperationQueue alloc] init];
		[queueUI setMaxConcurrentOperationCount:1];
		
		busyBodies = [[NSMutableArray alloc] initWithCapacity:8192];
		busyBusy = NO;
		jPADBusyBodyBeat = 0;
		
		[self initPreferences];

        [NSBundle loadNibNamed:@"VersionCheckController" owner:[NSApplication sharedApplication]];

		[[JSServiceManager sharedServices] initializeServices];
		
//#if PADBOX_EXPIRE_CHECK != 0
//		[PADBOXController	performSelectorOnMainThread:@selector(startBOXWithToken:)
//										   withObject:[NSNumber numberWithDouble:PADBOX_EXPIRE_DATE]
//										waitUntilDone:YES];
//#endif		
		
//		PADBOX_VALID_BEGIN
				
//		[self initCrashReport];
//		[self initPreferences];
//		DACALSetup();
				
//		PADBOX_VALID_END

	}
    return self; 
}

- (void)queueOperation:(NSOperation*)op { [queue addOperation:op]; }
- (void)queueUIOperation:(NSOperation*)op { [queueUI addOperation:op]; }
- (void)queueSearchOperation:(NSOperation*)op {	[queueSearch addOperation:op]; }

- (void)cancelOperationsForDevice:(DACALDevice*)oldBox onQueue:(NSOperationQueue*)workQueue
{
	[workQueue setSuspended:YES];
	
	NSArray*	theOps = [workQueue operations];
	int			index, count = [theOps count];
	
	for( index=0; index < count; index++ )
		[[theOps objectAtIndex:index] cancelOperationForDevice:oldBox];
	
	[workQueue setSuspended:NO];
}

- (void)cancelOperationsForDevice:(DACALDevice*)oldBox
{
	[self cancelOperationsForDevice:oldBox onQueue:queue];
	[self cancelOperationsForDevice:oldBox onQueue:queueUI];
	[self cancelOperationsForDevice:oldBox onQueue:queueSearch];
	
}

- (void)dealloc
{
	[queue release], queue = nil;
	[queueUI release], queueUI = nil;
	[queueSearch release], queueSearch = nil;
	[busyBodies release], busyBodies = nil;
	
	DACALClientRelease( kPADClientIdentifier );

	[addVolumeController release];
	[super dealloc];
}

/*
- (void)initCrashReport
{
	[[ILCrashReporter defaultReporter]
	 launchReporterForCompany:@"PickADisk"
	 reportAddr:@"crashreport@pickadisk.com"];	
}
*/

- (void)initPreferences
{
	NSMutableDictionary*	defaultPrefs = [NSMutableDictionary dictionaryWithCapacity:0];
	NSNumber*				boolTRUE = [NSNumber numberWithInt:1];
	NSNumber*				boolFALSE = [NSNumber numberWithInt:0];
	NSString*				prefsVersion = [NSString stringWithCString:PAD_PREFS_VERSION encoding:NSUTF8StringEncoding];
	NSString*				currentVersion = nil;
	BOOL					needsUpdate = NO;
	BOOL					gotUpdate = NO;
	NSUserDefaults*			defaults = [NSUserDefaults standardUserDefaults];
	
	currentVersion = [defaults stringForKey:@"PADPrefsVersion"];
	
	if( !currentVersion || ![prefsVersion isEqual:currentVersion] )
		needsUpdate = YES;
	
	[defaultPrefs setObject:prefsVersion forKey:@"PADPrefsVersion"];
	
	[defaultPrefs setObject:boolTRUE forKey:@"PADPlaySounds"];
	
	[defaultPrefs setObject:boolTRUE forKey:@"PADEjectOnIndex"];
	[defaultPrefs setObject:boolTRUE forKey:@"PADCheckInOnIndex"];
	
	[defaultPrefs setObject:[NSNumber numberWithInt:7] forKey:@"PADScanDepthData"];
	[defaultPrefs setObject:[NSNumber numberWithInt:5] forKey:@"PADScanDepthAudio"];
	[defaultPrefs setObject:[NSNumber numberWithInt:5] forKey:@"PADScanDepthImage"];
	[defaultPrefs setObject:[NSNumber numberWithInt:1] forKey:@"PADScanDepthVideo"];
	
	[defaultPrefs setObject:boolFALSE forKey:@"PADColumnDateAdded"];
	[defaultPrefs setObject:boolTRUE forKey:@"PADColumnSlotNum"];
	[defaultPrefs setObject:boolTRUE forKey:@"PADColumnSlotType"];
	[defaultPrefs setObject:boolTRUE forKey:@"PADColumnCheckedOut"];
	[defaultPrefs setObject:boolFALSE forKey:@"PADColumnDateCheckedOut"];
	[defaultPrefs setObject:boolFALSE forKey:@"PADColumnComments"];
	[defaultPrefs setObject:boolFALSE forKey:@"PADColumnTags"];
	[defaultPrefs setObject:boolFALSE forKey:@"PADColumnRating"];
	
	[defaultPrefs setObject:boolFALSE forKey:@"PADSearchResultsGrouped"];
	
	[defaultPrefs setObject:@"4BDD0419-381B-4CCB-A50F-A645B456E199" forKey:@"PADPrefToolSelected"];
	
	[defaults registerDefaults:defaultPrefs];
	
	if( needsUpdate )
	{
		//if( currentVersion == nil ) 
		//	gotUpdate = YES;
		
		//if( [currentVersion compare:@"0.1"] == NSOrderedSame )
		//	gotUpdate = YES;
		
		//	User upgrading to prefs version 0.5 should get a new toolbar in case they've saved one
		if( [prefsVersion compare:@"0.5"] == NSOrderedSame )
			[defaults removeObjectForKey:@"NSToolbar Configuration CBD4AF57-273A-43B1-B47C-55D929D9CF3D"];
		
		gotUpdate = YES;
		
		if( gotUpdate == YES ) {
			[defaults setObject:prefsVersion forKey:@"PADPrefsVersion"];
			[defaults synchronize];
			if( currentVersion == nil ) currentVersion = [NSString stringWithCString:(const char*)"0.0" encoding:NSUTF8StringEncoding];
			NSLog(@"Updated preferences from version %@ to version %@", currentVersion, prefsVersion);
		}
	}
	
}

- (void)awakeFromNib {
	
	[[JSServiceManager sharedServices] openServices];

	PADBOX_VALID_BEGIN
		
	// First wake up the License Controller which may show modal UI
	// Since we're not requiring the license we can start it here instead of in the init
//	[PADLicenseService sharedLicenseService];
	
	// Register for 'GURL' Apple Event to handle URL opening
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleOpenLocationAppleEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	
	// *** new nibs
	[NSBundle loadNibNamed:@"CarouselIndex" owner:[NSApplication sharedApplication]];

	// Add busy body heartbeat
	[NSTimer scheduledTimerWithTimeInterval:PAD_BUSYBODY_DELAY target:self selector:@selector(doBusyWork:) userInfo:nil repeats:YES];
	
//	DACALClientInitialize();
	
//	[[LicenseController shared] showNotLicensed];
	
	//	if (!valid)
	//		NSLog(@"License invalid");
			
	PADBOX_VALID_END
	if( !PADBOX_VALIDATED ) 
		NSLog(@"PickADisk has expired.");
}

- (void)handleOpenLocationAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)reply {
	
    NSAppleEventDescriptor *directObjectDescriptor = [event paramDescriptorForKeyword:keyDirectObject];
	NSString *urlString;
	NSURL *objectURL;
	
    if ( directObjectDescriptor ) {
		urlString = [directObjectDescriptor stringValue];
        if ( urlString ) {			
			objectURL = [[NSURL alloc] initWithString: urlString];
            if ( objectURL ) {
				NSLog(@"Open URL: %@", objectURL);
				[objectURL release];
			}
        }
    }
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	if( [filename hasSuffix:@"padlicense"] == YES )
		return [[PADLicenseService sharedLicenseService] registerLicenseFromFile:filename];
	
	return YES;
}

- (NSArray*)feedParametersForHostBundle:(NSBundle*)hostBundle sendingSystemProfile:(BOOL)isSending
{
	NSMutableArray*		outArray = [NSMutableArray arrayWithCapacity:4];
	NSArray*			profileDictKeys = [NSArray arrayWithObjects:@"key", @"visibleKey", @"value", @"visibleValue", nil];
	DACALCount			boxCount = DACALDevicesGetCount();
	DACALCount			count101 = DACALDevicesGetCountForModel( DACALDC101CFName );
	DACALCount			count300 = DACALDevicesGetCountForModel( DACALDC300CFName );
	DACALCount			count016 = DACALDevicesGetCountForModel( DACALDC016CFName );
	
	if( isSending == YES )
	{
		[outArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"countTotal", @"Carousel Count", [NSNumber numberWithInt:boxCount], [NSNumber numberWithInt:boxCount], nil] forKeys:profileDictKeys]];
		
		if( count101 )
			[outArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"countDC101", @"DC-101 Count", [NSNumber numberWithInt:count101], [NSNumber numberWithInt:count101], nil] forKeys:profileDictKeys]];
		if( count300 )
			[outArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"countDC300", @"DC-300 Count", [NSNumber numberWithInt:count300], [NSNumber numberWithInt:count300], nil] forKeys:profileDictKeys]];
		if( count016 )
			[outArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"countDC016RW", @"DC016RW Count", [NSNumber numberWithInt:count016], [NSNumber numberWithInt:count016], nil] forKeys:profileDictKeys]];
	}
	
	{
		PADLicenseService*	lService = [PADLicenseService sharedLicenseService];
		NSString*			lHash = [lService licenseHash];
		NSString*			lCrack = [lService licenseCracked] ? @"Yes" : @"No";
		
		if( !lHash | ([lHash length] == 0) )
			lHash = @"None";
		
		[outArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"pLoc", @"PadKey", lHash, @"< Private >", nil] forKeys:profileDictKeys]];
		[outArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"pTrue", @"PadSafe", lCrack, @"< Private >", nil] forKeys:profileDictKeys]];
	}
	
	return( (NSArray*)outArray );
}

- (IBAction)provideFeedback:(id)sender
{
	CFURLRef	feedbackURL = CFURLCreateWithString( kCFAllocatorDefault, CFCopyLocalizedString(CFSTR("http://pickadisk.com/feedback/"), CFSTR("PAD URL used when user selects Provide User Feedback")), NULL );
	CFURLRef	launchURL;
	
	LSOpenCFURLRef( feedbackURL, &launchURL );
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    if (toolbarController != nil)
        return [toolbarController validateMenuItem:item];

    return NO;
}

+ (void)playUISound:(NSInteger)theSound
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"PADPlaySounds"] == YES ) AudioServicesPlaySystemSound( (SystemSoundID)theSound );
}

+ (void)playUISoundForResult:(DACALResult)theResult
{
	SystemSoundID	theSound = kASSystemSoundDoink;
	
	if( theResult == kDACALOK ) theSound = kASSystemSoundSuccess;
	
	[self playUISound:theSound];
	
}

+ (void)playUISoundForBOOL:(BOOL)wasSuccess
{
	SystemSoundID	theSound = kASSystemSoundDoink;
	
	if( wasSuccess == YES ) theSound = kASSystemSoundSuccess;
	
	[self playUISound:theSound];
	
}

+ (id)shared {
	if (!sharedAppController) {
		[[[AppController alloc] init] retain];
	}
	return sharedAppController;
}

- (void)setDataView: (TreeController *) tc {
	dataView = tc;
}

- (TreeController *)dataView {
	return dataView;
}

- (PADIndexToolbarController *)toolbarController {
	return toolbarController;
}

- (void)setToolbarController: (PADIndexToolbarController *) tb {
	toolbarController = tb;
}

- (IBAction)addSlot:(id)sender { [toolbarController clickAssign:self]; }
- (IBAction)mountDisc:(id)sender { [toolbarController clickPlay:self]; }
- (IBAction)deleteSlot:(id)sender { [toolbarController clickUnassign:self]; }
- (IBAction)idUnits:(id)sender { [toolbarController clickIdentify:self]; }
- (IBAction)resetCarousel:(id)sender { [toolbarController clickReset:self]; }
- (IBAction)checkInOut:(id)sender { [toolbarController clickCheckOut:self]; }
- (IBAction)checkIn:(id)sender { [toolbarController clickCheckIn:self]; }
- (IBAction)checkOut:(id)sender { [toolbarController clickCheckOut:self]; }
- (IBAction)retractDoor:(id)sender { [toolbarController clickCloseDoor:self]; }
- (IBAction)gotoSlot:(id)sender { [toolbarController clickGotoSlot:self]; }
- (IBAction)ejectVolumes:(id)sender { [toolbarController clickEject:self]; }

- (IBAction)printReport:(id)sender
{
	NSArray*	theBoxes = [toolbarController selectedDevices];
	
	if( [theBoxes count] > 0 )
		[[PADLayoutView printReportForDevice:(DACALDeviceRef)[theBoxes objectAtIndex:0] forSender:sender] autorelease];
}

- (PADAddVolumeController*)addVolumeController { return addVolumeController; }
- (void)setAddVolumeController:(PADAddVolumeController*)inAVC
{
	addVolumeController = [inAVC retain];
	//    if (!addVolumeController || ![addVolumeController isEqual:inAVC]) {
	//		[addVolumeController release];
	//		addVolumeController = [inAVC retain];
	//    }
}

- (void)addBusyBody:(id)item ofView:(id)view 
{
	[self addBusyBody:item];
}

- (void)addBusyBody:(id)item
{
	busyBusy = YES;
	//[busyBodies setObject:view forKey:item]; 
	if( ![busyBodies containsObject:item] )
		[busyBodies addObject:item];
	//NSLog( @"Added %@ <%@>\n\tBodies: %@", [item description], item, [busyBodies description] );
	busyBusy = NO;
}

- (void)scheduleAddBusyBody:(id)item
{
	[NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(scheduledAddBusyBody:) userInfo:item repeats:YES];	
}

- (void)scheduledAddBusyBody:(NSTimer*)busyTimer
{ 
	if( busyBusy == YES )
        return;
	
	[self addBusyBody:[busyTimer userInfo] ofView:nil];
	[busyTimer invalidate];
}

- (void)removeBusyBody:(id)item
{
	PADOutlineView* theTable = nil;
	int				theRow;
	
	busyBusy = YES;
	//[busyBodies removeObjectForKey:item]; 
	//NSLog( @"Bodies: %@", [busyBodies description] );
	//if( [busyBodies count] > 0 ) [busyBodies removeObject:item];
	[busyBodies removeObject:item];
	//NSLog( @"Removed %@ <%@>\n\tBodies: %@", [item description], item, [busyBodies description] );
/*
	if( [[item nodeData] itemType] == kPADTypeIndexDevice )
		theTable = [[[DACALTreeDataSource shared] treeControl] outlineView];
	else
		theTable = [dataView outlineView];
	if(theTable != nil)
		[theTable reloadItem:(id)[item nodeParent] reloadChildren:YES];
*/
	if( [[item nodeData] itemType] == kPADTypeIndexDevice )
	{
		theTable = [[[DACALTreeDataSource shared] treeControl] outlineView];
		[theTable reloadItem:[[item nodeParent] nodeParent] reloadChildren:YES];
		theRow = [theTable rowForItem:item];
		if( ![[theTable itemAtRow:theRow] isEqual:item] ) theTable = nil;
	}
	else
		theTable = [dataView outlineView];
	if(theTable != nil) [theTable reloadItem:(id)item reloadChildren:[[item nodeData] isExpanded]];

		//if( [[[item nodeParent] nodeData] isExpanded] ) 
				//NSLog( @"Got Busy: %@ <%@>\n\tBodies: %@", [entry description], entry, [busyBodies description] );
	theTable = nil;
	
	
	busyBusy = NO;
}

- (void)scheduleRemoveBusyBody:(id)item
{
	[NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(scheduledRemoveBusyBody:) userInfo:item repeats:YES];	
}

- (void)scheduledRemoveBusyBody:(NSTimer*)busyTimer
{ 
	if( busyBusy == YES ) return;
	
	[self removeBusyBody:[busyTimer userInfo]];
	[busyTimer invalidate];
}

- (NSMutableArray*)busyBodies
{
	return( busyBodies ); 
}

- (void)doBusyWork:(NSTimer*)busyTimer
{ 
	PADOutlineView* theTable = nil;
	int				theRow;
	
	if( busyBusy == YES )
        return;
	if( [busyBodies count] == 0 )
        return;
	
	busyBusy = YES;	
	
	SimpleTreeNode	*entry = nil;
    NSEnumerator *enumerator = [busyBodies objectEnumerator];
    while ((entry=(SimpleTreeNode*)[enumerator nextObject])) {
		if( [[entry nodeData] itemType] == kPADTypeIndexDevice )
		{
			theTable = [[[DACALTreeDataSource shared] treeControl] outlineView];
			[theTable reloadItem:[[entry nodeParent] nodeParent] reloadChildren:YES];
			theRow = [theTable rowForItem:entry];
			if( ![[theTable itemAtRow:theRow] isEqual:entry] )
                theTable = nil;
		}
		else
			theTable = [dataView outlineView];
		if(theTable != nil)
			[theTable reloadItem:(id)entry reloadChildren:[[entry nodeData] isExpanded]];
		if( [[[entry nodeParent] nodeData] isExpanded] ) 
            PMLOG_DEBUG(@"Got Busy: %@ <%@>\n\tBodies: %@", [entry description], entry, [busyBodies description] );
		theTable = nil;
	}
	
	jPADBusyBodyBeat++;
	if( jPADBusyBodyBeat > 11 )
        jPADBusyBodyBeat = 0;
	
	busyBusy = NO;
}

- (IBAction)runLicense:(id)sender
	{ [[LicenseController sharedLicenseController] chooseAppLicensedMenu:self]; }

- (IBAction)requestLicense:(id)sender 
	{ [[LicenseController sharedLicenseController] chooseRequestLicenseMenu:self]; }

- (IBAction)showHelp:(id)sender {
	CFBundleRef mainBundle = CFBundleGetMainBundle();
	CFURLRef helpURL = CFBundleCopyResourceURL(mainBundle, CFSTR("index"), CFSTR("html"), CFSTR("PickADiskDoc"));
	//helpURL = CFBundleCopyResourcesDirectoryURL(mainBundle);
	//CFStringRef urlString = CFURLGetString (helpURL);
	LSOpenCFURLRef(helpURL, NULL);
	return;
}

@end



