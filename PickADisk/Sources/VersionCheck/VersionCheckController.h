//
//  VersionCheckController.h
//  PickADisk
//
//  Created by Dave Carlton on 9/6/12.
//  Copyright (c) 2012 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//Make sure the version number defines exist; when compiling in 10.5, NSAppKitVersionNumber10_5 isn't defined
#ifndef NSAppKitVersionNumber10_5
#define NSAppKitVersionNumber10_5 949
#endif


//Make sure the version number defines exist; when compiling in 10.7, NSAppKitVersionNumber10_7 isn't defined
#ifndef NSAppKitVersionNumber10_7
#define NSAppKitVersionNumber10_7 1138
#endif

extern NSString*		kPADVersionCheckFirstRunPrefKey;

@interface VersionCheckController : NSWindowController {
    IBOutlet NSWindow *versionCheckWindow;
    BOOL haveFirstRun;
}

- (BOOL)versionValid;
- (BOOL)isOnSnowLeopardOrBetter;
- (BOOL)isOnLionOrBetter;
- (IBAction)quit:(id)sender;
- (IBAction)webSite:(id)sender;
- (IBAction)tryAnyway:(id)sender;

@end
