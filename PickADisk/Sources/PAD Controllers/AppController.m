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
	DACALRegisterIconResource( CFSTR("DVD"), 'dvd ' );
	DACALRegisterIconResource( CFSTR("CD"), 'Dcd ' );
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
		DACALSetup();

		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:6];
		
		//busyBodies = [NSMutableDictionary dictionaryWithCapacity:1000];
		//busyBodies = [NSMutableArray arrayWithCapacity:0];
		busyBodies = [[NSMutableArray alloc] initWithCapacity:8192];
		busyBusy = NO;
		jPADBusyBodyBeat = 0;
		
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

	NSNotificationCenter *noteCenter;
	
	// Assume -observerMethod:(id)aNotification exists
	noteCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[noteCenter addObserver:self selector:@selector(newMediaDetected:)
					  name:@"NSWorkspaceDidMountNotification" object:nil]; // Register for all mount notifications

	// Register for 'GURL' Apple Event to handle URL opening
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleOpenLocationAppleEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	
	// *** new nibs
	[NSBundle loadNibNamed:@"CarouselIndex" owner:[NSApplication sharedApplication]];
	[NSBundle loadNibNamed:@"CarouselProgress" owner:[NSApplication sharedApplication]];

	// Add busy body heartbeat
	[NSTimer scheduledTimerWithTimeInterval:PAD_BUSYBODY_DELAY target:self selector:@selector(doBusyWork:) userInfo:nil repeats:YES];
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
	[[[NSApplication sharedApplication] addVolumeController] detectedMounts:urlMounts];
//	[urlMounts release];
	
	NSLogFunc;
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


