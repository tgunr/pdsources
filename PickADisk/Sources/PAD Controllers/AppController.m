//
//  AppDelegate.m
//  Async Downloader
//
//  Created by Jack Small on 7/7/08.
//  Copyright 2008 Jack Small. All rights reserved.
//


#import "AppController.h"
#import <DiscRecording/DiscRecording.h>
#import <AudioToolbox/AudioToolbox.h>
#import <fcntl.h>

//#import <CoreFoundation/CoreFoundation.h>
#import "pmsCFUtility.h"
#import "pmsDACALUtility.h"
#import "PADOperationOpenDevice.h"
#import <ILCrashReporter/ILCrashReporter.h>
#import "DACDriverInstaller.h"
#import "DACVolume.h"
#import "LicenseController.h"

#define PAD_BUSYBODY_DELAY	0.1
#define PAD_PREFS_VERSION	(const char*)"0.3"

@implementation AppController
static AppController *shared;

- (id)init
{
    if (shared) 
	{
        [self autorelease];
        return shared;
    }
    if (self = [super init])
	{	// Initializtion 
		
#if PADBOX_EXPIRE_CHECK != 0
		[PADBOXController	performSelectorOnMainThread:@selector(startBOXWithToken:)
											withObject:[NSNumber numberWithDouble:PADBOX_EXPIRE_DATE]
										waitUntilDone:YES];
#endif		

		PADBOX_VALID_BEGIN
		
		[self initCrashReport];
		[self initPreferences];
		DACALSetup();

		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:6];
		
		queueSearch = [[NSOperationQueue alloc] init];
		[queueSearch setMaxConcurrentOperationCount:2];
		
		queueUI = [[NSOperationQueue alloc] init];
		[queueUI setMaxConcurrentOperationCount:1];

		//busyBodies = [NSMutableDictionary dictionaryWithCapacity:1000];
		//busyBodies = [NSMutableArray arrayWithCapacity:0];
		busyBodies = [[NSMutableArray alloc] initWithCapacity:8192];
		busyBusy = NO;
		jPADBusyBodyBeat = 0;
		
		PADBOX_VALID_END
		
		shared = self;
	}
    return self; 
}

- (void)queueOperation:(NSOperation*)op { [queue addOperation:op]; }
- (void)queueUIOperation:(NSOperation*)op { [queueUI addOperation:op]; }
- (void)queueSearchOperation:(NSOperation*)op {	[queueSearch addOperation:op]; }

- (void)cancelOperationsForDevice:(DACALDevice*)oldBox
{
	[queue setSuspended:YES];
	
	NSArray*	theOps = [queue operations];
	int			index, count = [theOps count];
	
	for( index=0; index < count; index++ )
		[[theOps objectAtIndex:index] cancelOperationForDevice:oldBox];

	[queue setSuspended:NO];
}

- (void)dealloc
{
	[queue release], queue = nil;
	[queueUI release], queueUI = nil;
	[busyBodies release], busyBodies = nil;
	
	DACALClientRelease( kPADClientIdentifier );
	
    [super dealloc];
}

- (void)initCrashReport
{
	[[ILCrashReporter defaultReporter]
	 launchReporterForCompany:@"PickADisk"
	 reportAddr:@"crashreport@pickadisk.com"];	
}

- (void)initPreferences
{
	NSMutableDictionary*	defaultPrefs = [NSMutableDictionary dictionaryWithCapacity:0];
	NSNumber*				boolTRUE = [NSNumber numberWithInt:1];
	NSNumber*				boolFALSE = [NSNumber numberWithInt:0];
	NSString*				prefsVersion = [NSString stringWithCString:PAD_PREFS_VERSION];
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
	
	[defaultPrefs setObject:[NSNumber numberWithInt:5] forKey:@"PADScanDepthData"];
	[defaultPrefs setObject:[NSNumber numberWithInt:3] forKey:@"PADScanDepthAudio"];
	[defaultPrefs setObject:[NSNumber numberWithInt:2] forKey:@"PADScanDepthImage"];
	[defaultPrefs setObject:[NSNumber numberWithInt:1] forKey:@"PADScanDepthVideo"];
	
	[defaultPrefs setObject:boolTRUE forKey:@"PADColumnDateAdded"];
	[defaultPrefs setObject:boolTRUE forKey:@"PADColumnSlotNum"];
	[defaultPrefs setObject:boolTRUE forKey:@"PADColumnSlotType"];
	[defaultPrefs setObject:boolTRUE forKey:@"PADColumnCheckedOut"];
	
	[defaultPrefs setObject:boolFALSE forKey:@"PADSearchResultsGrouped"];

	[defaultPrefs setObject:@"4BDD0419-381B-4CCB-A50F-A645B456E199" forKey:@"PADPrefToolSelected"];
	
	[defaults registerDefaults:defaultPrefs];
	
	if( needsUpdate )
	{
		if( currentVersion == nil ) 
			gotUpdate = YES;
		
		if( [currentVersion compare:@"0.1"] == NSOrderedSame )
			gotUpdate = YES;
				
		if( gotUpdate == YES ) {
			[defaults setObject:prefsVersion forKey:@"PADPrefsVersion"];
			[defaults synchronize];
			if( currentVersion == nil ) currentVersion = [NSString stringWithCString:(const char*)"0.0"];
			NSLog(@"Updated preferences from version %@ to version %@", currentVersion, prefsVersion);
		}
	}
	
}

- (void)awakeFromNib {

	PADBOX_VALID_BEGIN

	// Validate pref license
	BOOL valid = [[LicenseController shared] dataValid];
	
	// Register for 'GURL' Apple Event to handle URL opening
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleOpenLocationAppleEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	
	// *** new nibs
	[NSBundle loadNibNamed:@"CarouselIndex" owner:[NSApplication sharedApplication]];
	//[NSBundle loadNibNamed:@"CarouselProgress" owner:[NSApplication sharedApplication]];

	// Add busy body heartbeat
	[NSTimer scheduledTimerWithTimeInterval:PAD_BUSYBODY_DELAY target:self selector:@selector(doBusyWork:) userInfo:nil repeats:YES];
	
	DACALClientInitialize();
		
	if (!valid)
		NSLog(@"License invalid");
		
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


- (NSArray*)feedParametersForHostBundle:(NSBundle*)hostBundle sendingSystemProfile:(BOOL)isSending
{
	NSMutableArray*		outArray = [NSMutableArray arrayWithCapacity:4];
	NSArray*			profileDictKeys = [NSArray arrayWithObjects:@"key", @"visibleKey", @"value", @"visibleValue", nil];
	DACALCount			boxCount = DACALDevicesGetCount();
	DACALCount			count101 = DACALDevicesGetCountForModel( DACALDC101CFName );
	DACALCount			count300 = DACALDevicesGetCountForModel( DACALDC300CFName );
	DACALCount			count016 = DACALDevicesGetCountForModel( DACALDC016RWCFName );
	
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
	if( toolbarController != nil ) return [toolbarController validateMenuItem:item];

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

+ (id)shared
{
    if (!shared) {
        [[AppController alloc] init];
    }
    return shared;
}

- (void)setDataView:(TreeController*)tc { dataView = tc; }
- (id)dataView { return (id)dataView; }

- (PADIndexToolbarController*)toolbarController { return toolbarController; }

- (void)setToolbarController:(PADIndexToolbarController*)tb { toolbarController = tb; }

- (IBAction)addSlot:(id)sender { [toolbarController clickAssign:self]; }
- (IBAction)mountDisc:(id)sender { [toolbarController clickPlay:self]; }
- (IBAction)deleteSlot:(id)sender { [toolbarController clickUnassign:self]; }
- (IBAction)idUnits:(id)sender { [toolbarController clickIdentify:self]; }
- (IBAction)resetCarousel:(id)sender { [toolbarController clickReset:self]; }
- (IBAction)checkInOut:(id)sender { [toolbarController clickCheckOut:self]; }
- (IBAction)retractDoor:(id)sender { [toolbarController clickCloseDoor:self]; }
- (IBAction)gotoSlot:(id)sender { NSLog(@"Unimplemented feature."); }

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
	if( busyBusy == YES ) return;
	
	[self addBusyBody:[busyTimer userInfo] ofView:nil];
	[busyTimer invalidate];
}

- (void)removeBusyBody:(id)item
{
	NSOutlineView* theTable = nil;
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
	NSOutlineView* theTable = nil;
	int				theRow;
	
	if( busyBusy == YES ) return;
	if( [busyBodies count] == 0 ) return;
	
	busyBusy = YES;	

	SimpleTreeNode	*entry = nil;
    NSEnumerator *enumerator = [busyBodies objectEnumerator];
    while ((entry=(SimpleTreeNode*)[enumerator nextObject])) {
		if( [[entry nodeData] itemType] == kPADTypeIndexDevice )
		{
			theTable = [[[DACALTreeDataSource shared] treeControl] outlineView];
			[theTable reloadItem:[[entry nodeParent] nodeParent] reloadChildren:YES];
			theRow = [theTable rowForItem:entry];
			if( ![[theTable itemAtRow:theRow] isEqual:entry] ) theTable = nil;
		}
		else
			theTable = [dataView outlineView];
		if(theTable != nil)
			[theTable reloadItem:(id)entry reloadChildren:[[entry nodeData] isExpanded]];
			//if( [[[entry nodeParent] nodeData] isExpanded] ) 
			//NSLog( @"Got Busy: %@ <%@>\n\tBodies: %@", [entry description], entry, [busyBodies description] );
		theTable = nil;
	}
	
	jPADBusyBodyBeat++;
	if( jPADBusyBodyBeat > 11 ) jPADBusyBodyBeat = 0;
		
	busyBusy = NO;
}

@end


