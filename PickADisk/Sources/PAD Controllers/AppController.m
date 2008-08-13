//
//  AppDelegate.m
//  Async Downloader
//
//  Created by Matt Long on 2/16/08.
//  Copyright 2008 Cocoa Is My Girlfriend. All rights reserved.
//


#import "AppController.h"
#import <DiscRecording/DiscRecording.h>
#import <AudioToolbox/AudioToolbox.h>
#import <fcntl.h>

//#import <CoreFoundation/CoreFoundation.h>
#import "pmsCFUtility.h"
#import "pmsDACALUtility.h"

#define PAD_BUSYBODY_DELAY 0.1

void DACALSetup( void )
{
	DACALRegisterIconResource( CFSTR("DC300Black"), kDACALCarouselsFolderType );
	DACALRegisterIconResource( CFSTR("CDAudio"), 'cdda' );
	DACALRegisterIconResource( CFSTR("DVD-Video"), 'dvd ' );
	DACALRegisterIconResource( CFSTR("CD-silver"), 'Dcd ' );
	//DACALRegisterIconResource( CFSTR("ClockSearch"), 'ClkS' );
	//DACALRegisterIconResource( CFSTR("SmartFolder"), 'SmFl' );

	DACALDevicesInitialize();
}


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
		
		DACALSetup();

		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:6];
		
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

- (void)dealloc
{
	[queue release], queue = nil;
	[busyBodies release], busyBodies = nil;
	
	DACALDevicesFinalize();
	
    [super dealloc];
}

- (void)awakeFromNib {

	PADBOX_VALID_BEGIN

	NSNotificationCenter *noteCenter;
	
	// Assume -observerMethod:(id)aNotification exists
	noteCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[noteCenter addObserver:self selector:@selector(newMediaDetected:)
					  name:@"NSWorkspaceDidMountNotification" object:nil]; // Register for all mount notifications
	[noteCenter addObserver:self selector:@selector(existingMediaRemoved:)
					  name:@"NSWorkspaceWillUnmountNotification" object:nil]; // Register for all unmount notifications

	// Register for 'GURL' Apple Event to handle URL opening
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleOpenLocationAppleEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	
	// *** new nibs
	[NSBundle loadNibNamed:@"CarouselIndex" owner:[NSApplication sharedApplication]];
	//[NSBundle loadNibNamed:@"CarouselProgress" owner:[NSApplication sharedApplication]];

	// Add busy body heartbeat
	[NSTimer scheduledTimerWithTimeInterval:PAD_BUSYBODY_DELAY target:self selector:@selector(doBusyWork:) userInfo:nil repeats:YES];
	
	PADBOX_VALID_END
	
	if( !PADBOX_VALIDATED ) NSLog(@"PickADisk has expired.");
}

- (void) newMediaDetected:(id)aNotification {
	
	NSArray*		newMounts = [[NSWorkspace sharedWorkspace] mountNewRemovableMedia];
	NSInteger		mountCount = [newMounts count];
	NSInteger		index = 0;
	NSMutableArray*	urlMounts = [NSMutableArray arrayWithCapacity:mountCount];
//	NSURL*			discURL = nil; //
	
	for( index=0; index < mountCount; index++ )
		[urlMounts addObject:[NSURL fileURLWithPath:[newMounts objectAtIndex:index]]];

	NSLog(@"Detected Mounts: %@", urlMounts);	

	//if( addVolumeController ) [addVolumeController detectedMounts:urlMounts];
	//id controllerThing = [[NSApplication sharedApplication] addVolumeController];
	[addVolumeController detectedMounts:urlMounts];
//	[urlMounts release];
	
	NSLogFunc;
}

- (void) existingMediaRemoved:(id)aNotification {
	NSArray*	oldMounts = (NSArray*)[NSArray arrayWithObject:[NSURL fileURLWithPath:[[aNotification userInfo] valueForKey:@"NSDevicePath"]]];
	
	NSLog(@"Detected Unmounts: %@", oldMounts);	

	[addVolumeController ejectedMounts:oldMounts];
	
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
	CFURLRef	feedbackURL = CFURLCreateWithString( kCFAllocatorDefault, CFSTR("http://pickadisk.com/feedback/"), NULL );
	CFURLRef	launchURL;
	
	LSOpenCFURLRef( feedbackURL, &launchURL );
}


+ (void)playUISound:(NSInteger)theSound {
		
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"PADPlaySounds"] == YES ) AudioServicesPlaySystemSound( (SystemSoundID)theSound );

}

+ (id)shared
{
    if (!shared) {
        [[AppController alloc] init];
    }
    return shared;
}

- (void)setDataView:(TreeController*)tc { dataView = tc; }

- (PADIndexToolbarController*)toolbarController { return toolbarController; }

- (void)setToolbarController:(PADIndexToolbarController*)tb { toolbarController = tb; }

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

	busyBusy = YES;
	//[busyBodies removeObjectForKey:item]; 
	//NSLog( @"Bodies: %@", [busyBodies description] );
	//if( [busyBodies count] > 0 ) [busyBodies removeObject:item];
	[busyBodies removeObject:item];
	//NSLog( @"Removed %@ <%@>\n\tBodies: %@", [item description], item, [busyBodies description] );

	theTable = [dataView outlineView];
	if(theTable != nil)
		[theTable reloadItem:(id)item reloadChildren:NO];
	
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
	
	if( busyBusy == YES ) return;
	if( [busyBodies count] == 0 ) return;
	
	busyBusy = YES;	
    NSObject *entry = nil;
    NSEnumerator *enumerator = [busyBodies objectEnumerator];
    while ((entry=[enumerator nextObject])) {
		theTable = [dataView outlineView];
		if(theTable != nil)
			//[entry setBusyCount:[entry busyCount]+1];
			[theTable reloadItem:(id)entry reloadChildren:YES];
			//NSLog( @"Got Busy: %@ <%@>\n\tBodies: %@", [entry description], entry, [busyBodies description] );
		theTable = nil;
	}
	
	jPADBusyBodyBeat++;
	if( jPADBusyBodyBeat > 11 ) jPADBusyBodyBeat = 0;
		
	busyBusy = NO;
}
@end


