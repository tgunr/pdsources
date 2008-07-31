#import "PADPrefsController.h"
#import <Sparkle/SUUpdater.h>

@implementation PADPrefsController

- (void)awakeFromNib {
	
	if( tabToolbar ) [tabToolbar setSelectedItemIdentifier:[[[tabToolbar items] objectAtIndex:0] itemIdentifier]];
		
	
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



- (IBAction)clickTool:(NSToolbarItem*)sender
{
	if( tabView ) [tabView selectTabViewItemWithIdentifier: [sender label]];
	if( tabToolbar ) [tabToolbar setSelectedItemIdentifier: [sender itemIdentifier]];
	
	[self refreshUpdateDate:sender];
}


- (IBAction)refreshUpdateDate:(id)sender
{
	NSDate*		theDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"SULastCheckTime"];
	NSString*	theUpdateString = (NSString*)CFSTR("Never checked for an update.");
	
	CFLocaleRef			thisLocale = CFLocaleCopyCurrent();
	CFDateFormatterRef	thisFormat = CFDateFormatterCreate( kCFAllocatorDefault, thisLocale, kCFDateFormatterFullStyle, kCFDateFormatterFullStyle );
	
	if( theDate )
		theUpdateString = (NSString*)CFDateFormatterCreateStringWithDate( kCFAllocatorDefault, thisFormat, (CFDateRef)theDate );
	
	if( updateText ) [updateText setStringValue:theUpdateString];
	
	CFRelease( theUpdateString );
	CFRelease( thisFormat );
	CFRelease( thisLocale );	
}

-(void) refreshUpdateTimer:(NSTimer*)timer
	{ [self refreshUpdateDate:[timer userInfo]]; }


- (IBAction)checkForUpdatesAndRefreshDate:(id)sender
{
	[[SUUpdater sharedUpdater] checkForUpdates:sender];
	
	[NSTimer scheduledTimerWithTimeInterval:3.0
									 target:self
								   selector:@selector(refreshUpdateTimer:)
								   userInfo:sender
									repeats:NO];
}

- (IBAction)provideFeedback:(id)sender
{
	CFURLRef	feedbackURL = CFURLCreateWithString( kCFAllocatorDefault, CFSTR("mailto:feedback@pickadisk.com?subject=PickADisk%20Feedback"), NULL );
	CFURLRef	launchURL;
	
	LSOpenCFURLRef( feedbackURL, &launchURL );
	//CFRelease( feedbackURL );
}


@end
