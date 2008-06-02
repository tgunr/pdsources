//
//  PMTBFSController.m
//  PMTB
//
//  Created by Dave Carlton on 6/2/08.
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import "PMTBFSController.h"

@implementation PMTBFSController

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
//	NSOpenPanel* panel = [NSOpenPanel openPanel];
//	[panel setCanChooseFiles:NO];
//	[panel setCanChooseDirectories:YES];
//	[panel setAllowsMultipleSelection:NO];
//	int ret = [panel runModalForDirectory:@"/tmp" file:nil types:nil];
//	if ( ret == NSCancelButton ) {
//		exit(0);
//	}
//	NSArray* paths = [panel filenames];
//	if ( [paths count] != 1 ) {
//		exit(0);
//	}
	NSString *carouselsPath; 
	NSArray *paths;
    NSFileManager *mgr = [NSFileManager defaultManager];
	
    paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0) {
        carouselsPath = [paths objectAtIndex:0];     
	}
	
	carouselsPath = [carouselsPath stringByAppendingString:@"/Carousels"];
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(mountFailed:)
				   name:kGMUserFileSystemMountFailed object:nil];
	[center addObserver:self selector:@selector(didMount:)
				   name:kGMUserFileSystemDidMount object:nil];
	[center addObserver:self selector:@selector(didUnmount:)
				   name:kGMUserFileSystemDidUnmount object:nil];
	
	NSString* mountPath = @"/Volumes/Carousels";
	loop_ = [[PMTBFS alloc] initWithRootPath:carouselsPath];
	
	fs_ = [[GMUserFileSystem alloc] initWithDelegate:loop_ isThreadSafe:NO];
	
	NSMutableArray* options = [NSMutableArray array];
	NSString* volArg = [NSString stringWithFormat:@"volicon=%@", 
	 [[NSBundle mainBundle] pathForResource:@"DC300Black" ofType:@"icns"]];

	NSString* volname = [NSString stringWithFormat:@"volname=%@", @"PMTB"];
	
	
	[options addObject:volArg];
	[options addObject:@"debug"];
	[options addObject:volname];
	[fs_ mountAtPath:mountPath 
		 withOptions:options];
}


@end
