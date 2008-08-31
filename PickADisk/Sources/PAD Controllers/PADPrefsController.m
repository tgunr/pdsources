#import "PADPrefsController.h"
#import <Sparkle/SUUpdater.h>

@implementation PADPrefsController

- (void)awakeFromNib {

	if( tabToolbar ) [tabToolbar setSelectedItemIdentifier:[[[tabToolbar items] objectAtIndex:0] itemIdentifier]];
		
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.SULastCheckTime" options:0 context:NULL];

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



- (IBAction)clickTool:(NSToolbarItem*)sender
{
	if( tabView ) [tabView selectTabViewItemWithIdentifier: [sender label]];
	if( tabToolbar ) [tabToolbar setSelectedItemIdentifier: [sender itemIdentifier]];
	
	[self refreshUpdateDate:sender];
}


- (IBAction)refreshUpdateDate:(id)sender
{
	NSDate*		theDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"SULastCheckTime"];
	NSString*	theLastCheckFormat = @"Last Check: %@";
	NSString*	theUpdateString = (NSString*)CFSTR("Never checked for an update.");
	
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


@end
