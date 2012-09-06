//
//  VersionCheckController.m
//  PickADisk
//
//  Created by Dave Carlton on 9/6/12.
//  Copyright (c) 2012 PolyMicro Systems. All rights reserved.
//

#import "VersionCheckController.h"
#import "PADVersionCheckService.h"

@interface VersionCheckController ()
- (void)runModalWindow;

@end

@implementation VersionCheckController

static VersionCheckController*	shared_VersionCheckController = nil;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) { 
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)dealloc
{
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.licenseDict"];

    [super dealloc];
}

+ (id)sharedVersionCheckController
{
    if (!shared_VersionCheckController)
        [[VersionCheckController alloc] init];
    return shared_VersionCheckController;
}


-(id)init {
    if (shared_VersionCheckController)
        return (id)shared_VersionCheckController;

    if( (self = [super init]) ) {
        //NSLog(@"VersionCheckController Created");
        shared_VersionCheckController = self;

    }

    return self;
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

- (void)awakeFromNib {
    if (![[PADVersionCheckService sharedVersionCheckService] versionValid]) {
        haveFirstRun = [[NSUserDefaults standardUserDefaults] boolForKey:kPADVersionCheckFirstRunPrefKey];
        if (!haveFirstRun) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPADVersionCheckFirstRunPrefKey];
            [self runModalWindow];
        }

    }
}

- (void)runModalWindow
{
    NSInteger	result;
    result = [[NSApplication sharedApplication] runModalForWindow:versionCheckWindow];
    [versionCheckWindow performClose:self];
}

- (IBAction)quit:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPADVersionCheckFirstRunPrefKey];
    [[NSApplication sharedApplication] terminate:self];
}

- (IBAction)webSite:(id)sender {
    NSURL *gotoPADURL;
    gotoPADURL = [NSURL URLWithString:@"http://pickadisk.com/"];

    LSOpenCFURLRef( (CFURLRef) gotoPADURL, NULL );
    [versionCheckWindow performClose:sender];
    [NSApp abortModal];
}

- (IBAction)tryAnyway:(id)sender {
    [versionCheckWindow performClose:sender];
    [NSApp abortModal];
}
@end


