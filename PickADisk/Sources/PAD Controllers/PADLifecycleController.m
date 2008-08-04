//
//  PADLifecycleController.m
//  PickADisk
//
//  Created by Jack Small on 8/2/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "PADLifecycleController.h"

#if PADBOX_EXPIRE_CHECK != 0

#import <Sparkle/SUUpdater.h>
#import <Sparkle/SUAppcast.h>
#import <Sparkle/SUUserInitiatedUpdateDriver.h>

BOOL		gPADBOX_EXPIRED = NO;

@implementation PADBOXController
static	CFAbsoluteTime PADBOXController_Token = 0;

-(id)init
{
	if( self = [super init] ) {
		boxToken = PADBOX_EXPIRE_DATE;
		foundUpdate = NO;
	}
	return self;
}

-(void)checkBOX:(NSTimer*)timer
{
	CFDateRef		now = CFDateCreate( kCFAllocatorDefault, CFAbsoluteTimeGetCurrent() );
	CFOptionFlags					responseButton;
	SUUserInitiatedUpdateDriver*	updateDriver;
	CFDateRef		then = CFDateCreate( kCFAllocatorDefault, boxToken );
	CFStringRef		checkButton = CFSTR("Check For Update...");
	
	if( boxToken != PADBOXController_Token ) goto BUMMER;	
	if( !now || (CFDateCompare(now, then, NULL) != kCFCompareLessThan) ) goto BUMMER;

	return;
	
BUMMER:
	if( gPADBOX_EXPIRED ) checkButton = CFSTR("");
	
	CFUserNotificationDisplayAlert( 0.0, kCFUserNotificationStopAlertLevel, NULL, NULL, NULL, 
								   PADBOX_PRIMARY_MESSAGE, PADBOX_SECONDARY_MESSAGE, 
								   CFSTR("Quit"), checkButton, NULL, &responseButton );
	
	if( responseButton == kCFUserNotificationDefaultResponse ) exit(0);
	
	gPADBOX_EXPIRED = YES;
	
	updateDriver = [[SUUserInitiatedUpdateDriver alloc] init];
	[[SUUpdater sharedUpdater] setDelegate:self];
	[[SUUpdater sharedUpdater] checkForUpdatesWithDriver:updateDriver];
	
 }

+(id)startBOXWithToken:(NSNumber*)token
{
	CFAbsoluteTime		tokenNum = [token doubleValue];
	PADBOXController*	newLife = [[PADBOXController alloc] init];
	
	PADBOXController_Token = tokenNum;
	[newLife checkBOX:nil];
	
	[NSTimer scheduledTimerWithTimeInterval:PADBOX_DELAY
									 target:newLife
								   selector:@selector(checkBOX:)
								   userInfo:nil
									repeats:YES];		
	self = newLife;	
	return self;
}


- (void)didFindValidUpdate:(SUAppcastItem *)update toHostBundle:(NSBundle *)bundle
{
	foundUpdate = YES;
}

// Sent when the user makes a choice in the update alert dialog (install now / remind me later / skip this version).
- (void)userChoseAction:(SUUpdateAlertChoice)action forUpdate:(SUAppcastItem *)update toHostBundle:(NSBundle *)bundle
{
	if( action != SUInstallUpdateChoice ) {
		foundUpdate = NO;
		[self checkBOX:nil];
	}
}

@end


#endif

