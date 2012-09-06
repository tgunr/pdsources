//
// Created by davec on 9/6/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <Foundation/Foundation.h>
#import "JSServiceManager.h"
#import <AppKit/AppKit.h>


//Make sure the version number defines exist; when compiling in 10.5, NSAppKitVersionNumber10_5 isn't defined
#ifndef NSAppKitVersionNumber10_5
#define NSAppKitVersionNumber10_5 949
#endif


//Make sure the version number defines exist; when compiling in 10.7, NSAppKitVersionNumber10_7 isn't defined
#ifndef NSAppKitVersionNumber10_7
#define NSAppKitVersionNumber10_7 1138
#endif

extern NSString*		kPADVersionCheckFirstRunPrefKey;

@interface PADVersionCheckService : JSServiceAbstract

+ (id)sharedVersionCheckService;

- (void)openService;
- (BOOL)versionValid;

- (BOOL)isOnSnowLeopardOrBetter;
- (BOOL)isOnLionOrBetter;

@end