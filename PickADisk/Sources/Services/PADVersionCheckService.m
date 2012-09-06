//
// Created by davec on 9/6/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Cocoa/Cocoa.h>
#import "PADVersionCheckService.h"

NSString*		kPADVersionCheckFirstRunPrefKey		=	@"versionCheck";

@implementation PADVersionCheckService
+ (id)sharedVersionCheckService {
    return [PADVersionCheckService sharedService];
}

-(void)openService {
	// Wake up the License Controller which may show modal UI
	[NSBundle loadNibNamed:@"VersionCheckController" owner:[NSApplication sharedApplication]];
}


- (BOOL)versionValid {
    NSProcessInfo *info = [NSProcessInfo processInfo];
    NSUInteger os = [info operatingSystem];
    BOOL ok = [self isOnLionOrBetter];
    return ok;
}

- (BOOL)isOnSnowLeopardOrBetter
{
    return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_5);
}

- (BOOL)isOnLionOrBetter
{
    return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_7);
}

@end